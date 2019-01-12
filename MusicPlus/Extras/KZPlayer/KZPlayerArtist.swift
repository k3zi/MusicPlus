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

class KZPlayerArtist: Object {
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
}
