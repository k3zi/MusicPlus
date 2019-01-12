// 
//  KZPlayerItem.swift
//  KZPlayer
// 
//  Created by Kesi Maduka on 10/24/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit
import MediaPlayer
import RealmSwift

class KZPlayerItem: Object, RealmGenerating {
    @objc dynamic var title = "", albumArtist = "", genre = "", composer = "", assetURL = "", artworkURL = "", systemID = "", plexLibraryUniqueIdentifier = ""
    @objc dynamic var trackNum = 1, playCount = 1, position = 0
    @objc dynamic var startTime = 0.0, endTime = -1.0, tempo = 4.0
    @objc dynamic var liked = false, isDocumentURL = false
    let tags = List<KZPlayerTag>()

    @objc dynamic var artist: KZPlayerArtist?
    @objc dynamic var album: KZPlayerAlbum?

    @objc dynamic var oItem: KZPlayerItem? = nil {
        willSet {
            guard let oItem = oItem else {
                return
            }

            guard oItem != self else {
                return
            }

            self.observedKeys().forEach({ oItem.removeObserver(self, forKeyPath: $0) })
        }

        didSet {
            guard let oItem = oItem else {
                return
            }

            guard oItem != self else {
                return
            }

            self.observedKeys().forEach({ oItem.addObserver(self, forKeyPath: $0, options: .new, context: nil) })
        }
    }

    convenience init(item: MPMediaItem) {
        self.init()

        let realm = try! Realm()
        let artist = [item.albumArtist, item.artist].filter({ $0?.isNotEmpty ?? false }).first ?? "Unknown Artist"
        if let artist = realm.object(ofType: KZPlayerArtist.self, forPrimaryKey: artist! as AnyObject) {
            self.artist = artist
        } else {
            let artistObject = KZPlayerArtist(name: artist!)
            realm.add(artistObject)

            self.artist = artistObject
        }

        let album = (item.albumTitle?.isNotEmpty ?? false) ? item.albumTitle : "Unknown Album"
        if let album = realm.object(ofType: KZPlayerAlbum.self, forPrimaryKey: "\(album!)-\(self.artist!.name)" as AnyObject) {
            self.album = album
        } else {
            let albumObject = KZPlayerAlbum(name: album!, artist: self.artist!)
            realm.add(albumObject)

            self.album = albumObject
        }

        self.title = item.title ?? ""
        self.genre = item.genre ?? ""
        self.composer = item.composer ?? ""
        self.assetURL = item.assetURL?.absoluteString ?? ""

        self.trackNum = item.albumTrackNumber
        self.playCount = item.playCount

        self.startTime = 0
        self.endTime = item.playbackDuration

        self.systemID = "KZPlayerItem-\(item.persistentID)"
        self.oItem = self
    }

    convenience init(realm: Realm, artist: String, album: String, title: String, duration: Double, assetURL: String, isDocumentURL: Bool, artworkURL: String, uniqueIdentifier: String, trackNum: Int = 1, plexLibraryUniqueIdentifier: String = "") {
        self.init()

        if let artist = realm.object(ofType: KZPlayerArtist.self, forPrimaryKey: artist as AnyObject) {
            self.artist = artist
        } else {
            let artistObject = KZPlayerArtist(name: artist)
            realm.add(artistObject)

            self.artist = artistObject
        }

        if let album = realm.object(ofType: KZPlayerAlbum.self, forPrimaryKey: "\(album)-\(self.artist!.name)" as AnyObject) {
            self.album = album
        } else {
            let albumObject = KZPlayerAlbum(name: album, artist: self.artist!)
            realm.add(albumObject)

            self.album = albumObject
        }

        self.title = title
        self.assetURL = assetURL
        self.artworkURL = artworkURL
        self.trackNum = trackNum
        self.startTime = 0
        self.endTime = duration
        self.systemID = "KZPlayerItem-\(uniqueIdentifier)"
        self.isDocumentURL = isDocumentURL
        self.plexLibraryUniqueIdentifier = plexLibraryUniqueIdentifier
        self.oItem = self
    }

    func originalItem() -> KZPlayerItem {
        if oItem == self || oItem == nil {
            return self
        } else {
            return oItem!.originalItem()
        }
    }

