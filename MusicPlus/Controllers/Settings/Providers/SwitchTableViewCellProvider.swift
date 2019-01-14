//
//  SwitchTableViewCellProvider.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Flix

class SwitchTableViewCellProvider: BaseTableViewCellProvider {

    let uiSwitch = UISwitch()

    init(title: String, subTitle: String? = nil, icon: UIImage? = nil, isOn: Bool) {
        super.init(title: title, subTitle: subTitle, icon: icon)
        uiSwitch.isOn = isOn
    }

    override func onCreate(_ tableView: UITableView, cell: UITableViewCell, indexPath: IndexPath) {
        super.onCreate(tableView, cell: cell, indexPath: indexPath)
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.backgroundColor = .clear
        cell.contentView.addSubview(uiSwitch)
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        uiSwitch.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16).isActive = true
        uiSwitch.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor).isActive = true
    }

}
