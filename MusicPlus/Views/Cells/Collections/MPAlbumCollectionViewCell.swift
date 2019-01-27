// 
//  MPAlbumCollectionViewCell.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/17/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit
import Reusable

class MPAlbumCollectionViewCell: UICollectionViewCell, Reusable {

    let imageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let highloightView = UIView()
    var album: KZPlayerAlbum?

    var widthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.backgroundColor = RGB(217)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        imageView.addSubview(highloightView)

        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.medium)
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)

        subtitleLabel.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.light)
        subtitleLabel.textColor = .white
        contentView.addSubview(subtitleLabel)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupConstraints() {
        imageView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
        imageView.autoMatch(.height, to: .width, of: imageView)
        widthConstraint = imageView.autoSetDimension(.width, toSize: 120)

        highloightView.autoPinEdgesToSuperviewEdges()

        titleLabel.autoPinEdge(toSuperviewEdge: .left)
        titleLabel.autoPinEdge(toSuperviewEdge: .right)
        titleLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 8)

        subtitleLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 2)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .left)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .right)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0, relation: .greaterThanOrEqual)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    override var isHighlighted: Bool {
        didSet {
            func runAnimations() {
                highloightView.backgroundColor = isHighlighted ? RGB(255, a: 0.2) : UIColor.clear
            }

            if !isHighlighted {
                UIView.animate(withDuration: Constants.UI.Animation.cellHighlight, animations: runAnimations)
            } else {
                runAnimations()
            }
        }
    }
}
