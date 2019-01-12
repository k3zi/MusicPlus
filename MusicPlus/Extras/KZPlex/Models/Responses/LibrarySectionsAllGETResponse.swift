//
//  LibrarySectionsAllGETResponse.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper

class LibrarySectionsAllGETResponse: XMLMappable, MediaContainer {

    var nodeName: String!
    var plex: KZPlex! {
        didSet {
            tracks.forEach({
                $0.plex = self.plex
            })
        }
    }

    var allowSync: Bool!
    var identifier: String!
    var mediaTagPrefix: String!
    var mediaTagVersion: Date!
    var size: Int!
    var title1: String!

    var tracks: [Track]!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        allowSync <- (map.attributes["allowSync"], XMLBoolFromIntTransform())
        identifier <- map.attributes["identifier"]
        mediaTagPrefix <- map.attributes["mediaTagPrefix"]
        mediaTagVersion <- (map.attributes["mediaTagVersion"], XMLDateTransform())
        size <- map.attributes["size"]
        title1 <- map.attributes["title1"]

        tracks <- map["Track"]
        if tracks == nil {
            tracks = []
        }
    }

}
