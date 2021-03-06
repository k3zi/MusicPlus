//
//  MPLibraryCell.swift
//  Music+
//
//  Created by kezi on 2018/10/31.
//  Copyright © 2018 Kesi Maduka. All rights reserved.
//

import UIKit

class MPLibraryCell: KZTableViewCell {

    let iconView = UIImageView()
    let label = UILabel()

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.black.withAlphaComponent(0.27)
        topSeparator.backgroundColor = .black
        bottomSeparator.backgroundColor = .black

        selectionStyle = .none
        accessoryType = .none

        iconView.contentMode = .center
        contentView.addSubview(iconView)

        label.textColor = Constants.UI.Color.gray
        label.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.bold)
        label.textAlignment = .left
        contentView.addSubview(label)

        NotificationCenter.default.addObserver(self, selector: #selector(updateTint), name: .tintColorDidChange, object: nil)
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
        height += 16
        height += iconView.estimatedHeight(width)
        height += 16
        return height
    }

    override func fillInCellData(_ shallow: Bool) {
        super.fillInCellData(shallow)

        if let item = model as? MPLibraryItem {
            iconView.image = item.icon
            label.text = item.name
        } else if let item = model as? KZRealmLibrary {
            iconView.image = item.libraryType == .plex ? #imageLiteral(resourceName: "sidebarPlexIcon") : #imageLiteral(resourceName: "serverIItunesIcon")
            label.text = item.name
            let selected = KZPlayer.sharedInstance.currentLibrary?.uniqueIdentifier == item.uniqueIdentifier
            let tintColor = selected ? AppDelegate.del().session.tintColor : Constants.UI.Color.gray
            iconView.tintColor = tintColor
            label.textColor = tintColor
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        topSeparator.alpha = 0.14
        bottomSeparator.alpha = 0.14
    }

    @objc func updateTint() {
        fillInCellData(true)
    }

}
