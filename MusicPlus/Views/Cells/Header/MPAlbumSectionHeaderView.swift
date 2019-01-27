// 
//  MPAlbumSectionHeaderView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class MPAlbumSectionHeaderView: UIView {

    let imageView = UIImageView()

    let titleLabel = UILabel()
    let subtitleLabelHolderView = UIView()
    let subtitleLabel = UILabel()
    let topSeperator = UIView()
    let bottomSeperator = UIView()

    let album: KZPlayerAlbum

    init(album: KZPlayerAlbum) {
        self.album = album
        super.init(frame: CGRect.zero)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupView() {
        self.backgroundColor = UIColor.clear

        topSeperator.backgroundColor = .white
        topSeperator.alpha = 0.14
        addSubview(topSeperator)

        bottomSeperator.backgroundColor = .black
        bottomSeperator.alpha = 0.14
        addSubview(bottomSeperator)

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = Constants.UI.Color.gray
        addSubview(imageView)

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.numberOfLines = 2
        addSubview(titleLabel)

        subtitleLabel.textColor = .white
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabelHolderView.addSubview(subtitleLabel)

        subtitleLabelHolderView.backgroundColor = RGB(0.2, a: 0.5)
        subtitleLabelHolderView.layer.cornerRadius = 6
        addSubview(subtitleLabelHolderView)

        fillInView()
        setupConstraints()
    }

    func fillInView() {
        if let song = album.songs.first {
            if let artwork = song.fetchArtwork(completionHandler: { artwork in
                self.imageView.image = artwork.image(at: CGSize(width: 115, height: 115))
            }) {
                imageView.image = artwork.image(at: CGSize(width: 115, height: 115))
            }
        }

        titleLabel.text = album.name
        subtitleLabel.text = album.artist?.name
    }

    func setupConstraints() {
        bottomSeperator.autoSetDimension(.height, toSize: (1.0 / UIScreen.main.scale))
        bottomSeperator.autoPinEdge(toSuperviewEdge: .bottom)
        bottomSeperator.autoPinEdge(toSuperviewEdge: .left)
        bottomSeperator.autoPinEdge(toSuperviewEdge: .right)

        imageView.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        imageView.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        imageView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
        imageView.autoSetDimensions(to: CGSize(width: 115, height: 115))

        titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 14)
        titleLabel.autoPinEdge(.left, to: .right, of: imageView, withOffset: 10)
        titleLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 14)

        subtitleLabel.autoPinEdgesToSuperviewEdges(with: .init(top: 3, left: 8, bottom: 3, right: 8))

        subtitleLabelHolderView.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 4)
        subtitleLabelHolderView.autoPinEdge(.left, to: .right, of: imageView, withOffset: 10)
        subtitleLabelHolderView.autoPinEdge(toSuperviewEdge: .right, withInset: 14, relation: .greaterThanOrEqual)
    }

}
