// 
//  MPArtistSectionHeaderView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPArtistSectionHeaderView: UIView {

    let imageView = UIImageView()

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let infoHolder = UIView()

    let heartButton = UIButton.styleForHeart()

    let topSeperator = UIView()
    let bottomSeperator = UIView()

    let toggleButton = ExtendedButton()

    let album: KZPlayerAlbum

    init(album: KZPlayerAlbum) {
        self.album = album
        super.init(frame: CGRect.zero)

        setupView()

        NotificationCenter.default.addObserver(self, selector: #selector(updateTint), name: Constants.Notification.tintColorDidChange, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupView() {
        self.backgroundColor = UIColor.clear

        topSeperator.backgroundColor = RGB(255)
        topSeperator.alpha = 0.14
        addSubview(topSeperator)

        bottomSeperator.backgroundColor = RGB(0)
        bottomSeperator.alpha = 0.14
        addSubview(bottomSeperator)

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = Constants.UI.Color.gray
        addSubview(imageView)

        titleLabel.textColor = RGB(255)
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
        titleLabel.numberOfLines = 2
        infoHolder.addSubview(titleLabel)

        subtitleLabel.textColor = RGB(255)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        infoHolder.addSubview(subtitleLabel)

        addSubview(infoHolder)

        heartButton.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        addSubview(heartButton)

        toggleButton.setImage(#imageLiteral(resourceName: "arrowDown"), for: .normal)
        toggleButton.setImage(#imageLiteral(resourceName: "arrowUp"), for: .selected)
        addSubview(toggleButton)

        fillInView()
        setupConstraints()
    }

    func fillInView() {

        if let song = album.songs.first {
            song.fetchArtwork { artwork in
                self.imageView.image = artwork.image(at: CGSize(width: 70, height: 70))
            }
        }

        titleLabel.text = album.name
        subtitleLabel.text = "\(album.songs.count) tracks / \(album.durationText())"
    }

    func setupConstraints() {
        bottomSeperator.autoSetDimension(.height, toSize: (1.0/UIScreen.main.scale))
        bottomSeperator.autoPinEdge(toSuperviewEdge: .bottom)
        bottomSeperator.autoPinEdge(toSuperviewEdge: .left)
        bottomSeperator.autoPinEdge(toSuperviewEdge: .right)

        topSeperator.autoSetDimension(.height, toSize: (1.0/UIScreen.main.scale))
        topSeperator.autoPinEdge(toSuperviewEdge: .top)
        topSeperator.autoPinEdge(toSuperviewEdge: .left)
        topSeperator.autoPinEdge(toSuperviewEdge: .right)

        imageView.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        imageView.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        imageView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
        imageView.autoSetDimensions(to: CGSize(width: 70, height: 70))

        infoHolder.autoPinEdge(.left, to: .right, of: imageView, withOffset: 10)

        titleLabel.autoPinEdge(toSuperviewEdge: .top)
        titleLabel.autoPinEdge(toSuperviewEdge: .left)
        titleLabel.autoPinEdge(toSuperviewEdge: .right)

        subtitleLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 2)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .left)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .bottom)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .right)

        heartButton.autoPinEdge(.left, to: .right, of: infoHolder, withOffset: 12, relation: .greaterThanOrEqual)
        heartButton.autoAlignAxis(toSuperviewAxis: .horizontal)

        NSLayoutConstraint.autoSetPriority(UILayoutPriority.required) {
            self.infoHolder.autoAlignAxis(toSuperviewAxis: .horizontal)
            self.heartButton.autoSetContentCompressionResistancePriority(for: .horizontal)
            if let image = self.heartButton.currentImage {
                self.heartButton.autoSetDimensions(to: image.size)
            }
        }

        toggleButton.autoPinEdge(.left, to: .right, of: heartButton, withOffset: 18)
        toggleButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        toggleButton.autoPinEdge(toSuperviewEdge: .right, withInset: 17)
    }

    // MARK: Handle Updates

    @objc func toggleLike() {
        let selected = !album.liked
        heartButton.isSelected = selected

        try? album.realm?.write {
            album.liked = heartButton.isSelected
        }
    }

    @objc func updateTint() {
        heartButton.tintColor = AppDelegate.del().session.tintColor
    }

}
