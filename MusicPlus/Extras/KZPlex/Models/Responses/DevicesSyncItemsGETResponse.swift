//
//  DevicesSyncItemsGETResponse.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/12.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import XMLMapper

class DevicesSyncItemsGETResponse: XMLMappable {

    var nodeName: String!
    var plex: KZPlex! {
        didSet {
            items.forEach {
                $0.plex = self.plex
            }
        }
    }
    var directory: Directory! {
        didSet {
            items.forEach {
                $0.directory = self.directory
            }
        }
    }
    var connection: Connection! {
        didSet {
            items.forEach {
                $0.connection = self.connection
            }
        }
    }
    var device: Device! {
        didSet {
            items.forEach {
                $0.device = self.device
            }
        }
    }

    var clientIdentifier: String!
    var status: String!
    var items: [SyncItem]!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        clientIdentifier <- map.attributes["clientIdentifier"]
        status <- map.attributes["status"]
        items <- map["SyncItems.SyncItem"]
        if items == nil {
            items = []
        }
    }

}
