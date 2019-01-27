//
//  SyncItem.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/12.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import XMLMapper

class SyncItem: XMLMappable, Hashable {

    static func == (lhs: SyncItem, rhs: SyncItem) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var nodeName: String!
    var plex: KZPlex!
    var directory: Directory!
    var connection: Connection!
    var device: Device!

    var id: Int!
    var clientIdentifier: String!
    var version: Int!
    var location: String!

    var status: Status!
    var server: Server!
    var mediaSettings: MediaSettings!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        id <- map.attributes["id"]
        clientIdentifier <- map.attributes["clientIdentifier"]
        version <- map.attributes["version"]

        var location: Location?
        location <- map["Location"]
        self.location = location?.uri ?? ""

        status <- map["Status"]
        server <- map["Server"]
        mediaSettings <- map["MediaSettings"]
    }
}
