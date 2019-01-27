//
//  DescriptionTableViewCellProvider.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import Flix
import RxSwift

class DescriptionTableViewCellProvider: BaseTableViewCellProvider {

    let disposeBag = DisposeBag()
    let onClick: () -> Void

    init(title: String, subTitle: String? = nil, icon: UIImage?, onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init(title: title, subTitle: subTitle, icon: icon)
    }

    override func onCreate(_ tableView: UITableView, cell: UITableViewCell, indexPath: IndexPath) {
        super.onCreate(tableView, cell: cell, indexPath: indexPath)
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator

        tableView.rx.itemSelected.bind { selectedIndexPath in
            guard selectedIndexPath == indexPath else {
                return
            }

            UIView.animate(withDuration: Constants.UI.Animation.cellHighlight) {
                cell.backgroundColor = RGB(255, a: 0.2)
            }

            UIView.animate(withDuration: Constants.UI.Animation.cellHighlight, delay: Constants.UI.Animation.cellHighlight, options: [], animations: {
                cell.backgroundColor = .clear
            }, completion: nil)

            self.onClick()
        }.disposed(by: disposeBag)

        tableView.rx.itemDeselected.bind { selectedIndexPath in
            guard selectedIndexPath == indexPath else {
                return
            }

            UIView.animate(withDuration: Constants.UI.Animation.cellHighlight) {
                cell.backgroundColor = .clear
            }
        }.disposed(by: disposeBag)
    }

}
