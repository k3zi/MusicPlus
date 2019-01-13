// 
//  AlbumsViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class AlbumsViewController: KZViewController {

    static let shared = AlbumsViewController()

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 8.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let cellsPerRow = CGFloat(3)
        let cellWidth = (Constants.UI.Screen.width - cellsPerRow*10)/cellsPerRow
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth + 50)

        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.clipsToBounds = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 8, bottom: 8, right: 8)
        collectionView.register(cellType: MPAlbumCollectionViewCell.self)

        return collectionView
    }()
    let shadowView = UIView()
    let shadowLayer = CAGradientLayer()
    var shadowTopConstraint: NSLayoutConstraint?

    var uiCollection: Results<KZPlayerAlbum>?
    var imageCache = [(row: Int, image: UIImage)]()
    let cacheCapacity = 1000

    init() {
        self.imageCache.reserveCapacity(cacheCapacity)
        super.init(nibName: nil, bundle: nil)
    }

    func collection() -> Results<KZPlayerAlbum>? {
        return KZPlayer.sharedInstance.currentLibrary?.realm().objects(KZPlayerAlbum.self).sorted(byKeyPath: "name")
    }

    override func fetchData() {
        uiCollection = collection()
        collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Albums"
        view.backgroundColor = UIColor.clear
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menuBT"), style: .plain, target: MPContainerViewController.sharedInstance, action: #selector(MPContainerViewController.toggleMenu))

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.isPrefetchingEnabled = true
        view.addSubview(collectionView)

        shadowView.backgroundColor = UIColor.clear
        shadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        shadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        shadowLayer.colors = [RGB(0).cgColor, UIColor.clear.cgColor]
        shadowView.layer.insertSublayer(shadowLayer, at: 0)
        shadowView.alpha = 0.0
        view.addSubview(shadowView)

        NotificationCenter.default.addObserver(forName: Constants.Notification.libraryDidChange, object: nil, queue: nil) { _ in
            self.fetchData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        shadowLayer.frame = CGRect(x: 0, y: 0, width: shadowView.frame.size.width, height: 10)
    }

    override func setupConstraints() {
        super.setupConstraints()

        collectionView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        collectionView.autoPinEdge(toSuperviewEdge: .left)
        collectionView.autoPinEdge(toSuperviewEdge: .right)
        collectionView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)

        shadowTopConstraint = shadowView.autoPinEdge(.top, to: .top, of: collectionView)
        shadowView.autoPinEdge(toSuperviewEdge: .left)
        shadowView.autoPinEdge(toSuperviewEdge: .right)
        shadowView.autoSetDimension(.height, toSize: 21)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let percent = min(scrollView.contentOffset.y/300.0, 0.3)
        shadowView.alpha = percent
        NotificationCenter.default.post(name: Constants.Notification.hidePopup, object: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 8.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let cellsPerRow = CGFloat(3)
        let cellWidth = (size.width - cellsPerRow*10)/cellsPerRow
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth + 50)

        for cell in collectionView.visibleCells {
            if let cell = cell as? MPAlbumCollectionViewCell {
                cell.widthConstraint?.constant = layout.itemSize.width
            }
        }

        layout.invalidateLayout()
        collectionView.delegate = self
        collectionView.dataSource = self
    }

}

extension AlbumsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uiCollection?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as MPAlbumCollectionViewCell

        guard let uiCollection = uiCollection else {
            return cell
        }

        let album = uiCollection[indexPath.row]
        cell.titleLabel.text = album.name
        cell.subtitleLabel.text = album.artist?.name
        cell.album = album
        if let song = album.songs.first, let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            DispatchQueue.main.async {
                if let image = self.cachedImage(at: indexPath) {
                    cell.imageView.image = image
                } else {
                    song.fetchArtwork { artwork in
                        guard album.key == cell.album?.key, let image = artwork.image(at: layout.itemSize) else {
                            return
                        }

                        cell.imageView.image = image
                        self.cache(image: image, at: indexPath)
                    }
                }
            }
            cell.widthConstraint?.constant = layout.itemSize.width
            cell.layoutIfNeeded()
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let uiCollection = uiCollection else {
            return
        }

        let album = uiCollection[indexPath.row]
        let vc = AlbumViewController(album: album)
        self.navigationController?.pushViewController(vc, animated: true)
    }

}

extension AlbumsViewController: UICollectionViewDataSourcePrefetching {

    func cache(image: UIImage, at index: IndexPath) {
        if !imageCache.contains(where: { (cache: (row: Int, image: UIImage)) -> Bool in
            return cache.row == index.row
        }) {
            imageCache = Array(imageCache.suffix(cacheCapacity))
            imageCache.append((row: index.row, image: image))
        }
    }

    func cachedImage(at index: IndexPath) -> UIImage? {
        return imageCache.filter({ (cache: (row: Int, image: UIImage)) -> Bool in
            return cache.row == index.row
        }).first?.image
    }

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let uiCollection = uiCollection, let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        for indexPath in indexPaths {
            let album = uiCollection[indexPath.row]
            guard let song = album.songs.first else {
                continue
            }

            song.fetchArtwork { artwork in
                guard let image = artwork.image(at: layout.itemSize) else {
                    return
                }

                self.cache(image: image, at: indexPath)
            }
        }
    }

}
