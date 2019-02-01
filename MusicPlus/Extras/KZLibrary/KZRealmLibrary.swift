//
//  KZRealmLibrary.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/21.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import MediaPlayer
import PromiseKit
import AwaitKit
import Alamofire

enum KZRealmLibraryType: String {
    case localEmpty
    case local
    case plex
}

class KZRealmLibrary: Object, RealmGenerating {
    func realmGenerator() -> (() -> Realm?) {
        return {
            return try? Realm()
        }
    }

    @objc dynamic var name: String = ""
    @objc dynamic var uniqueIdentifier: String = ""
    @objc dynamic var created: Date = Date()

    @objc dynamic var libraryTypeRaw: String = "localEmpty"
    @objc dynamic var plexLibraryConfig: PlexRealmLibraryConfig?

    @objc dynamic var isRefreshing = false

    var libraryType: KZRealmLibraryType {
        set {
            libraryTypeRaw = newValue.rawValue
        }
        get {
            return KZRealmLibraryType(rawValue: libraryTypeRaw)!
        }
    }

    static var libraries: Results<KZRealmLibrary> {
        return Realm.main.objects(KZRealmLibrary.self).sorted(byKeyPath: "name", ascending: true)
    }

    convenience init(name: String, type: KZRealmLibraryType, plexLibraryConfig: PlexRealmLibraryConfig? = nil) {
        self.init()
        self.name = name
        self.libraryType = type
        self.uniqueIdentifier = UUID().uuidString
        self.created = Date()
        self.plexLibraryConfig = plexLibraryConfig
    }

    func realm() -> Realm {
        var config = Realm.Configuration()
        switch libraryType {
        case .local, .localEmpty:
            config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("KZLocalLibrary-\(uniqueIdentifier).realm")
        case .plex:
            config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("KZPlexLibrary-\(uniqueIdentifier).realm")
        }

        config.schemaVersion = Realm.currentSchemaVersion
        config.migrationBlock = { migration, oldSchemaVersion in
            migration.enumerateObjects(ofType: KZPlayerItem.className()) { old, new in
                if oldSchemaVersion < 7 {
                    new?["libraryUniqueIdentifier"] = old?["plexLibraryUniqueIdentifier"]
                }
            }
        }
        return try! Realm(configuration: config)
    }

    func refresh() {
        switch libraryType {
        case .local:
            let safeSelf = self.safeRefrence
            MPMediaLibrary.requestAuthorization { _ in
                safeSelf.resolve()?.addAllItems { _, _ in
                }
            }
        case .plex:
            plexRefresh()
        default:
            break
        }
    }

    // MARK: - Local Library

