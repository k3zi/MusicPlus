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

class KZPlayerItem: Object, KZPlayerItemBase {
    @objc dynamic var title = "", albumArtist = "", genre = "", composer = "", assetURL = "", artworkURL = "", localArtworkURL = "", systemID = "", libraryUniqueIdentifier = ""
    @objc dynamic var localAssetURL: String?
    @objc dynamic var trackNum = 1, playCount = 1, position = 0
    @objc dynamic var startTime = 0.0, endTime = -1.0, tempo = 1.0, bpm = 0.0, firstBeatPosition = 0.0, lastBeatPosition = 0.0
    @objc dynamic var liked = false, isDocumentURL = false
    let tags = List<KZPlayerTag>()

    @objc dynamic var artist: KZPlayerArtist?
    @objc dynamic var album: KZPlayerAlbum?
    @objc dynamic var plexTrack: KZPlayerPlexTrack?

    @objc dynamic var oItem: KZPlayerItem? = nil {
        willSet {
            guard let oItem = oItem else {
                return
            }

            guard oItem != self else {
                return
            }

            self.observedKeys().forEach { oItem.removeObserver(self, forKeyPath: $0) }
        }

        didSet {
            guard let oItem = oItem else {
                return
            }

            guard oItem != self else {
                return
            }

            self.observedKeys().forEach { oItem.addObserver(self, forKeyPath: $0, options: .new, context: nil) }
        }
    }

    // Ignore this field
    var orig: KZPlayerItem? {
        return self
    }

