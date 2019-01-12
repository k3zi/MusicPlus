//
//  Location.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper

class Location: XMLMappable {
    var nodeName: String!

    var id: Int!
    var path: String!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        id <- map.attributes["id"]
        path <- map.attributes["path"]
    }
}
