// 
//  ArtistsViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class ArtistsViewController: MPSectionedTableViewController {

    static let shared = ArtistsViewController()
    var peekPop: PeekPop!

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Artists"
        tableView.register(cellType: MPArtistTableViewCell.self)

        peekPop = PeekPop(viewController: self)
        peekPop.registerForPreviewingWithDelegate(self, sourceView: tableView)

        self.setUpLibraryBarItem()

        NotificationCenter.default.addObserver(forName: .libraryDidChange, object: nil, queue: nil) { _ in
            self.fetchData()
            self.setUpLibraryBarItem()
        }
    }

    // MARK: Setup View

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return MPArtistTableViewCell.self
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        guard let artist = tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerArtist else {
            return
        }

        let vc = ArtistViewController(artist: artist)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func collection() -> Results<KZPlayerArtist>? {
        return KZPlayer.sharedInstance.currentLibrary?.realm().objects(KZPlayerArtist.self)
    }

    override func fetchData() {
        sections.removeAll()

        let alpha = CharacterSet.alphanumerics
        let numeric = CharacterSet.decimalDigits

        guard let collection = collection() else {
            return tableView.reloadData()
        }

        for item in collection {
            guard let firstChar = item.name.capitalized.first else {
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

        tableView.reloadData()
    }

}

extension ArtistsViewController: PeekPopPreviewingDelegate {

    func previewingContext(_ previewingContext: PreviewingContext, viewForLocation location: CGPoint) -> UIView? {
        guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }

        guard let modelCell = cell as? KZTableViewCell, let item = modelCell.model as? KZPlayerArtist else {
            return nil
        }

        return PopupMenuItemView(item: item, exclude: [.goToAlbum, .goToArtist]) { action in
            switch action {
            case .play:
                let wrappedArtist = KZThreadSafeReference(to: item)
                KZPlayer.executeOn(queue: KZPlayer.libraryQueue) {
                    guard let safeArtist = wrappedArtist.resolve() else {
                        return
                    }

                    let collection = AnyRealmCollection(safeArtist.songs)
                    KZPlayer.sharedInstance.play(collection, shuffle: false)
                }
            case .addUpNext:
                let collection = AnyRealmCollection(item.songs)
                KZPlayer.sharedInstance.addUpNext(collection.toArray())
            default:
                break
            }
        }
    }

}
