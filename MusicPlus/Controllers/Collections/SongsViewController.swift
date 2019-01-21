// 
//  SongsViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class SongsViewController: MPSongCollectionViewController {

    static let shared = SongsViewController()
    let shuffleButton = MPShuffleHeaderView(frame: .zero)

    // MARK: - Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Songs"
        tableView.tableHeaderView = shuffleButton
        tableView.delaysContentTouches = false

        shuffleButton.addTarget(self, action: #selector(shuffle), for: .touchUpInside)

        NotificationCenter.default.addObserver(forName: .libraryDidChange, object: nil, queue: nil) { _ in
            self.collectionGenerator = {
                return KZPlayer.sharedInstance.currentLibrary?.allSongs
            }
        }
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
