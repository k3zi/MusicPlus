// 
//  MPSongTableViewCell.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPArtistTableViewCell: KZTableViewCell, MPOptionsButtonDelegate {

    let titleLabel = UILabel()
    let optionsButton = MPOptionsButton(buttons: [(icon: "", name: "add to up next"), (icon: "", name: "add to playlist"), (icon: "", name: "edit metadata")])

    var indexPath: IndexPath?

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        bottomSeperator.backgroundColor = RGB(0)

        titleLabel.textColor = RGB(255)
        titleLabel.font = .systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        contentView.addSubview(titleLabel)

        optionsButton.delegate = self
        contentView.addSubview(optionsButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 17)
        titleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        titleLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 17)
        titleLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 50)

        NSLayoutConstraint.autoSetPriority(UILayoutPriority.required) {
            self.optionsButton.autoSetContentCompressionResistancePriority(for: .horizontal)
        }

        optionsButton.autoPinEdge(toSuperviewEdge: .top, withInset: 13)
        optionsButton.autoPinEdge(toSuperviewEdge: .right, withInset: 0)
    }

    override func estimatedHeight() -> CGFloat {
        let width = Constants.UI.Navigation.menuWidth

        var height = CGFloat(0)
        height = height + 10
        height = height + titleLabel.estimatedHeight(width)
        height = height + 10
        return height
    }

    override func fillInCellData(_ shallow: Bool) {
        super.fillInCellData(shallow)

        guard let item = model as? KZPlayerArtist else {
            return
        }

        titleLabel.text = item.name
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        if indexPath.row != 0 {
            bottomSeperator.alpha = 0.14
        }

        self.indexPath = indexPath
    }

    override func hitTest(_ point: CGPoint, with witht: UIEvent?) -> UIView? {
        let translatedPoint = optionsButton.convert(point, from: self)

        if (optionsButton.bounds).contains(translatedPoint) {
            return optionsButton.hitTest(translatedPoint, with: witht)
        }

        return super.hitTest(point, with: witht)
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

    // MARK: Handle Updates

    func optionsButtonWillExpand(_ button: MPOptionsButton) {
        self.superview?.bringSubviewToFront(self)
        self.bringSubviewToFront(button)
    }

    func optionsButtonDidClick(_ button: MPOptionsButton, index: Int) {
        button.toggle()
        guard let item = model as? KZPlayerItem ?? (model as? KZThreadSafeReference<KZPlayerItem>)?.resolve() else {
            return
        }

        if index == 0 {
            KZPlayer.sharedInstance.addUpNext(item)
        }
    }

}
