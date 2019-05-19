// 
//  SongsViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class SongsViewController: MPSongCollectionViewController {

    static let shared = SongsViewController()
    let shuffleButton = MPTitleHeaderView(frame: .zero)

    // MARK: - Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Songs"
        definesPresentationContext = true
        tableView.tableHeaderView = shuffleButton
        tableView.delaysContentTouches = false

        shuffleButton.addTarget(self, action: #selector(shuffle), for: .touchUpInside)

        setUpLibraryBarItem()

        NotificationCenter.default.addObserver(forName: .libraryDidChange, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.collectionGenerator = {
                return KZPlayer.sharedInstance.currentLibrary?.allSongs
            }

           self.setUpLibraryBarItem()
        }.dispose(with: self)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let percent = min((scrollView.contentOffset.y - shuffleButton.frame.size.height)/300.0, 0.3)
        shadowView.alpha = percent
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shuffleButton.frame.size.width = Constants.UI.Screen.width
    }

    @objc func shuffle(_ button: UIButton) {
        self.playAllShuffled()
    }

}
