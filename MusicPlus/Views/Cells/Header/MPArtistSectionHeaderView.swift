// 
//  MPArtistSectionHeaderView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class MPArtistSectionHeaderView: UIView {

    let imageView = UIImageView()

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let infoHolder = UIView()

    let topSeparator = UIView()
    let bottomSeparator = UIView()

    let toggleButton = ExtendedButton()

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

        topSeparator.backgroundColor = .white
        topSeparator.alpha = 0.14
        addSubview(topSeparator)

        bottomSeparator.backgroundColor = .black
        bottomSeparator.alpha = 0.14
        addSubview(bottomSeparator)

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = Constants.UI.Color.gray
        addSubview(imageView)

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
        titleLabel.numberOfLines = 2
        infoHolder.addSubview(titleLabel)

        subtitleLabel.textColor = .white
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        infoHolder.addSubview(subtitleLabel)

        addSubview(infoHolder)

        toggleButton.setImage(Images.chevronDown, for: .normal)
        toggleButton.setImage(Images.chevronUp, for: .selected)
        toggleButton.tintColor = Colors.artistAlbumToggleButton
        addSubview(toggleButton)

        fillInView()
        setupConstraints()
    }

    func fillInView() {

        if let song = album.songs.first {
            imageView.setImage(with: song)
        }

        titleLabel.text = album.name
        subtitleLabel.text = "\(album.songs.count) tracks / \(album.durationText())"
    }

    func setupConstraints() {
        bottomSeparator.autoSetDimension(.height, toSize: (1.0/UIScreen.main.scale))
        bottomSeparator.autoPinEdge(toSuperviewEdge: .bottom)
        bottomSeparator.autoPinEdge(toSuperviewEdge: .left)
        bottomSeparator.autoPinEdge(toSuperviewEdge: .right)

        topSeparator.autoSetDimension(.height, toSize: (1.0/UIScreen.main.scale))
        topSeparator.autoPinEdge(toSuperviewEdge: .top)
        topSeparator.autoPinEdge(toSuperviewEdge: .left)
        topSeparator.autoPinEdge(toSuperviewEdge: .right)

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

        NSLayoutConstraint.autoSetPriority(UILayoutPriority.required) {
            self.infoHolder.autoAlignAxis(toSuperviewAxis: .horizontal)
        }

        toggleButton.autoPinEdge(.left, to: .right, of: infoHolder, withOffset: 18, relation: .greaterThanOrEqual)
        toggleButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        toggleButton.autoPinEdge(toSuperviewEdge: .right, withInset: 17)
    }

}
