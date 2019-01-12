// 
//  MPAlbumSectionHeaderView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPAlbumSectionHeaderView: UIView, MPOptionsButtonDelegate {

    let imageView = UIImageView()

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    let heartButton = UIButton.styleForHeart()
    let optionsButton = MPOptionsButton(buttons: [(icon: "", name: "add to up next"), (icon: "", name: "add to playlist"), (icon: "", name: "go to album"), (icon: "", name: "go to artist"), (icon: "", name: "edit metadata")])

    let topSeperator = UIView()
    let bottomSeperator = UIView()

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
        addSubview(titleLabel)

        subtitleLabel.textColor = RGB(255)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        addSubview(subtitleLabel)

        heartButton.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        addSubview(heartButton)

        optionsButton.delegate = self
        addSubview(optionsButton)

        fillInView()
        setupConstraints()
    }

    func fillInView() {
        if let song = album.songs.first {
            song.fetchArtwork { artwork in
                self.imageView.image = artwork.image(at: CGSize(width: 115, height: 115))
            }
        }

        titleLabel.text = album.name
        subtitleLabel.text = album.artist?.name
    }

    func setupConstraints() {
        bottomSeperator.autoSetDimension(.height, toSize: (1.0/UIScreen.main.scale))
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

        subtitleLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 4)
        subtitleLabel.autoPinEdge(.left, to: .right, of: imageView, withOffset: 10)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 14)

        heartButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)
        heartButton.autoPinEdge(toSuperviewEdge: .right, withInset: 80)

        NSLayoutConstraint.autoSetPriority(UILayoutPriority.required) {
            self.heartButton.autoSetContentCompressionResistancePriority(for: .horizontal)
            if let image = self.heartButton.currentImage {
                self.heartButton.autoSetDimensions(to: image.size)
            }
            self.optionsButton.autoSetContentCompressionResistancePriority(for: .horizontal)
        }

        optionsButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 13)
        optionsButton.autoPinEdge(toSuperviewEdge: .right, withInset: 28)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let translatedPoint = optionsButton.convert(point, from: self)

        if optionsButton.bounds.contains(translatedPoint) {
            return optionsButton.hitTest(translatedPoint, with: event)
        }

        return super.hitTest(point, with: event)
    }

    // MARK: Handle Updates

    @objc func toggleLike() {
        let selected = !album.liked
        heartButton.isSelected = selected

        try? album.realm?.write {
            album.liked = heartButton.isSelected
        }
    }

    func optionsButtonWillExpand(_ button: MPOptionsButton) {
        self.superview?.bringSubviewToFront(self)
        self.bringSubviewToFront(button)
    }

    func optionsButtonDidClick(_ button: MPOptionsButton, index: Int) {
        button.toggle()

        if index == 0 {
            // KZPlayer.sharedInstance.addUpNext(item)
        }
    }

    @objc func updateTint() {
        heartButton.tintColor = AppDelegate.del().session.tintColor
    }

}
