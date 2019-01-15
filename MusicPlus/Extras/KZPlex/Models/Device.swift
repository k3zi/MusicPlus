//
//  Device.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper

class Device: XMLMappable {
    var nodeName: String!
    var plex: KZPlex! {
        didSet {
            connections.forEach {
                $0.plex = self.plex
            }
        }
    }

    var accessToken: String!
    var createdAt: Date!
    var clientIdentifier: String!
    var device: String!
    var httpsRequired: Bool!
    var lastSeenAt: Date!
    var name: String!
    var owned: Bool!
    var platform: String!
    var platformVersion: String!
    var port: Int!
    var presence: Bool!
    var productVersion: String!
    var provides: String!
    var publicAddress: String!
    var publicAddressMatches: Bool!
    var synced: Bool!

    var relay: Bool?

    // Shared Device
    var sourceTitle: String?
    var ownerId: Int?
    var home: Bool?

    var connections: [Connection]!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        accessToken <- map.attributes["accessToken"]
        createdAt <- (map.attributes["createdAt"], XMLDateTransform())
        clientIdentifier <- map.attributes["clientIdentifier"]
        device <- map.attributes["device"]
        httpsRequired <- (map.attributes["httpsRequired"], XMLBoolFromIntTransform())
        lastSeenAt <- (map.attributes["lastSeenAt"], XMLDateTransform())
        name <- map.attributes["name"]
        owned <- (map.attributes["owned"], XMLBoolFromIntTransform())
        platform <- map.attributes["platform"]
        platformVersion <- map.attributes["platformVersion"]
        port <- map.attributes["port"]
        presence <- (map.attributes["presence"], XMLBoolFromIntTransform())
        productVersion <- map.attributes["productVersion"]
        provides <- map.attributes["provides"]
        publicAddress <- map.attributes["publicAddress"]
        publicAddressMatches <- (map.attributes["publicAddressMatches"], XMLBoolFromIntTransform())
        synced <- (map.attributes["synced"], XMLBoolFromIntTransform())

        relay <- (map.attributes["relay"], XMLBoolFromIntTransform())

        home <- (map.attributes["home"], XMLBoolFromIntTransform())
        ownerId <- map.attributes["ownerId"]
        sourceTitle <- map.attributes["sourceTitle"]

        connections <- map["Connection"]
        if connections == nil {
            connections = []
        }

        connections.forEach {
            $0.device = self
        }
    }
}
