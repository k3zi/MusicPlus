// 
//  MPAlbumSongTableViewCell.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class MPAlbumSongTableViewCell: KZTableViewCell {

    let trackNumberLabel = UILabel()
    let titleLabel = UILabel()

    var indexPath: IndexPath?

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        topSeparator.backgroundColor = .black
        bottomSeparator.backgroundColor = .black

        trackNumberLabel.textColor = .init(white: 1, alpha: 0.5)
        trackNumberLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        contentView.addSubview(trackNumberLabel)

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        contentView.addSubview(titleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func updateConstraints() {
        super.updateConstraints()

        trackNumberLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 15)
        trackNumberLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        trackNumberLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 15)

        titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 15)
        titleLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 15)
        titleLabel.autoPinEdge(.left, to: .right, of: trackNumberLabel, withOffset: 15)
        titleLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 18, relation: .greaterThanOrEqual)
    }

    override func estimatedHeight() -> CGFloat {
        let width = Constants.UI.Navigation.menuWidth

        var height = CGFloat(0)
        height += 15
        height += titleLabel.estimatedHeight(width)
        height += 15
        return height
    }

    override func fillInCellData(_ shallow: Bool) {
        super.fillInCellData(shallow)

        guard let item = model as? KZPlayerItem else {
            return
        }

        trackNumberLabel.text = item.trackNum > 0 ? String(item.trackNum) : "-"

        titleLabel.text = item.titleText()
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        topSeparator.alpha = 0.14
        bottomSeparator.alpha = 0.14

        self.indexPath = indexPath
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        func runAnimations() {
            backgroundColor = highlighted ? RGB(255, a: 0.2) : UIColor.clear
            bottomSeparator.alpha = highlighted ? 0.0 : 0.14
        }

        if !highlighted {
            UIView.animate(withDuration: Constants.UI.Animation.cellHighlight, animations: runAnimations)
        } else {
            runAnimations()
        }
    }

}
