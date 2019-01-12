//
//  KZPlayerPlexTrack.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/12.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class KZPlayerPlexTrack: Object {
    @objc dynamic var updatedAt = Date()

    convenience init(track: Track) {
        self.init()
        updatedAt = track.updatedAt
    }
}
