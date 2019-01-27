//
//  TitleTableViewSectionProvider.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/20.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import Flix

class TitleTableViewSectionProvider: BaseTableViewCellProvider {

    let headerView: MPSectionHeaderView

    init(name: String) {
        headerView = MPSectionHeaderView(frame: .init(x: 0, y: 0, width: 0, height: 20), name: name)
        headerView.label.textAlignment = .center
        super.init(title: "", subTitle: "", icon: nil)
    }

    override func onCreate(_ tableView: UITableView, cell: UITableViewCell, indexPath: IndexPath) {
        super.onCreate(tableView, cell: cell, indexPath: indexPath)
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.translatesAutoresizingMaskIntoConstraints = false

        headerView.translatesAutoresizingMaskIntoConstraints = false

        contentView.backgroundColor = .clear
        contentView.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        headerView.autoSetDimension(.height, toSize: 20)
    }

}
