// 
//  MPShuffleTableViewCell.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPShuffleTableViewCell: KZTableViewCell {

    let label = UILabel()
    let shuffleImage = UIImageView(image: #imageLiteral(resourceName: "shuffleBT"))

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        bottomSeperator.backgroundColor = .black

        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        label.text = "Shuffle All"
        contentView.addSubview(label)

        shuffleImage.alpha = 0.4
        contentView.addSubview(shuffleImage)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func updateConstraints() {
        super.updateConstraints()

        label.autoPinEdge(toSuperviewEdge: .left, withInset: 17)
        label.autoPinEdge(toSuperviewEdge: .top, withInset: 15)
        label.autoPinEdge(toSuperviewEdge: .bottom, withInset: 15)

        shuffleImage.autoPinEdge(toSuperviewEdge: .right, withInset: 17)
        shuffleImage.autoAlignAxis(toSuperviewAxis: .horizontal)
    }

    override func estimatedHeight() -> CGFloat {
        let width = Constants.UI.Screen.width

        var height = CGFloat(0)
        height = height + 15
        height = height + label.estimatedHeight(width)
        height = height + 15
        return height
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        if indexPath.row != 0 {
            bottomSeperator.alpha = 0.14
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        func runAnimations() {
            backgroundColor = highlighted ? RGB(255, a: 0.2) : UIColor.clear
            bottomSeperator.alpha = highlighted ? 0.0 : 0.14
        }

        if !highlighted {
            UIView.animate(withDuration: Constants.UI.Animation.cellHighlight, animations: runAnimations)
        } else {
            runAnimations()
        }
    }

}
