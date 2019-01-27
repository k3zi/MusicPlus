// 
//  MPSongTableViewCell.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
//

fileprivate extension CGFloat {

    static let horizontalPadding: CGFloat = 18
    static let verticalPadding: CGFloat = 10
    static let verticalSpacing: CGFloat = 2

}

import UIKit

class MPSongTableViewCell: KZTableViewCell {

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func updateConstraints() {
        super.updateConstraints()

        titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: .verticalPadding)
        titleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: .horizontalPadding)

        subtitleLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: CGFloat.verticalSpacing)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: .horizontalPadding)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: .verticalPadding)
        subtitleLabel.autoPinEdge(toSuperviewEdge: .right, withInset: .horizontalPadding)
    }

    override func estimatedHeight() -> CGFloat {
        let width = Constants.UI.Navigation.menuWidth

        var height = CGFloat(0)
        height = height + CGFloat.verticalPadding
        height = height + titleLabel.estimatedHeight(width)
        height = height + CGFloat.verticalSpacing
        height = height + subtitleLabel.estimatedHeight(width)
        height = height + CGFloat.verticalPadding
        return height
    }

    override func fillInCellData(_ shallow: Bool) {
        super.fillInCellData(shallow)

        guard let item = (model as? KZPlayerItem) ?? (model as? KZThreadSafeReference<KZPlayerItem>)?.resolve() else {
            return
        }

        titleLabel.text = item.titleText()
        subtitleLabel.text = item.subtitleText()
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

}
