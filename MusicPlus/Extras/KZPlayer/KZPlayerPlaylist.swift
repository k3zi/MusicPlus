// 
//  KZPlayerPlaylist.swift
//  KZPlayer
// 
//  Created by Kesi Maduka on 10/26/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit
import RealmSwift

class KZPlayerPlaylist: Object {
    var items = List<KZPlayerPlaylistItem>()

    func add(_ item: KZPlayerItem) {
        let newItem = KZPlayerPlaylistItem(orig: item)
        newItem.order = items.count + 1
        items.append(newItem)
    }

    func addItems(_ items: [KZPlayerItem]) {
        for item in items {
            add(item)
        }
    }

    func remove(_ index: Int) {
        items.remove(at: index)
    }

    func exchange(_ from: Int, to: Int) {
        items.swapAt(from, to)
    }
}

class KZPlayerPlaylistItem: KZPlayerUpNextItem {
    @objc var order = 0
}
