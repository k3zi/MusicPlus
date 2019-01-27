//
//  BaseTableViewCellProvider.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import Flix

class BaseTableViewCellProvider: SingleUITableViewCellProvider {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .white
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = RGB(255, a: 0.5)
        label.numberOfLines = 0
        return label
    }()

    lazy var iconImageView = UIImageView()

    private let leftStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.alignment = .center
        return stackView
    }()

    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.alignment = UIStackView.Alignment.leading
        return stackView
    }()

    init(title: String, subTitle: String?, icon: UIImage? = nil) {
        super.init()
        if let icon = icon {
            iconImageView.image = icon
            leftStackView.addArrangedSubview(iconImageView)
        }

        leftStackView.addArrangedSubview(titleStackView)
        titleLabel.text = title
        titleStackView.addArrangedSubview(titleLabel)

        if let subTitle = subTitle {
            subTitleLabel.text = subTitle
            titleStackView.addArrangedSubview(subTitleLabel)
        }

        separatorInset = UIEdgeInsets(top: 0, left: iconImageView.image == nil ? 16 : 59, bottom: 0, right: 0)
        contentView.addSubview(leftStackView)
        leftStackView.translatesAutoresizingMaskIntoConstraints = false
        leftStackView.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
        leftStackView.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
        leftStackView.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
        leftStackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16)
    }

    override func onCreate(_ tableView: UITableView, cell: UITableViewCell, indexPath: IndexPath) {
        super.onCreate(tableView, cell: cell, indexPath: indexPath)
        cell.backgroundColor = .clear
    }

    func itemSelected(_ tableView: UITableView, indexPath: IndexPath, value: BaseTableViewCellProvider) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
