// 
//  KZPlayerArtist.swift
//  KZPlayer
// 
//  Created by Kesi Maduka on 10/24/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit
import MediaPlayer
import RealmSwift

class KZPlayerArtist: Object, RealmGenerating {
    @objc dynamic var name = ""
    @objc dynamic var liked = false

    var songs = LinkingObjects(fromType: KZPlayerItem.self, property: "artist")
    var albums = LinkingObjects(fromType: KZPlayerAlbum.self, property: "artist")

    convenience init(name: String) {
        self.init()

        self.name = name
    }

    override class func primaryKey() -> String? {
        return "name"
    }

    func realmGenerator() -> (() -> Realm?) {
        // First aquire things that can not go across threads
        let identifier = songs.first { $0.plexLibraryUniqueIdentifier.isNotEmpty }?.plexLibraryUniqueIdentifier
        return {
            guard let library = KZPlexLibrary.plexLibraries.first(where: { $0.uniqueIdentifier == identifier }) else {
                return nil
            }

            return library.realm()
        }
    }
}
