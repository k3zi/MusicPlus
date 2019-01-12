// 
//  MPMenuItemTableViewCell.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/12/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPMenuItemTableViewCell: KZTableViewCell {

    let iconView = UIImageView()
    let label = UILabel()

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        iconView.contentMode = .center
        contentView.addSubview(iconView)

        label.textColor = Constants.UI.Color.gray
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.bold)
        label.textAlignment = .center
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

        iconView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0), excludingEdge: .bottom)

        label.autoPinEdge(.top, to: .bottom, of: iconView, withOffset: 8)
        label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0), excludingEdge: .top)
    }

    override func estimatedHeight() -> CGFloat {
        let width = Constants.UI.Navigation.menuWidth

        var height = CGFloat(0)
        height = height + 16
        height = height + iconView.estimatedHeight(width)
        height = height + 16
        height = height + label.estimatedHeight(width)
        height = height + 16
        return height
    }

    override func fillInCellData(_ shallow: Bool) {
        super.fillInCellData(shallow)

        guard let item = model as? MPMenuItem else {
            return
        }

        iconView.image = item.icon
        label.text = item.name
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        let tintColor = selected ? AppDelegate.del().session.tintColor : Constants.UI.Color.gray
        iconView.tintColor = tintColor
        label.textColor = tintColor
    }

    @objc func updateTint() {
        setSelected(isSelected, animated: false)
    }

}
