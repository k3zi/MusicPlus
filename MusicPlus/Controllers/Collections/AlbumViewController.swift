// 
//  AlbumViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class AlbumViewController: MPSectionedTableViewController, PeekPopPreviewingDelegate {

    let album: KZPlayerAlbum
    var peekPop: PeekPop!

    init(album: KZPlayerAlbum) {
        self.album = album
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        tableView = UITableView(frame: CGRect.zero, style: .plain) // use plain so the header is sticky
        super.viewDidLoad()

        peekPop = PeekPop(viewController: self)
        peekPop.registerForPreviewingWithDelegate(self, sourceView: tableView)

        let titleView = UILabel()
        titleView.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        titleView.textColor = RGB(255)
        titleView.text = "\(album.songs.count) tracks / \(album.durationText())"
        titleView.sizeToFit()
        navigationItem.titleView = titleView
        let button = UIButton.styleForBack()
        button.addTarget(self, action: #selector(popNavigationController), for: .touchDown)
        navigationItem.leftBarButtonItems?.append(UIBarButtonItem(customView: button))

        tableView.register(cellType: MPAlbumSongTableViewCell.self)
        tableView.register(cellType: MPShuffleTableViewCell.self)
        tableView.sectionIndexMinimumDisplayRowCount = Int.max
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

    override func setupConstraints() {
        super.setupConstraints()

        shadowTopConstraint?.constant = 135
    }

    override func fetchData() {
        sections.removeAll()
        var songs = [Any]()
        album.songs.sorted(byKeyPath: "trackNum", ascending: true).forEach({ songs.append($0) })
        let section = TableSection(sectionName: album.name, sectionObjects: songs)
        sections.append(section)

        tableView.reloadData()
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        if indexPath?.row == 0 {
            return MPShuffleTableViewCell.self
        }

        return MPAlbumSongTableViewCell.self
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return [1] + super.tableViewCellData(tableView, section: section)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return MPAlbumSectionHeaderView(album: album)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 135
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 135
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)

        for cell in self.tableView.visibleCells {
            let hiddenFrameHeight = scrollView.contentOffset.y + self.tableView(tableView, heightForHeaderInSection: 0) - cell.frame.origin.y

            if hiddenFrameHeight >= 0 || hiddenFrameHeight <= cell.frame.size.height {
                self.maskCell(cell, fromTopWithMargin: hiddenFrameHeight)
            }
        }
    }

    func maskCell(_ cell: UITableViewCell, fromTopWithMargin margin: CGFloat) {
        cell.layer.mask = visibilityMaskForCell(cell, withLocation: margin/cell.frame.size.height)
        cell.layer.masksToBounds = true
    }

    func visibilityMaskForCell(_ cell: UITableViewCell, withLocation location: CGFloat) -> CAGradientLayer {
        let mask = CAGradientLayer()
        mask.frame = cell.bounds
        mask.colors = [RGB(255, a: 0.0).cgColor, RGB(255, a: 1.0).cgColor]
        mask.locations = [NSNumber(value: Float(location) as Float), NSNumber(value: Float(location) as Float)]
        return mask
    }

    @objc func popNavigationController() {
        self.navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row > 0 else {
            let wrappedAlbum = KZThreadSafeReference(to: album)
            KZPlayer.executeOn(queue: KZPlayer.libraryQueue) {
                guard let safeAlbum = wrappedAlbum.resolve() else {
                    return
                }

                let player = KZPlayer.sharedInstance
                player.play(AnyRealmCollection(safeAlbum.songs), shuffle: true)
            }
            return
        }

        let songs = tableViewCellData(tableView, section: indexPath.section)

        guard songs.count > 0 else {
            return
        }

        guard let initialSong = songs[indexPath.row] as? KZPlayerItem else {
            return
        }

        let wrappedSong = KZThreadSafeReference(to: initialSong)
        let wrappedAlbum = KZThreadSafeReference(to: album)

        KZPlayer.executeOn(queue: KZPlayer.libraryQueue) {
            guard let safeInitialSong = wrappedSong.resolve(), let safeAlbum = wrappedAlbum.resolve() else {
                return
            }

            let collection = AnyRealmCollection(safeAlbum.songs.sorted(byKeyPath: "trackNum", ascending: true))
            let player = KZPlayer.sharedInstance
            player.play(collection, initialSong: safeInitialSong, shuffle: false)
        }
    }
}
