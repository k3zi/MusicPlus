//
//  Track.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import XMLMapper
import PromiseKit
import AwaitKit

class Track: XMLMappable, Hashable {

    static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.ratingKey == rhs.ratingKey
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ratingKey)
    }

    var nodeName: String!
    var plex: KZPlex!
    var directory: Directory!
    var connection: Connection!
    var device: Device!

    var ratingKey: Int!
    var key: String!
    var parentRatingKey: Int!
    var grandparentRatingKey: Int!
    var type: String!
    var title: String!
    var grandparentKey: String!
    var parentKey: String!
    var grandparentTitle: String!
    var parentTitle: String!
    var summary: String!
    var index: Int!
    var parentIndex: String!
    var year: Int!
    var thumb: String!
    var art: String?
    var parentThumb: String!
    var parentArt: String?
    var grandparentThumb: String!
    var grandparentArt: String?
    var duration: Double!

    var lastViewedAt: Date!
    var addedAt: Date!
    var updatedAt: Date!

    var media: Media!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        ratingKey <- map.attributes["ratingKey"]
        key <- map.attributes["key"]
        parentRatingKey <- map.attributes["parentRatingKey"]
        grandparentRatingKey <- map.attributes["grandparentRatingKey"]
        type <- map.attributes["type"]
        title <- map.attributes["title"]
        grandparentKey <- map.attributes["grandparentKey"]
        parentKey <- map.attributes["parentKey"]
        grandparentTitle <- map.attributes["grandparentTitle"]
        parentTitle <- map.attributes["parentTitle"]
        summary <- map.attributes["summary"]
        index <- map.attributes["index"]
        parentIndex <- map.attributes["parentIndex"]
        year <- map.attributes["year"]
        thumb <- map.attributes["thumb"]
        art <- map.attributes["art"]
        parentThumb <- map.attributes["parentThumb"]
        parentArt <- map.attributes["parentArt"]
        grandparentThumb <- map.attributes["grandparentThumb"]
        grandparentArt <- map.attributes["grandparentArt"]
        duration <- map.attributes["duration"]

        lastViewedAt <- (map.attributes["lastViewedAt"], XMLDateTransform())
        addedAt <- (map.attributes["addedAt"], XMLDateTransform())
        updatedAt <- (map.attributes["updatedAt"], XMLDateTransform())

        if index == nil {
            index = 0
        }

        media <- map["Media"]
    }

    func asPlayerItem(realm: Realm, libraryUniqueIdentifier: String) -> KZPlayerItem {
        let url = key!
        let artworkURL = thumb ?? parentThumb ?? grandparentThumb ?? art ?? parentArt ?? grandparentArt ?? ""

        return KZPlayerItem(realm: realm, artist: grandparentTitle, album: parentTitle, title: title, duration: duration / 1000, assetURL: url, isDocumentURL: false, artworkURL: artworkURL, uniqueIdentifier: String(ratingKey), libraryUniqueIdentifier: libraryUniqueIdentifier, trackNum: index, plexTrack: self)
    }
}
