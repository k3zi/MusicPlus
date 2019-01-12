//
//  Status.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/12.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper

class Status: XMLMappable {
    var nodeName: String!

    var state: String!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        state <- map.attributes["state"]
    }
}
