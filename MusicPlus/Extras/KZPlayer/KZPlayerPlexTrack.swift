//
//  KZPlayerPlexTrack.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/12.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

class KZPlayerPlexTrack: Object {
    @objc dynamic var updatedAt = Date()
    // This should actually be dependent on settings for the default value
    @objc dynamic var shouldSyncRaw = true

    convenience init(track: Track) {
        self.init()
        updatedAt = track.updatedAt
    }
}
