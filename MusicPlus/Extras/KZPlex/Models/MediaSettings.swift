//
//  MediaSettings.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/12.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper

class MediaSettings: XMLMappable {

    var nodeName: String!

    var audioBoost: Int!
    var maxVideoBitrate: Int!
    var musicBitrate: Int!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        audioBoost <- map.attributes["audioBoost"]
        maxVideoBitrate <- map.attributes["maxVideoBitrate"]
        musicBitrate <- map.attributes["musicBitrate"]
    }
}
