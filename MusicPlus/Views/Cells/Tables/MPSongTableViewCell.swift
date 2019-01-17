// 
//  MPSongTableViewCell.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPSongTableViewCell: KZTableViewCell {

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    let heartButton = UIButton.styleForHeart()

    var indexPath: IndexPath?

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        bottomSeperator.backgroundColor = .black

        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        contentView.addSubview(titleLabel)

        subtitleLabel.textColor = .white
        subtitleLabel.font = UIFont.systemFont(ofSize: 9, weight: UIFont.Weight.light)
        contentView.addSubview(subtitleLabel)

        heartButton.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        contentView.addSubview(heartButton)

        NotificationCenter.default.addObserver(self, selector: #selector(updateTint), name: Constants.Notification.tintColorDidChange, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func updateConstraints() {
        super.updateConstraints()

        titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        titleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

        subtitleLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 2)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)

        heartButton.autoPinEdge(.left, to: .right, of: titleLabel, withOffset: 12, relation: .greaterThanOrEqual)
        heartButton.autoPinEdge(.left, to: .right, of: subtitleLabel, withOffset: 12, relation: .greaterThanOrEqual)
        heartButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        heartButton.autoPinEdge(toSuperviewEdge: .right, withInset: 18)

        NSLayoutConstraint.autoSetPriority(UILayoutPriority.required) {
            self.heartButton.autoSetContentCompressionResistancePriority(for: .horizontal)
            if let image = self.heartButton.currentImage {
                self.heartButton.autoSetDimensions(to: image.size)
            }
        }
    }

    override func estimatedHeight() -> CGFloat {
        let width = Constants.UI.Navigation.menuWidth

        var height = CGFloat(0)
        height = height + 10
        height = height + titleLabel.estimatedHeight(width)
        height = height + 5
        height = height + subtitleLabel.estimatedHeight(width)
        height = height + 10
        return height
    }

    override func fillInCellData(_ shallow: Bool) {
        super.fillInCellData(shallow)

        guard let item = (model as? KZPlayerItem) ?? (model as? KZThreadSafeReference<KZPlayerItem>)?.resolve() else {
            return
        }

        titleLabel.text = item.titleText()
        subtitleLabel.text = item.subtitleText()
        heartButton.isSelected = item.liked
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        if indexPath.row != 0 {
            bottomSeperator.alpha = 0.14
        }

        self.indexPath = indexPath
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        func runAnimations() {
            backgroundColor = highlighted ? RGB(255, a: 0.2) : UIColor.clear
            bottomSeperator.alpha = highlighted ? 0.0 : 0.14
        }

        if animated {
            UIView.animate(withDuration: Constants.UI.Animation.cellHighlight, animations: runAnimations)
        } else {
            runAnimations()
        }
    }

    // MARK: Handle Updates

    @objc func toggleLike() {
        guard let item = model as? KZPlayerItem else {
            return
        }

        let selected = !item.liked
        heartButton.isSelected = selected

        try? item.realm?.write {
            item.liked = heartButton.isSelected
        }
    }

    @objc func updateTint() {
        heartButton.tintColor = AppDelegate.del().session.tintColor
    }

}
