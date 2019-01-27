//
//  Server.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import XMLMapper

class Server: XMLMappable {
    var nodeName: String!
    var plex: KZPlex!

    var accessToken: String!
    var address: String!
    var createdAt: Date!
    var host: String!
    var localAddresses: String!
    var machineIdentifier: String!
    var name: String!
    var owned: Bool!
    var port: Int!
    var scheme: String!
    var synced: Bool!
    var updatedAt: Date!
    var version: String!

    // Shared Server
    var sourceTitle: String?
    var ownerId: Int?
    var home: Bool?

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        accessToken <- map.attributes["accessToken"]
        address <- map.attributes["address"]
        createdAt <- (map.attributes["createdAt"], XMLDateTransform())
        host <- map.attributes["host"]
        localAddresses <- map.attributes["localAddresses"]
        machineIdentifier <- map.attributes["machineIdentifier"]
        name <- map.attributes["name"]
        owned <- (map.attributes["owned"], XMLBoolFromIntTransform())
        port <- map.attributes["port"]
        scheme <- map.attributes["scheme"]
        synced <- (map.attributes["synced"], XMLBoolFromIntTransform())
        updatedAt <- (map.attributes["updatedAt"], XMLDateTransform())
        version <- map.attributes["version"]

        home <- (map.attributes["home"], XMLBoolFromIntTransform())
        ownerId <- map.attributes["ownerId"]
        sourceTitle <- map.attributes["sourceTitle"]
    }
}
