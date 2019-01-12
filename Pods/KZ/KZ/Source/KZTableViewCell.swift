//
//  KZTableViewCell.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import PureLayout
import Reusable

open class KZTableViewCell: UITableViewCell, Reusable {
    public let topSeperator = UIView()
    public let bottomSeperator = UIView()

    var didSetupConstraints = false
    var trailingDetailConstraint = NSLayoutConstraint()
    open var model: Any?

    override required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear

        self.contentView.addSubview(topSeperator)
        self.contentView.addSubview(bottomSeperator)

        self.contentView.bounds.size.height = 99999
    }

    //MARK: Setup Constraints
    override open func updateConstraints() {
        super.updateConstraints()
        if didSetupConstraints {
            return
        }

        bottomSeperator.autoSetDimension(.height, toSize: (1.0/UIScreen.main.scale))
        bottomSeperator.autoPinEdge(toSuperviewEdge: .bottom)
        bottomSeperator.autoPinEdge(toSuperviewEdge: .left)
        bottomSeperator.autoPinEdge(toSuperviewEdge: .right)

        topSeperator.autoSetDimension(.height, toSize: (1.0/UIScreen.main.scale))
        topSeperator.autoPinEdge(toSuperviewEdge: .top)
        topSeperator.autoPinEdge(toSuperviewEdge: .left)
        topSeperator.autoPinEdge(toSuperviewEdge: .right)

        didSetupConstraints = true
    }

    open func usesEstimatedHeight() -> Bool {
        return true
    }

    open func estimatedHeight() -> CGFloat {
        if usesEstimatedHeight() {
            print("AutoLayout: \"\(type(of: self))\" estimatedHeight isn't implemented")
        }

        return UITableView.automaticDimension
    }

    func heightForRow() -> CGFloat {
        if self.usesEstimatedHeight() {
            return UITableView.automaticDimension
        } else {
            return self.getHeight()
        }
    }

    open func getHeight() -> CGFloat {
        self.contentView.bounds.size.height = 99999
        self.setNeedsUpdateConstraints()
        self.updateConstraints()

        self.bounds.size.width = UIScreen.main.bounds.size.width

        self.setNeedsLayout()
        self.layoutIfNeeded()

        let height = self.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        return height + CGFloat(1.0)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.layoutIfNeeded()
    }

    open func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        if (indexPath as NSIndexPath).row == 0 {
            topSeperator.alpha = 0.0
        } else {
            topSeperator.alpha = 1.0
        }
    }

    open func setContent(_ content: Any, shallow: Bool) {
        model = content

        fillInCellData(shallow)
    }

    open func fillInCellData(_ shallow: Bool) {

    }

    override open func prepareForReuse() {
        super.prepareForReuse()

        model = nil
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
