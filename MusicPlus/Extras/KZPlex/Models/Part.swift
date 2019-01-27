//
//  Part.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import XMLMapper

class Part: XMLMappable, Hashable {

    static func == (lhs: Part, rhs: Part) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var nodeName: String!
    var plex: KZPlex!
    var connection: Connection!

    var id: Int!
    var key: String!
    var duration: Double!
    var file: String!
    var size: Int!
    var audioProfile: String!
    var container: String!
    var has64bitOffsets: Bool!
    var hasThumbnail: Bool!
    var optimizedForStreaming: Bool!
    var syncState: String?

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        id <- map.attributes["id"]
        key <- map.attributes["key"]
        duration <- map.attributes["duration"]
        file <- map.attributes["file"]
        size <- map.attributes["size"]
        audioProfile <- map.attributes["audioProfile"]
        container <- map.attributes["container"]
        syncState <- map.attributes["syncState"]
        has64bitOffsets <- (map.attributes["has64bitOffsets"], XMLBoolFromIntTransform())
        hasThumbnail <- (map.attributes["hasThumbnail"], XMLBoolFromIntTransform())
        optimizedForStreaming <- (map.attributes["optimizedForStreaming"], XMLBoolFromIntTransform())
    }
}
