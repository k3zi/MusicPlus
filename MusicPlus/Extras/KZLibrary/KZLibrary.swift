//
//  KZLibrary.swift
//  Music+
//
//  Created by kezi on 2019/01/05.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import CoreSpotlight
import MobileCoreServices

class KZLibrary: Codable, Equatable {

    static func == (lhs: KZLibrary, rhs: KZLibrary) -> Bool {
        return lhs.uniqueIdentifier == rhs.uniqueIdentifier
    }

    static var libraries: [KZLibrary] {
        var result = KZPlexLibrary.plexLibraries as [KZLibrary]
        result.append(contentsOf: KZLocalLibrary.localLibraries as [KZLibrary])
        return result.sorted(by: { $0.name > $1.name })
    }

    func realm() -> Realm {
        fatalError("No realm instance returned for KZLibrary subclass.")
    }

    let name: String
    let readOnly: Bool
    let uniqueIdentifier: String
    let created: Date
    let plexLibraryConfig: PlexLibraryConfig?
    var isRefreshing = false

    init(name: String, readOnly: Bool, plexLibraryConfig: PlexLibraryConfig? = nil) {
        self.name = name
        self.readOnly = readOnly
        self.uniqueIdentifier = UUID().uuidString
        self.created = Date()
        self.plexLibraryConfig = plexLibraryConfig
    }

    func refresh() {
    }

    func save() {
    }

    var allSongs: KZPlayerItemCollection {
        return KZPlayerItemCollection(realm().objects(KZPlayerItem.self).sorted(byKeyPath: "title", ascending: true))
    }

    func addItemToSpotlight(_ item: KZPlayerItem) {
        let attr = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attr.title = item.titleText()
        attr.contentDescription = item.subtitleText()
        attr.keywords = item.searchText().components(separatedBy: " ")
        /*if let image = item.artwork().image(at: CGSize(width: 50, height: 50)) {
            attr.thumbnailData = image.pngData()
        }*/
        attr.identifier = item.systemID
        attr.path = uniqueIdentifier

        let item = CSSearchableItem(uniqueIdentifier: nil, domainIdentifier: uniqueIdentifier, attributeSet: attr)

        CSSearchableIndex.default().indexSearchableItems([item])
    }

}
