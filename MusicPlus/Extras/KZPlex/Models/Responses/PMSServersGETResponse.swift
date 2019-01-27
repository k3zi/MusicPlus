//
//  Servers.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import XMLMapper

class PMSServersGETResponse: XMLMappable, MediaContainer {

    var nodeName: String!
    var plex: KZPlex! {
        didSet {
            servers.forEach {
                $0.plex = self.plex
            }
        }
    }

    var friendlyName: String!
    var identifier: String!
    var machineIdentifier: String!
    var size: Int!

    var servers: [Server]!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        friendlyName <- map.attributes["friendlyName"]
        identifier <- map.attributes["identifier"]
        machineIdentifier <- map.attributes["machineIdentifier"]
        size <- map.attributes["size"]

        servers <- map["Server"]
    }

}
