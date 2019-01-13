//
//  MPLibraryCell.swift
//  Music+
//
//  Created by kezi on 2018/10/31.
//  Copyright © 2018 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class MPLibraryCell: KZTableViewCell {

    let iconView = UIImageView()
    let label = UILabel()

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.black.withAlphaComponent(0.27)
        topSeperator.backgroundColor = RGB(0)
        bottomSeperator.backgroundColor = RGB(0)

        selectionStyle = .none
        accessoryType = .none

        iconView.contentMode = .center
        contentView.addSubview(iconView)

        label.textColor = Constants.UI.Color.gray
        label.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.bold)
        label.textAlignment = .left
        contentView.addSubview(label)

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

        iconView.autoPinEdgesToSuperviewEdges(with: .init(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right)
        NSLayoutConstraint.autoSetPriority(UILayoutPriority.required) {
            self.iconView.autoSetContentHuggingPriority(for: .horizontal)
        }
        label.autoPinEdge(.left, to: .right, of: iconView, withOffset: 8)
        label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 16), excludingEdge: .left)
    }

    override func estimatedHeight() -> CGFloat {
        let width = UIScreen.main.bounds.width - Constants.UI.Navigation.menuWidth

        var height = CGFloat(0)
        height = height + 16
        height = height + iconView.estimatedHeight(width)
        height = height + 16
        return height
    }

    override func fillInCellData(_ shallow: Bool) {
        super.fillInCellData(shallow)

        if let item = model as? MPLibraryItem {
            iconView.image = item.icon
            label.text = item.name
        } else if let item = model as? KZLibrary {
            iconView.image = item is KZPlexLibrary ? #imageLiteral(resourceName: "sidebarPlexIcon") : #imageLiteral(resourceName: "serverIItunesIcon")
            label.text = item.name
            let selected = KZPlayer.sharedInstance.currentLibrary == item
            let tintColor = selected ? AppDelegate.del().session.tintColor : Constants.UI.Color.gray
            iconView.tintColor = tintColor
            label.textColor = tintColor
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        topSeperator.alpha = 0.14
        bottomSeperator.alpha = 0.14
    }

    @objc func updateTint() {
        setSelected(isSelected, animated: false)
    }

}
