// 
//  MPSongCollectionViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
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
    // Doesn't need to be updated frequently so we can just store an array
    var displayedFilteredCollection: [KZPlayerItemBase]?
    let searchViewController = UISearchController(searchResultsController: nil)
    var currentCollectionToken: NotificationToken?
    var peekPop: PeekPop!

    var collectionGenerator: () -> KZPlayerItemCollection? = { return nil } {
        didSet {
            DispatchQueue.main.async {
                self.registerNewCollection()
            }
        }
    }

    var filteredCollectionnGenerator: () -> KZPlayerItemCollection? = { return nil } {
        didSet {
            displayedFilteredCollection = filteredCollectionnGenerator()?.toArray()
            tableView.reloadData()
        }
    }

    init() {
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
            guard let collection = self.filteredCollectionnGenerator() ?? self.collectionGenerator() else {
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

        searchViewController.dimsBackgroundDuringPresentation = false
        searchViewController.searchResultsUpdater = self
        searchViewController.searchBar.tintColor = .white
        searchViewController.hidesNavigationBarDuringPresentation = false
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let textField = searchViewController.searchBar.textField {
            let backgroundView = textField.subviews.first
            if #available(iOS 11.0, *) { // If `searchController` is in `navigationItem`
                backgroundView?.backgroundColor = UIColor.init(white: 0, alpha: 0.2)
                backgroundView?.subviews.forEach { $0.removeFromSuperview() }
            }
            backgroundView?.layer.cornerRadius = 10.5
            backgroundView?.layer.masksToBounds = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
            case .goToArtist:
                guard let artist = item.artist else {
                    return
                }
                let vc = ArtistViewController(artist: artist)
                self.navigationController?.pushViewController(vc, animated: true)
            case .goToAlbum:
                guard let album = item.album else {
                    return
                }
                let vc = AlbumViewController(album: album)
                self.navigationController?.pushViewController(vc, animated: true)
            default:
                break
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
            guard let safeInitialSong = wrappedSong.resolve(), let collection = self.filteredCollectionnGenerator() ?? self.collectionGenerator(), let index = collection.firstIndex(of: safeInitialSong) else {
                return
            }

            KZPlayer.sharedInstance.play(collection, initialSong: collection[index])
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let _ = displayedFilteredCollection {
            return 1
        }

        return super.numberOfSections(in: tableView)
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        if let displayedFilteredCollection = displayedFilteredCollection {
            return displayedFilteredCollection as [Any]
        }

        return super.tableViewCellData(tableView, section: section)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let _ = displayedFilteredCollection {
            return nil
        }

        return super.tableView(tableView, titleForHeaderInSection: section)
    }

    override func tableViewShowsSectionHeader(_ tableView: UITableView) -> Bool {
        if let _ = displayedFilteredCollection {
            return false
        }

        return super.tableViewShowsSectionHeader(tableView)
    }

}

extension MPSongCollectionViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchViewController.searchBar.text, text.count > 0 else {
            filteredCollectionnGenerator = { return nil }
            tableView.reloadData()
            return
        }

        filteredCollectionnGenerator = {
            guard let collection = self.collectionGenerator()?.filter("title CONTAINS[c] %@ OR artist.name CONTAINS[c] %@ OR album.name CONTAINS[c] %@", text, text, text) else {
                return nil
            }

            return AnyRealmCollection(collection)
        }
    }

}
