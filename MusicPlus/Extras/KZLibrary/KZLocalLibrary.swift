//
//  KZLocalLibrary.swift
//  Music+
//
//  Created by kezi on 2019/01/05.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import MediaPlayer

class KZLocalLibrary: KZLibrary {

    override func realm() -> Realm {
        var config = Realm.Configuration()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("KZLocalLibrary-\(uniqueIdentifier).realm")
        return try! Realm(configuration: config)
    }

    static var localLibraries: [KZLocalLibrary] {
        do {
            let result = try UserDefaults.standard.get(objectType: [KZLocalLibrary].self, forKey: Constants.Settings.localLibraries)
            if let result = result {
                return result
            }
        } catch {
            fatalError("Unable to read local library data from user defaults.")
        }

        return []
    }

    override func save() {
        var libraries = KZLocalLibrary.localLibraries.filter({ $0 != self })
        libraries.append(self)

        libraries.forEach { $0.isRefreshing = false }

        do {
            try UserDefaults.standard.set(object: libraries, forKey: Constants.Settings.localLibraries)
        } catch {
            fatalError("Unable to svae local library data to user defaults.")
        }

        UserDefaults.standard.synchronize()
    }

    func addAllItems(progressCallback: @escaping (_ status: String, _ complete: Bool) -> Void) {
         DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            progressCallback("Loading Items...", false)
            let items = self.getAllItems()
            progressCallback("Saving \(items.count) Items...", false)
            self.saveItems(items, progressCallback: progressCallback)
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
            let results = realm.objects(KZPlayerItem.self).filter("systemID = 'KZPlayerItem-\(item.persistentID)'")
            if results.count == 0 && (item.assetURL?.absoluteString.count ?? 0) > 0 {
                let newItem = KZPlayerItem(item: item)
                addItemToSpotlight(newItem)
                realm.add(newItem)
                changed = true
            }
        }

        progressCallback("Saving \(items.count) Items...", false)
        try! realm.commitWrite()

        if changed {
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Constants.Notification.libraryDataDidChange, object: nil)
            })
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
            print("Ooops! Something went wrong")
            print(err)
            return
        }

        let asset = AVURLAsset(url: absoluteNewFileURL)
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
                    print("Ooops! Something went wrong")
                }
            }

            let title = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? fileURL.lastPathComponent
            let artist = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyArtist, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? ""
            let albumName = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? ""
            let trackNumberString = AVMetadataItem.metadataItems(from: asset.commonMetadata, withKey: AVMetadataKey.iTunesMetadataKeyTrackNumber, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? ""
            let trackNumber = Int.init(trackNumberString) ?? 1

            let duration = Double(CMTimeGetSeconds(asset.duration))

            let realm = self.realm()
            realm.beginWrite()

            let item = KZPlayerItem(realm: realm, artist: artist, album: albumName, title: title, duration: duration, assetURL: newFileURL.path, isDocumentURL: true, artworkURL: artworkFileUrl ?? "", uniqueIdentifier: randomIdentifier, trackNum: trackNumber)
            item.artworkURL = mediaFileURL.path
            self.addItemToSpotlight(item)
            realm.add(item)

            try! realm.commitWrite()

            if update {
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: Constants.Notification.libraryDataDidChange, object: nil)
                })
            }
        }
    }

}
