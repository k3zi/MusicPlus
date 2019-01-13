// 
//  ArtistsViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class ArtistsViewController: MPSectionedTableViewController {

    static let shared = ArtistsViewController()

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

        NotificationCenter.default.addObserver(forName: Constants.Notification.libraryDidChange, object: nil, queue: nil) { _ in
            self.fetchData()
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
