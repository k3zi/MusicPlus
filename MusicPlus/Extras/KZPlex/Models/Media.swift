//
//  Media.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper

class Media: XMLMappable, Hashable {

    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var nodeName: String!
    var plex: KZPlex!
    var connection: Connection!

    var id: Int!
    var duration: Double!
    var bitrate: Int!
    var audioChannels: Int!
    var audioCodec: String!
    var container: String!
    var optimizedForStreaming: Bool!
    var audioProfile: String!
    var has64bitOffsets: Bool!

    var part: Part!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        id <- map.attributes["id"]
        duration <- map.attributes["duration"]
        bitrate <- map.attributes["bitrate"]
        audioChannels <- map.attributes["audioChannels"]
        audioCodec <- map.attributes["audioCodec"]
        container <- map.attributes["container"]
        optimizedForStreaming <- (map.attributes["optimizedForStreaming"], XMLBoolFromIntTransform())
        audioProfile <- map.attributes["audioProfile"]
        has64bitOffsets <- (map.attributes["has64bitOffsets"], XMLBoolFromIntTransform())

        part <- map["Part"]
    }
}