    func realmGenerator() -> (() -> Realm?) {
        // First aquire things that can not go across threads
        let identifier = plexLibraryUniqueIdentifier
        return {
            guard let library = KZPlexLibrary.plexLibraries.first(where: { $0.uniqueIdentifier == identifier }) else {
                return nil
            }

            return library.realm()
        }
    }

    func realm() -> Realm? {
        return realmGenerator()()
    }

    var plexLibraryConfig: PlexLibraryConfig? {
        guard plexLibraryUniqueIdentifier.isNotEmpty, let config = KZPlexLibrary.plexLibraries.first(where: { $0.uniqueIdentifier == plexLibraryUniqueIdentifier })?.plexLibraryConfig else {
            return nil
        }

        return config
    }

    func fileURL() -> URL {
        if let config = plexLibraryConfig {
            let headers = KZPlex.requestHeadersQuery
            return URL(string: "\(config.connectionURI)/music/:/transcode/universal/start?path=\(assetURL)&X-Plex-Token=\(config.authToken)&\(headers)")!
        }

        if assetURL.hasPrefix("http") {
            return URL(string: assetURL)!
        }

        if isDocumentURL {
            let fileManager = FileManager.default
            let documentURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

            return documentURL.appendingPathComponent(assetURL)
        }

        return URL(string: assetURL)!
    }

    func fetchArtwork(completionHandler: @escaping (_ artwork: MPMediaItemArtwork) -> Void) {
        func callCompletionHandler(artwork: MPMediaItemArtwork) {
            DispatchQueue.main.async {
                completionHandler(artwork)
            }
        }

        var artworkURL = self.artworkURL
        let systemID = self.systemID
        let config = plexLibraryConfig

        DispatchQueue.global(qos: .background).async {
            if artworkURL.isNotEmpty {
                if let config = config {
                    let headers = KZPlex.requestHeadersQuery
                    artworkURL = "\(config.connectionURI)/photo/:/transcode?url=\(artworkURL)&width=\(Int(UIScreen.main.bounds.height))&height=\(Int(UIScreen.main.bounds.height))&minSize=1&X-Plex-Token=\(config.authToken)&\(headers)"
                }

                if let url = URL(string: artworkURL), !url.isFileURL {
                    KZPlayer.imageDownloader.download(URLRequest(url: url)) { response in
                        guard let image = response.result.value else {
                            return callCompletionHandler(artwork: .default)
                        }

                        callCompletionHandler(artwork: MPMediaItemArtwork(boundsSize: .zero, requestHandler: { size in
                            return image.af_imageAspectScaled(toFill: size)
                        }))
                    }
                    return // Alamofire will handle the default
                }

                let fileManager = FileManager.default
                let documentURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

                let localArtworkURL = documentURL.appendingPathComponent(artworkURL)

                if let image = UIImage(contentsOfFile: localArtworkURL.path) {
                    return callCompletionHandler(artwork: MPMediaItemArtwork.init(boundsSize: .zero, requestHandler: { _ in return image }))
                }

                return callCompletionHandler(artwork: .default)
            }

            guard let systemID = systemID.components(separatedBy: "-").last else {
                return callCompletionHandler(artwork: .default)
            }

            let p = MPMediaPropertyPredicate(value: systemID, forProperty: MPMediaItemPropertyPersistentID)
            let q = MPMediaQuery(filterPredicates: [p])

            if let artwork = q.items?.first?.artwork {
                return callCompletionHandler(artwork: artwork)
            }

            callCompletionHandler(artwork: .default)
        }
    }

    func duration() -> Double {
        return endTime - startTime
    }

    func artistName() -> String {
        let result = artist?.name ?? albumArtist
        return result.count > 0 ? result : "Unknown Artist"
    }

    func albumName() -> String {
        return album?.name ?? ""
    }

    func titleText() -> String {
        guard title.count > 0 else {
            return "Unknown Title"
        }

        return title
    }

    func subtitleText() -> String {
        let artist = albumArtist.count > 0 ? albumArtist : artistName()

        let text = [albumName(), artist].filter({ $0.count > 0 }).joined(separator: " - ")
        if text.count > 0 {
            return text
        }

        return "Unknown Metadata"
    }

    func searchText() -> String {
        return [title, albumName(), albumArtist, artistName()].filter({ $0.count > 0 }).joined(separator: " ")
    }