    func addAllItems(progressCallback: @escaping (_ status: String, _ complete: Bool) -> Void) {
        let safeSelf = self.safeRefrence
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            progressCallback("Loading Items...", false)
            let items = safeSelf.resolve()?.getAllItems() ?? []
            progressCallback("Saving \(items.count) Items...", false)
            safeSelf.resolve()?.saveItems(items, progressCallback: progressCallback)
        }
    }

    fileprivate func getAllItems() -> [MPMediaItem] {
        let predicate1 = MPMediaPropertyPredicate(value: MPMediaType.anyAudio.rawValue, forProperty: MPMediaItemPropertyMediaType)
        var predicate2 = MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem)
        if #available(iOS 9.2, *) {
            predicate2 = MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyHasProtectedAsset)
        }

        let query = MPMediaQuery(filterPredicates: [predicate1, predicate2])
        return query.items ?? []
    }

    fileprivate func saveItems(_ items: [MPMediaItem], progressCallback: @escaping (_ status: String, _ complete: Bool) -> Void) {
        let realm = self.realm()
        var changed = false
        var i = 0
        realm.beginWrite()

        for item in items {
            i += 0
            progressCallback("Saving \(i) of \(items.count) Items...", false)
            let result = realm.object(ofType: KZPlayerItem.self, forPrimaryKey: "KZPlayerItem-\(item.persistentID)")
            if result == nil && (item.assetURL?.absoluteString.isNotEmpty ?? false) {
                let newItem = KZPlayerItem(item: item, realm: realm, libraryUniqueIdentifier: uniqueIdentifier)
                addItemToSpotlight(newItem)
                realm.add(newItem)
                changed = true
            }
        }

        progressCallback("Saving \(items.count) Items...", false)
        try? realm.commitWrite()

        if changed {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .libraryDataDidChange, object: nil)
            }
        }

        progressCallback("Saved.", true)
    }

    func addMediaItem(at fileURL: URL, update: Bool = true) {
        guard fileURL.isFileURL else {
            return
        }

        let randomIdentifier = String.random(length: 27)
        let newFilePath = randomIdentifier + "." + fileURL.pathExtension
        var newFileURL = URL(fileURLWithPath: "")
        var mediaFileURL = URL(fileURLWithPath: "")
        var absoluteNewFileURL = URL(fileURLWithPath: "")
        var absoluteMediaFileURL = URL(fileURLWithPath: "")

        do {
            let fileManager = FileManager.default
            var documentURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

            documentURL.appendPathComponent("Added Music")
            newFileURL = URL(fileURLWithPath: "Added Music")

            if !fileManager.fileExists(atPath: documentURL.path) {
                try fileManager.createDirectory(at: documentURL, withIntermediateDirectories: false, attributes: [:])
            }

            newFileURL.appendPathComponent(newFilePath)
            absoluteNewFileURL = documentURL.appendingPathComponent(newFilePath)

            try fileManager.moveItem(atPath: fileURL.path, toPath: absoluteNewFileURL.path)
        } catch let err as NSError {
            os_log(.error, log: .general, "Something went wrong: %@", err)
            return
        }

        let asset = AVURLAsset(url: absoluteNewFileURL)
        let safeSelf = self.safeRefrence
        asset.loadValuesAsynchronously(forKeys: [#keyPath(AVAsset.tracks), #keyPath(AVAsset.commonMetadata), #keyPath(AVAsset.duration)]) {
            let artworks = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)

            var artwork: UIImage?
            for item in artworks {
                if let data = item.value as? Data {
                    artwork = UIImage(data: data)
                } else if item.keySpace == AVMetadataKeySpace.id3, let dictionary = item.value as? [String: Any] {
                    if let data = dictionary["data"] as? Data {
                        artwork = UIImage(data: data)
                    }
                }
            }

            var artworkFileUrl: String?
            if let artwork = artwork, let data = artwork.pngData() {
                do {
                    let fileManager = FileManager.default
                    var documentURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

                    documentURL.appendPathComponent("Added Music Artwork")
                    mediaFileURL = URL(fileURLWithPath: "Added Music Artwork")

                    if !fileManager.fileExists(atPath: documentURL.path) {
                        try fileManager.createDirectory(at: documentURL, withIntermediateDirectories: false, attributes: [:])
                    }

                    mediaFileURL.appendPathComponent(randomIdentifier + ".png")
                    absoluteMediaFileURL = documentURL.appendingPathComponent(randomIdentifier + ".png")

                    fileManager.createFile(atPath: absoluteMediaFileURL.path, contents: data, attributes: [:])
                    artworkFileUrl = mediaFileURL.path
                } catch {
                    os_log("Ooops! Something went wrong")
                }
            }

            let title = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? fileURL.lastPathComponent
            let artist = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtist, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? ""
            let albumName = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? ""
            let trackNumberString = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.iTunesMetadataKeyTrackNumber, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? ""
            let trackNumber = Int.init(trackNumberString) ?? 1

            let duration = Double(CMTimeGetSeconds(asset.duration))

            guard let safeSelf = safeSelf.resolve() else {
                return
            }

            let realm = safeSelf.realm()

            realm.beginWrite()

            let item = KZPlayerItem(realm: realm, artist: artist, album: albumName, title: title, duration: duration, assetURL: newFileURL.path, isDocumentURL: true, artworkURL: artworkFileUrl ?? "", uniqueIdentifier: randomIdentifier, libraryUniqueIdentifier: safeSelf.uniqueIdentifier, trackNum: trackNumber)
            item.artworkURL = mediaFileURL.path
            safeSelf.addItemToSpotlight(item)
            realm.add(item)

            try! realm.commitWrite()

            if update {
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: .libraryDataDidChange, object: nil)
                })
            }
        }
    }

    // MARK: - Plex Library

    func plexRefresh() {
        guard plexLibraryConfig != nil && !isRefreshing else {
            return
        }

        try! realm?.write {
            isRefreshing = true
        }
        os_log("Refreshing")
        let plex = KZPlex(authToken: plexLibraryConfig!.authToken)
        let selfRefrence = KZThreadSafeReference(to: self)
        async {
            guard let safeSelf = selfRefrence.resolve() else {
                return
            }

            let resources = try await(plex.resources())
            let arrayOfPromises = resources.devices.filter { $0.clientIdentifier == safeSelf.plexLibraryConfig!.clientIdentifier }.flatMap { $0.connections }.map { $0.sections() }
            let serversResponse = try await(when(fulfilled: arrayOfPromises))
            let servers = serversResponse.compactMap { $0 }
            var libraries: [Directory] = servers.flatMap { $0.directories }
            libraries = libraries.uniqueElements.filter { $0.type == .artist }
            guard let library = libraries.first(where: { $0.uuid == safeSelf.plexLibraryConfig!.dircetoryUUID }) else {
                throw KZPlex.Error(errorDescription: "Unable to find library.")
            }

            try! safeSelf.realm?.write {
                safeSelf.plexLibraryConfig?.connectionURI = library.connection.uri
            }

            let allTracksResponse = try await(library.all())
            let realm = safeSelf.realm()
            let items = allTracksResponse.tracks!
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
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .libraryDataDidChange, object: nil)
                        }
                    }
                }
                autoreleasepool {
                    let result = realm.object(ofType: KZPlayerItem.self, forPrimaryKey: "KZPlayerItem-\(item.ratingKey!)")
                    if result == nil {
                        // Add new item
                        let newItem = item.asPlayerItem(realm: realm, libraryUniqueIdentifier: safeSelf.uniqueIdentifier)
                        safeSelf.addItemToSpotlight(newItem)
                        realm.add(newItem)
                        changed = true
                    } else if let result = result, result.plexTrack?.updatedAt != item.updatedAt {
                        // Update old item
                    }
                }
            }
            try! realm.commitWrite()

            if changed {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .libraryDataDidChange, object: nil)
                }
            }

            guard let syncList = try await(plex.syncItems()) else {
                return
            }

            // TODO: Use enums instead
            let responsibleItems = syncList.items.filter {
                $0.server.machineIdentifier == library.device.clientIdentifier
                    && $0.location.contains(library.uuid.lowercased())
            }

            let syncItems = try await(when(fulfilled: responsibleItems.map { library.syncItems(syncItemId: $0.id) }))
            let fileManager = FileManager.default
            let documentURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

            var allSyncTracks: [Track] = syncItems.flatMap { $0.tracks }
            allSyncTracks = allSyncTracks.filter { $0.media.part.syncState == "processed" }

            i = 0
            let syncPromises = AnyIterator<Promise<Void>> {
                guard allSyncTracks.isNotEmpty else {
                    return nil
                }

                let track = allSyncTracks.removeFirst()

                return async {
                    guard let self = selfRefrence.resolve(), let plexLibraryConfig = self.plexLibraryConfig else {
                        return
                    }

                    let realm = self.realm()

                    i += 1
                    guard let item = realm.object(ofType: KZPlayerItem.self, forPrimaryKey: "KZPlayerItem-\(track.ratingKey!)") else {
                        return
                    }

                    var chosenMedia = track.media!
                    if item.plexTrack?.shouldSyncRaw ?? false, let originalTrack = items.first(where: { $0.ratingKey == track.ratingKey }) {
                        chosenMedia = originalTrack.media!
                    }

                    let key = "\(chosenMedia.part.duration!)-\(chosenMedia.part.size!)-\(chosenMedia.audioChannels!)-\(chosenMedia.audioCodec!)"
                    let downloadURL = "\(plexLibraryConfig.connectionURI)\(chosenMedia.part.key!)"
                    let downloadedURL = "\(plexLibraryConfig.connectionURI)/sync/\(KZPlex.clientIdentifier)/item/\(track.ratingKey!)/downloaded"

                    let ext = chosenMedia.part.key.components(separatedBy: ".").last ?? "mp3"

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
                        // TODO: We can't just delete it we need to see if it has any other reliances
                        try fileManager.removeItem(atPath: oldAsset)
                    }

                    if fileManager.fileExists(atPath: absoluteFilePath.path) {
                        try realm.write {
                            item.localAssetURL = filePath.path
                        }
                        return
                    }

                    do {
                        try await(plex.download(downloadURL, to: absoluteFilePath, token: plexLibraryConfig.authToken))
                        try selfRefrence.resolve()?.realm().write {
                            item.localAssetURL = filePath.path
                        }
                        if let safeSelf = selfRefrence.resolve() {
                            try await(plex.put(downloadedURL, token: safeSelf.plexLibraryConfig!.authToken))
                        }
                        os_log("%d → synced %@ to %@", i, item.title, filePath.path)
                    } catch {
                        os_log(.error, log: .general, "%@", error.localizedDescription)
                    }
                }
            }

            try await(when(fulfilled: syncPromises, concurrently: 1))
            os_log("Finished Syncing.")
            try! safeSelf.realm?.write {
                safeSelf.isRefreshing = true
            }
        }
    }

    // MARK: - Misc

    var allSongs: KZPlayerItemCollection {
        return KZPlayerItemCollection(realm().objects(KZPlayerItem.self).sorted(byKeyPath: "title", ascending: true))
    }

    func addItemToSpotlight(_ item: KZPlayerItem) {
        let attr = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attr.title = item.titleText()
        attr.contentDescription = item.subtitleText()
        attr.keywords = item.searchText.components(separatedBy: " ")
        /*if let image = item.artwork().image(at: CGSize(width: 50, height: 50)) {
         attr.thumbnailData = image.pngData()
         }*/
        attr.identifier = item.systemID
        attr.path = uniqueIdentifier

        let item = CSSearchableItem(uniqueIdentifier: nil, domainIdentifier: uniqueIdentifier, attributeSet: attr)

        CSSearchableIndex.default().indexSearchableItems([item])
    }

}
