// 
//  MPSongCollectionViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit
import Foundation
import Dispatch

enum MPCollectionSortBy {
    case name
    case trackNumber
}

class MPSongCollectionViewController: MPSectionedTableViewController {

    var uiCollection: KZPlayerItemCollection?

    init() {
        super.init(nibName: nil, bundle: nil)
        self.uiCollection = collection()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func collection() -> KZPlayerItemCollection? {
        return nil
    }

    // MARK: Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(cellType: MPSongTableViewCell.self)
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return MPSongTableViewCell.self
    }

    override func fetchData() {
        let alpha = CharacterSet.alphanumerics
        let numeric = CharacterSet.decimalDigits

        let collection = self.collection()

        guard let uiCollection = collection else {
            return DispatchQueue.main.async {
                self.uiCollection = nil
                self.sections = []
                self.tableView.reloadData()
            }
        }

        if self.uiCollection == collection {
            return
        }

        var sections = [TableSection]()

        for item in uiCollection {
            let title = item.titleText()
            guard let firstChar = title.capitalized.first else {
                continue
            }

            var firstCharString = String(firstChar)
            let charSet = CharacterSet.init(charactersIn: firstCharString)

            if numeric.isSuperset(of: charSet) {
                firstCharString = "#"
            } else if !alpha.isSuperset(of: charSet) {
                firstCharString = "-"
            }

            var i = 0
            while i < sections.count && sections[i].sectionName < firstCharString {
                i += 1
            }

            if i < sections.count && sections[i].sectionName == firstCharString {
                sections[i].sectionObjects.append(item)
            } else {
                sections.insert(TableSection(sectionName: firstCharString, sectionObjects: [item]), at: i)
            }
        }

        DispatchQueue.main.async {
            self.uiCollection = collection
            self.sections = sections
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        guard let initialSong = tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerItem else {
            return
        }

        let wrappedSong = KZThreadSafeReference(to: initialSong)
        KZPlayer.libraryQueue.async {
            guard let safeInitialSong = wrappedSong.resolve(), let collection = self.collection(), let index = collection.firstIndex(of: safeInitialSong) else {
                return
            }

            let player = KZPlayer.sharedInstance
            player.settings.crossFadeMode = .crossFade
            player.play(collection, initialSong: collection[index])
        }

        NotificationCenter.default.post(name: Constants.Notification.hidePopup, object: nil)

        if MPContainerViewController.sharedInstance.playerViewStyle  == .hidden {
            MPContainerViewController.sharedInstance.playerViewStyle = .full
        }
    }

}