    override class func primaryKey() -> String? {
        return "systemID"
    }

    func observedKeys() -> [String] {
        return ["title", "artist", "album", "albumArtist", "genre", "composer", "assetURL", "trackNum", "playCount", "startTime", "endTime", "tempo"]
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)

        guard let newValue = change?[NSKeyValueChangeKey.newKey], let keyPath = keyPath else {
            return
        }

        let realm = self.realm!

        try! realm.write {
            self.setValue(newValue, forKey: keyPath)
        }
    }
}

class KZPlayerQueueItem: KZPlayerItem {
    convenience init(orig: KZPlayerItem) {
        self.init()

        self.title = orig.title
        self.artist = orig.artist
        self.album = orig.album
        self.genre = orig.genre
        self.composer = orig.composer
        self.assetURL = orig.assetURL
        self.artworkURL = orig.artworkURL

        self.trackNum = orig.trackNum
        self.playCount = orig.playCount

        self.startTime = orig.startTime
        self.endTime = orig.endTime

        self.systemID = "KZPlayerQueueItem-\(Date.timeIntervalSinceReferenceDate)-\(orig.originalItem().systemID)"
        self.isDocumentURL = orig.isDocumentURL
        self.oItem = orig.originalItem()
    }
}

class KZPlayerShuffleQueueItem: KZPlayerItem {
    convenience init(orig: KZPlayerItem) {
        self.init()

        self.title = orig.title
        self.album = orig.album
        self.artist = orig.artist
        self.genre = orig.genre
        self.composer = orig.composer
        self.assetURL = orig.assetURL
        self.artworkURL = orig.artworkURL

        self.trackNum = orig.trackNum
        self.playCount = orig.playCount

        self.startTime = orig.startTime
        self.endTime = orig.endTime

        self.systemID = "KZPlayerShuffleQueueItem-\(Date.timeIntervalSinceReferenceDate)-\(orig.originalItem().systemID)"
        self.isDocumentURL = orig.isDocumentURL
        self.plexLibraryUniqueIdentifier = orig.plexLibraryUniqueIdentifier
        self.oItem = orig.originalItem()
    }
}

class KZPlayerUpNextItem: KZPlayerItem {
    convenience init(orig: KZPlayerItem) {
        self.init()

        self.title = orig.title
        self.artist = orig.artist
        self.album = orig.album
        self.genre = orig.genre
        self.composer = orig.composer
        self.assetURL = orig.assetURL
        self.artworkURL = orig.artworkURL

        self.trackNum = orig.trackNum
        self.playCount = orig.playCount

        self.startTime = orig.startTime
        self.endTime = orig.endTime

        self.systemID = "KZPlayerUpNextItem-\(Date.timeIntervalSinceReferenceDate)-\(orig.originalItem().systemID)"
        self.isDocumentURL = orig.isDocumentURL
        self.plexLibraryUniqueIdentifier = orig.plexLibraryUniqueIdentifier
        self.oItem = orig.originalItem()
    }

}

class KZPlayerHistoryItem: KZPlayerItem {
    convenience init(orig: KZPlayerItem) {
        self.init()

        self.title = orig.title
        self.artist = orig.artist
        self.album = orig.album
        self.genre = orig.genre
        self.composer = orig.composer
        self.assetURL = orig.assetURL
        self.artworkURL = orig.artworkURL

        self.trackNum = orig.trackNum
        self.playCount = orig.playCount

        self.startTime = orig.startTime
        self.endTime = orig.endTime

        self.systemID = "KZPlayerUpNextItem-\(Date.timeIntervalSinceReferenceDate)-\(orig.originalItem().systemID)"
        self.isDocumentURL = orig.isDocumentURL
        self.plexLibraryUniqueIdentifier = orig.plexLibraryUniqueIdentifier
        self.oItem = orig.originalItem()
    }

}

extension AnyRealmCollection where Element: KZPlayerItem {
    func shuffled() -> Results<Element> {
        for result in self {
            result.position = Int(arc4random_uniform(UInt32(self.count)))
        }

        return self.sorted(byKeyPath: "position", ascending: true)
    }

    func toArray() -> [Element] {
        var arr = [Element]()

        for result in self {
            arr.append(result)
        }

        return arr
    }
}
