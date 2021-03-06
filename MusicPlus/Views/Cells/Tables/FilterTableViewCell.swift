//
//  FilterTableViewCell.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/27.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import RxSwift

class FilterTableViewCell: KZTableViewCell, UITextFieldDelegate {

    let removeButton = UIButton()
    let label = UILabel()

    let valueField = UITextField(frame: .zero)
    let valueFieldHolderView = UIView()

    let disposeBag = DisposeBag()

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.black.withAlphaComponent(0.27)
        topSeparator.backgroundColor = .black
        bottomSeparator.backgroundColor = .black

        selectionStyle = .none
        accessoryType = .none

        removeButton.setImage(#imageLiteral(resourceName: "removeButton"), for: .normal)
        removeButton.tintColor = .white
        contentView.addSubview(removeButton)

        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.bold)
        label.textAlignment = .left
        contentView.addSubview(label)

        valueFieldHolderView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        valueFieldHolderView.layer.cornerRadius = 4
        contentView.addSubview(valueFieldHolderView)

        valueField.textColor = .white
        valueField.backgroundColor = .clear
        valueField.textAlignment = .right
        valueField.placeholder = "Value"
        valueField.delegate = self
        valueFieldHolderView.addSubview(valueField)

        valueField.rx.controlEvent([.editingChanged]).asObservable().subscribe { [weak self] _ in
            (self?.model as? FilterItem)?.value = self?.valueField.text ?? ""
        }.disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func updateConstraints() {
        super.updateConstraints()
        removeButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right)
        removeButton.autoMatch(.width, to: .height, of: removeButton)

        label.autoPinEdge(.left, to: .right, of: removeButton, withOffset: 16)
        label.autoAlignAxis(toSuperviewAxis: .horizontal)

        valueFieldHolderView.autoPinEdge(.left, to: .right, of: label, withOffset: 16, relation: .greaterThanOrEqual)
        valueFieldHolderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 8), excludingEdge: .left)

        valueField.autoPinEdgesToSuperviewEdges(with: .init(top: 0, left: 5, bottom: 0, right: 5))
    }

    override func estimatedHeight() -> CGFloat {
        let width = UIScreen.main.bounds.width - Constants.UI.Navigation.menuWidth

        var height = CGFloat(0)
        height += 16
        height += removeButton.estimatedHeight(width)
        height += 16
        return height
    }

    override func fillInCellData(_ shallow: Bool) {
        super.fillInCellData(shallow)

        if let item = model as? FilterItem {
            let title = NSMutableAttributedString(string: item.property.displayName, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
            title.append(NSAttributedString(string: " "))
            title.append(NSAttributedString(string: item.comparison.displayName, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]))
            title.append(NSAttributedString(string: ":"))
            label.attributedText = title
        }
    }

    override func setIndexPath(_ indexPath: IndexPath, last: Bool) {
        topSeparator.alpha = 0.14
        bottomSeparator.alpha = 0.14
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
