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

class MPSongCollectionViewController: MPSectionedTableViewController, PeekPopPreviewingDelegate {

    var displayedCollection: KZPlayerItemCollection?
    var currentCollectionToken: NotificationToken?
    var peekPop: PeekPop!

    var collectionGenerator: () -> KZPlayerItemCollection? {
        didSet {
            DispatchQueue.main.async {
                self.registerNewCollection()
            }
        }
    }

    init() {
        collectionGenerator = { return nil }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func registerNewCollection() {
        currentCollectionToken?.invalidate()
        currentCollectionToken = nil

        guard let collection = collectionGenerator() else {
            displayedCollection = nil
            sections = []
            tableView.reloadData()
            return
        }

        currentCollectionToken = collection.observe { [weak self] changes in
            guard let self = self else {
                return
            }

            switch changes {
            case .initial(let collection):
                self.updateSections(collection: AnyRealmCollection(collection))
                break
            case .update(_, let deletions, let insertions, _):
                if deletions.count > 0 || insertions.count > 0 {
                    self.updateSections(collection: AnyRealmCollection(collection))
                }
                break
            case .error:
                break
            }
        }
    }

    func updateSections(collection: KZPlayerItemCollection) {
        let alpha = CharacterSet.alphanumerics
        let numeric = CharacterSet.decimalDigits

        var sections = [TableSection]()

        for item in collection {
            let title = item.titleText()
            guard let firstChar = title.capitalized.first else {
                continue
            }

            var firstCharString = String(firstChar)
            let charSet = CharacterSet(charactersIn: firstCharString)

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

        displayedCollection = collection
        self.sections = sections
        tableView.reloadData()
    }

    func playAllShuffled() {
        KZPlayer.executeOn(queue: KZPlayer.libraryQueue) {
            guard let collection = self.collectionGenerator() else {
                return
            }

            let player = KZPlayer.sharedInstance
            player.play(collection, shuffle: true)
        }
    }

    // MARK: Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(cellType: MPSongTableViewCell.self)

        peekPop = PeekPop(viewController: self)
        peekPop.registerForPreviewingWithDelegate(self, sourceView: tableView)
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return MPSongTableViewCell.self
    }

    func previewingContext(_ previewingContext: PreviewingContext, viewForLocation location: CGPoint) -> UIView? {
        guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }

        guard let modelCell = cell as? KZTableViewCell, let item = modelCell.model as? KZPlayerItemBase else {
            return nil
        }

        return PopupMenuItemView(item: item) { action in
            switch action {
            case .play:
                self.tableView(self.tableView, didSelectRowAt: indexPath)
            case .addUpNext:
                KZPlayer.sharedInstance.addUpNext(item.originalItem)
            }
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
        KZPlayer.executeOn(queue: KZPlayer.libraryQueue) {
            guard let safeInitialSong = wrappedSong.resolve(), let collection = self.collectionGenerator(), let index = collection.firstIndex(of: safeInitialSong) else {
                return
            }

            let player = KZPlayer.sharedInstance
            player.play(collection, initialSong: collection[index])
        }

        NotificationCenter.default.post(name: Constants.Notification.hidePopup, object: nil)

        if MPContainerViewController.sharedInstance.playerViewStyle  == .hidden {
            MPContainerViewController.sharedInstance.playerViewStyle = .full
        }
    }

}
