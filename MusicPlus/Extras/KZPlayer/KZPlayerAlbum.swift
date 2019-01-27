// 
//  KZPlayerAlbum.swift
//  KZPlayer
// 
//  Created by Kesi Maduka on 10/24/15.
//  Copyright © 2015 Kesi Maduka. All rights reserved.
// 

import UIKit
import MediaPlayer
import RealmSwift

class KZPlayerAlbum: Object, RealmGenerating {
    @objc dynamic var name = ""
    @objc dynamic var liked = false

    @objc dynamic var artist: KZPlayerArtist?
    var songs = LinkingObjects(fromType: KZPlayerItem.self, property: "album")
    @objc dynamic var key = ""

    convenience init(name: String, artist: KZPlayerArtist) {
        self.init()

        self.name = name
        self.artist = artist
        self.key = "\(name)-\(artist.name)"
    }

    override class func primaryKey() -> String? {
        return "key"
    }

    func realmGenerator() -> (() -> Realm?) {
        // First aquire things that can not go across threads
        let identifier = songs.first { $0.libraryUniqueIdentifier.isNotEmpty }?.libraryUniqueIdentifier
        return {
            guard let library = KZRealmLibrary.libraries.first(where: { $0.uniqueIdentifier == identifier }) else {
                return nil
            }

            return library.realm()
        }
    }

    func totalDuration() -> Double {
        var sum = 0.0
        songs.forEach {
            sum = sum + $0.duration
        }
        return sum
    }

    func durationText() -> String {
        let duration = totalDuration()
        let (days, hrf) = modf(duration / 86400)
        let (hours, minf) = modf(hrf * 24)
        let minutes = Int(minf * 60)

        var output = [String]()

        if days > 0 { output.append("\(days) day\(days == 1 ? "" : "s")") }
        if hours > 0 { output.append("\(Int(hours)) hour\(hours == 1 ? "" : "s")") }
        if minutes > 0 { output.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }

        return output.joined(separator: " ")
    }
}
