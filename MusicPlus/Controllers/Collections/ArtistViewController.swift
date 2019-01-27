// 
//  ArtistViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class ArtistViewController: MPSectionedTableViewController {

    let artist: KZPlayerArtist
    var expandedSections = [Bool]()
    let shuffleButton = MPTitleHeaderView(frame: CGRect.zero)

    init(artist: KZPlayerArtist) {
        self.artist = artist
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = artist.name
        let button = UIButton.styleForBack()
        button.addTarget(self, action: #selector(popViewController), for: .touchDown)
        navigationItem.leftBarButtonItems?.append(UIBarButtonItem(customView: button))

        tableView.register(cellType: MPSongTableViewCell.self)
        tableView.sectionIndexMinimumDisplayRowCount = Int.max
        tableView.tableHeaderView = shuffleButton
        tableView.delaysContentTouches = false

        shuffleButton.label.text = "Shuffle Artist"
        shuffleButton.addTarget(self, action: #selector(shuffle), for: .touchUpInside)

        NotificationCenter.default.addObserver(forName: .libraryDidChange, object: nil, queue: nil) { _ in
            self.fetchData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shuffleButton.frame.size.width = Constants.UI.Screen.width
    }

    override func fetchData() {
        sections.removeAll()
        artist.albums.forEach {
            var songs = [Any]()
            $0.songs.forEach({ songs.append($0) })
            let section = TableSection(sectionName: $0.name, sectionObjects: songs)
            sections.append(section)
            if expandedSections.count < sections.count {
                expandedSections.append(false)
            }
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let album = artist.albums[section]
        let view = MPArtistSectionHeaderView(album: album)

        view.tag = section
        view.toggleButton.tag = section
        view.toggleButton.isSelected = expandedSections[section]
        view.bottomSeperator.isHidden = view.toggleButton.isSelected || artist.albums.count == (section + 1)
        view.toggleButton.addTarget(self, action: #selector(toggleSection), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSection))
        view.addGestureRecognizer(tap)

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 90
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 90
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !expandedSections[section] {
            return 0
        }

        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    @objc func toggleSection(_ sender: UIButton) {
        expandedSections[sender.tag] = !expandedSections[sender.tag]
        tableView.reloadSections(IndexSet(integer: sender.tag), with: .automatic)
    }

    @objc func didTapSection(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else {
            return
        }

        view.backgroundColor = RGB(255, a: 0.2)

        delay(0.3) {
            UIView.animate(withDuration: Constants.UI.Animation.cellHighlight, animations: {
                view.backgroundColor = UIColor.clear
            }, completion: nil)
        }

        let section = view.tag
        let album = artist.albums[section]

        let vc = AlbumViewController(album: album)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc func popViewController() {
        _ = self.navigationController?.popViewController(animated: true)
    }

    @objc func shuffle(_ button: MPTitleHeaderView) {
        let wrappedArtist = KZThreadSafeReference(to: artist)
        KZPlayer.executeOn(queue: KZPlayer.libraryQueue) {
            guard let safeArtist = wrappedArtist.resolve() else {
                return
            }

            let collection = AnyRealmCollection(safeArtist.songs)
            KZPlayer.sharedInstance.play(collection, shuffle: true)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableViewCellData(tableView, section: indexPath.section).count > 0 else {
            return
        }

        guard let initialSong = tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZPlayerItem else {
            return
        }

        let wrappedArtist = KZThreadSafeReference(to: artist)
        let wrappedSong = KZThreadSafeReference(to: initialSong)
        KZPlayer.executeOn(queue: KZPlayer.libraryQueue) {
            guard let safeInitialSong = wrappedSong.resolve(), let safeArtist = wrappedArtist.resolve() else {
                return
            }

            let collection = AnyRealmCollection(safeArtist.songs)
            guard let index = collection.firstIndex(of: safeInitialSong) else {
                return
            }

            KZPlayer.sharedInstance.play(collection, initialSong: collection[index])
        }
    }

}
