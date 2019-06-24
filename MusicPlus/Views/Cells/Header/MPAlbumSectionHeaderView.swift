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
    let bottomSeparator = UIView()

    let album: KZPlayerAlbum

    init(album: KZPlayerAlbum) {
        self.album = album
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear

        bottomSeparator.backgroundColor = .black
        bottomSeparator.alpha = 0.14
        addSubview(bottomSeparator)

        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = Constants.UI.Color.gray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.numberOfLines = 2

        subtitleLabel.textColor = .white
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabelHolderView.addSubview(subtitleLabel)

        subtitleLabelHolderView.backgroundColor = RGB(0.2, a: 0.5)
        subtitleLabelHolderView.layer.cornerRadius = 6

        setupConstraints()
        let infoStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabelHolderView])
        infoStackView.axis = .vertical
        infoStackView.spacing = CGFloat.goo.systemSpacing
        infoStackView.alignment = .leading

        let stackView = UIStackView(arrangedSubviews: [imageView, infoStackView, UIView()])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .top
        stackView.spacing = CGFloat.goo.systemSpacing(multiplier: 2)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets.goo.systemSpacingInsets(2)

        addSubview(stackView)
        stackView.goo.boundingAnchor.makeRelativeEdgesEqualToSuperview().activate()

        fillInView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func fillInView() {
        if let song = album.songs.first {
            imageView.image = song.fetchArtwork(completionHandler: { artwork in
                self.imageView.image = artwork.image(at: CGSize(width: 115, height: 115))
            })?.image(at: CGSize(width: 115, height: 115))
        }

        titleLabel.text = album.name
        subtitleLabel.text = album.artist?.name
    }

    func setupConstraints() {
        bottomSeparator.autoSetDimension(.height, toSize: (1.0 / UIScreen.main.scale))
        bottomSeparator.autoPinEdge(toSuperviewEdge: .bottom)
        bottomSeparator.autoPinEdge(toSuperviewEdge: .left)
        bottomSeparator.autoPinEdge(toSuperviewEdge: .right)

        imageView.autoSetDimensions(to: CGSize(width: 115, height: 115))

        subtitleLabel.autoPinEdgesToSuperviewEdges(with: .init(top: 3, left: 8, bottom: 3, right: 8))
    }

}