    convenience init(item: MPMediaItem, realm: Realm, libraryUniqueIdentifier: String) {
        self.init()

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

    convenience init(realm: Realm, artist: String, album: String, title: String, duration: Double, assetURL: String, isDocumentURL: Bool, artworkURL: String, uniqueIdentifier: String, libraryUniqueIdentifier: String, trackNum: Int = 1, plexTrack: Track? = nil) {
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
        self.libraryUniqueIdentifier = libraryUniqueIdentifier
        if let plexTrack = plexTrack {
            self.plexTrack = KZPlayerPlexTrack(track: plexTrack)
        }
        self.oItem = self
    }

    func originalItem() -> KZPlayerItem {
        if oItem == self || oItem == nil {
            return self
        } else {
            return oItem!.originalItem()
        }
    }

    var plexLibraryConfig: PlexRealmLibraryConfig? {
        guard libraryUniqueIdentifier.isNotEmpty, let config = KZRealmLibrary.libraries.first(where: { $0.uniqueIdentifier == libraryUniqueIdentifier })?.plexLibraryConfig else {
            return nil
        }

        return config
    }

    var isStoredLocally: Bool {
        if isDocumentURL || localAssetURL != nil || libraryUniqueIdentifier.isEmpty || !["http://", "ftp://", "https://"].contains(where: { assetURL.contains($0) }) {
            return true
        }

        return false
    }

    func fileURL() -> URL {
        if let localAssetURL = localAssetURL {
            let fileManager = FileManager.default
            let documentURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

            return documentURL.appendingPathComponent(localAssetURL)
        }

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

    func fetchArtwork(completionHandler: @escaping (_ artwork: MPMediaItemArtwork) -> Void) -> MPMediaItemArtwork? {
        func callCompletionHandler(artwork: MPMediaItemArtwork) {
            DispatchQueue.main.async {
                completionHandler(artwork)
            }
        }

        var localArtworkURL = self.localArtworkURL
        var artworkURL = self.artworkURL
        let config = plexLibraryConfig
        let isStoredLocally = self.isStoredLocally

        if localArtworkURL.isEmpty {
            localArtworkURL = URL(fileURLWithPath: "Locally Stored Artwork").appendingPathComponent("\(artworkURL.SHA256()).png").path
        }

        let threadSafeSelf = KZThreadSafeReference(to: self)

        let fileManager = FileManager.default
        let documentURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let localArtworkAbsoluteURL = documentURL.appendingPathComponent(localArtworkURL)

        if let image = UIImage(contentsOfFile: localArtworkAbsoluteURL.path) {
            return MPMediaItemArtwork.init(boundsSize: .zero, requestHandler: { _ in return image })
        } else if self.localArtworkURL.isNotEmpty {
            DispatchQueue.global().async {
                guard let safeSelf = threadSafeSelf.resolve() else {
                    return
                }
                try! safeSelf.realm?.write {
                    safeSelf.localArtworkURL = ""
                }
            }
        }

        if artworkURL.isNotEmpty {
            let safeConfig = config?.safeRefrence
            DispatchQueue.global(qos: .background).async {
                if let config = safeConfig?.resolve() {
                    artworkURL = "\(config.connectionURI)/photo/:/transcode?url=\(artworkURL)&width=\(Int(UIScreen.main.bounds.height))&height=\(Int(UIScreen.main.bounds.height))&minSize=1&X-Plex-Token=\(config.authToken)"
                }

                if let url = URL(string: artworkURL), !url.isFileURL {
                    KZPlayer.imageDownloader.download(URLRequest(url: url)) { response in
                        guard let image = response.result.value else {
                            return callCompletionHandler(artwork: .default)
                        }
                        image.af_inflate()

                        KZPlayer.executeOn(queue: KZPlayer.libraryQueue) {
                            if isStoredLocally, let safeSelf = threadSafeSelf.resolve(), let pngData = image.pngData() {
                                do {
                                    let fileName = "\(artworkURL.SHA256()).png"
                                    let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                                    var absoluteFilePath = documentURL.appendingPathComponent("Locally Stored Artwork")
                                    var filePath = URL(fileURLWithPath: "Locally Stored Artwork")
                                    try FileManager.default.createDirectory(at: absoluteFilePath, withIntermediateDirectories: true, attributes: nil)

                                    absoluteFilePath.appendPathComponent(fileName)
                                    filePath.appendPathComponent(fileName)
                                    try? FileManager.default.removeItem(at: absoluteFilePath)
                                    try pngData.write(to: absoluteFilePath)
                                    try safeSelf.realm?.write {
                                        safeSelf.localArtworkURL = filePath.path
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        }
                        callCompletionHandler(artwork: MPMediaItemArtwork(boundsSize: .zero, requestHandler: { _ in
                            return image
                        }))
                    }
                    return // Alamofire will handle the default
                }
            }

            return nil
        }

        localArtworkURL = documentURL.appendingPathComponent(artworkURL).path
        if let image = UIImage(contentsOfFile: localArtworkURL) {
            return MPMediaItemArtwork.init(boundsSize: .zero, requestHandler: { _ in return image })
        }

        guard let systemID = systemID.components(separatedBy: "-").last else {
            return .default
        }

        let p = MPMediaPropertyPredicate(value: systemID, forProperty: MPMediaItemPropertyPersistentID)
        let q = MPMediaQuery(filterPredicates: [p])

        if let artwork = q.items?.first?.artwork {
            return artwork
        }

        return .default
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

class KZPlayerQueueItem: Object, KZPlayerItemBase {
    @objc dynamic var orig: KZPlayerItem?
    @objc dynamic var position = 0

    convenience init(orig: KZPlayerItem) {
        self.init()
        self.orig = orig
    }
}

class KZPlayerShuffleQueueItem: Object, KZPlayerItemBase {
    @objc dynamic var orig: KZPlayerItem?
    @objc dynamic var position = 0

    convenience init(orig: KZPlayerItem) {
        self.init()
        self.orig = orig
    }
}

class KZPlayerUpNextItem: Object, KZPlayerItemBase {
    @objc dynamic var orig: KZPlayerItem?
    @objc dynamic var position = 0

    convenience init(orig: KZPlayerItem) {
        self.init()
        self.orig = orig
    }
}

class KZPlayerHistoryItem: Object, KZPlayerItemBase {
    @objc dynamic var orig: KZPlayerItem?
    @objc dynamic var position = 0

    convenience init(orig: KZPlayerItem) {
        self.init()
        self.orig = orig
    }
}

extension Array where Element: KZPlayerItemBase {
    func withShuffledPosition() -> Array<Element> {
        for result in self {
            result.position = Int(arc4random_uniform(UInt32(count)))
        }

        return sorted(by: { $0.position < $1.position })
    }
}

extension UIImageView {

    func setImage(with item: KZPlayerItemBase, isStillValid: (() -> Bool)? = nil) {
        image = item.fetchArtwork { artwork in
            if let isStillValid = isStillValid, !isStillValid() {
                return
            }
            self.image = artwork.image(at: self.bounds.size)
            }?.image(at: bounds.size)
    }

}

extension AnyRealmCollection where Element: KZPlayerItemBase {
    func withShuffledPosition() -> Results<Element> {
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

extension Results {
    func toArray() -> [Element] {
        var arr = [Element]()
        for result in self {
            arr.append(result)
        }
        return arr
    }
}
