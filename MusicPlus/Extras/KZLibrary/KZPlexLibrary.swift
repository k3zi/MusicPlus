//
//  KZPlexLibrary.swift
//  Music+
//
//  Created by kezi on 2019/01/05.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import MediaPlayer
import CoreSpotlight
import MobileCoreServices
import PromiseKit
import AwaitKit
import Alamofire

class KZPlexLibrary: KZLibrary {

    override func realm() -> Realm {
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("KZPlexLibrary-\(uniqueIdentifier).realm")
        return try! Realm(configuration: config)
    }

    override func refresh() {
        guard let plexLibraryConfig = plexLibraryConfig else {
            return
        }

        let plex = KZPlex(authToken: plexLibraryConfig.authToken)
        plex.resources().then { resources -> Promise<[LibrarySectionsGETResponse?]> in
            let arrayOfPromises = resources.devices.filter { $0.clientIdentifier == plexLibraryConfig.clientIdentifier }.flatMap { $0.connections }.map { $0.sections() }
            return when(fulfilled: arrayOfPromises)
        }.then { response -> Promise<Void> in
            let servers = response.compactMap { $0 }
            var libraries: [Directory] = servers.flatMap { $0.directories }
            libraries = libraries.uniqueElements.filter { $0.type == .artist }
            guard let library = libraries.first(where: { $0.uuid == plexLibraryConfig.dircetoryUUID }) else {
                throw KZPlex.Error(errorDescription: "Unable to find library.")
            }

            plexLibraryConfig.connectionURI = library.connection.uri
            self.save()

            return library.all().then(on: DispatchQueue.global(qos: .background)) { response -> Promise<DevicesSyncItemsGETResponse?> in
                let realm = self.realm()
                let items = response.tracks!
                var changed = false
                realm.beginWrite()

                var i = 0
                for item in items {
                    i += 1
                    if i == 100 {
                        try! realm.commitWrite()
                        realm.beginWrite()
                        i = 0

                        if changed {
                            DispatchQueue.main.async(execute: {
                                NotificationCenter.default.post(name: Constants.Notification.libraryDataDidChange, object: nil)
                            })
                        }
                    }
                    autoreleasepool {
                        let results = realm.objects(KZPlayerItem.self).filter("systemID = 'KZPlayerItem-\(item.ratingKey!)'")
                        if results.count == 0 {
                            // Add new item
                            let newItem = item.asPlayerItem(realm: realm, plexLibraryUniqueIdentifier: self.uniqueIdentifier)
                            self.addItemToSpotlight(newItem)
                            realm.add(newItem)
                            changed = true
                        } else if let oldItem = results.filter({ $0.plexTrack?.updatedAt != item.updatedAt }).first {
                            // Update old item
                        }
                    }
                }
                try! realm.commitWrite()

                if changed {
                    DispatchQueue.main.async(execute: {
                        NotificationCenter.default.post(name: Constants.Notification.libraryDataDidChange, object: nil)
                    })
                }

                return plex.syncItems()
            }.done(on: DispatchQueue.global(qos: .background)) { response in
                guard let response = response else {
                    return
                }

                // TODO: Use enums instead
                let responsibleItems = response.items.filter {
                    $0.server.machineIdentifier == library.device.clientIdentifier
                    && $0.location.contains(library.uuid.lowercased())
                    && $0.status.state == "complete"
                }

                let arrayOfPromises = responsibleItems.map {
                    library.syncItems(syncItemId: $0.id)
                }

                let syncItems = try await(when(fulfilled: arrayOfPromises))
                let fileManager = FileManager.default
                let documentURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

                var allSyncTracks: [Track] = syncItems.flatMap { $0.tracks }

                let syncPromises = AnyIterator<Promise<Void>> {
                    guard allSyncTracks.count > 0 else {
                        return nil
                    }

                    let track = allSyncTracks.removeFirst()

                    return async {
                        let realm = self.realm()
                        guard let item = realm.objects(KZPlayerItem.self).filter("systemID = 'KZPlayerItem-\(track.ratingKey!)'").first else {
                            return
                        }

                        let key = "\(track.media.part.duration!)-\(track.media.part.size!)-\(track.media.audioChannels!)-\(track.media.audioCodec!)"
                        print(key)

                        let ext = track.media.part.key.components(separatedBy: ".").last ?? "mp3"

                        let fileName = "\(key).\(ext)"
                        var absoluteFilePath = documentURL.appendingPathComponent("Plex Synced Music")
                        var filePath = URL(fileURLWithPath: "Plex Synced Music")

                        if !fileManager.fileExists(atPath: absoluteFilePath.path) {
                            try fileManager.createDirectory(at: absoluteFilePath, withIntermediateDirectories: false, attributes: [:])
                        }

                        filePath.appendPathComponent(fileName)
                        absoluteFilePath.appendPathComponent(fileName)

                        if item.localAssetURL == filePath.path {
                            return
                        } else if let oldAsset = item.localAssetURL {
                            try fileManager.removeItem(atPath: oldAsset)
                        }

                        if fileManager.fileExists(atPath: absoluteFilePath.path) {
                            try realm.write {
                                item.localAssetURL = filePath.path
                            }
                            return
                        }

                        let downloadURL = "\(plexLibraryConfig.connectionURI)\(track.media.part.key!)"
                        do {
                            let response = try await(plex.get(downloadURL, token: plexLibraryConfig.authToken))
                            try response.data.write(to: absoluteFilePath)
                            try realm.write {
                                item.localAssetURL = filePath.path
                            }
                        } catch {
                            print(error)
                        }
                    }
                }

                try await(when(fulfilled: syncPromises, concurrently: 2))
                print("Finished Syncing")
            }
        }
    }

    static var plexLibraries: [KZPlexLibrary] {
        do {
            let result = try UserDefaults.standard.get(objectType: [KZPlexLibrary].self, forKey: Constants.Settings.plexLibraries)
            if let result = result {
                return result
            }
        } catch {
            fatalError("Unable to read plex library data from user defaults.")
        }

        return []
    }

    override func save() {
        var libraries = KZPlexLibrary.plexLibraries.filter({ $0 != self })
        libraries.append(self)

        do {
            try UserDefaults.standard.set(object: libraries, forKey: Constants.Settings.plexLibraries)
        } catch {
            fatalError("Unable to svae plex library data to user defaults.")
        }

        UserDefaults.standard.synchronize()
    }

}
