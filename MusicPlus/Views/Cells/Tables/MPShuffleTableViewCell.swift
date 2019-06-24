// 
//  MPShuffleTableViewCell.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class MPShuffleTableViewCell: KZTableViewCell {

    let label = UILabel()
    let shuffleImage = UIImageView(image: Images.shuffle)

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        bottomSeparator.backgroundColor = .black

        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        label.text = Strings.Buttons.shuffleAll

        shuffleImage.translatesAutoresizingMaskIntoConstraints = false
        shuffleImage.tintColor = Colors.shuffleButton
        shuffleImage.contentMode = .scaleAspectFit
        shuffleImage.setContentHuggingPriority(.required, for: .horizontal)

        let stackView = UIStackView(arrangedSubviews: [label, UIView(), shuffleImage])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets.goo.systemSpacingInsets(2)
        contentView.addSubview(stackView)
        NSLayoutConstraint.goo.activate([
            stackView.goo.boundingAnchor.makeRelativeEdgesEqualToSuperview(),
            shuffleImage.heightAnchor.constraint(equalToConstant: CGFloat.goo.touchTargetDimension / 2),
            shuffleImage.widthAnchor.constraint(equalTo: shuffleImage.heightAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        if indexPath.row != 0 {
            bottomSeparator.alpha = 0.14
        }
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
