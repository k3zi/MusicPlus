//
//  APIResourcesGETResponse.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper

class APIResourcesGETResponse: XMLMappable, MediaContainer {

    var nodeName: String!
    var plex: KZPlex! {
        didSet {
            devices.forEach({
                $0.plex = self.plex
            })
        }
    }

    var devices: [Device]!
    var size: Int!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        devices <- map["Device"]
        size <- map.attributes["size"]
    }

}
