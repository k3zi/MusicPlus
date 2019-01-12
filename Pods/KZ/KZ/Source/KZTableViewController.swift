//
//  KZTableViewController.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

open class KZTableViewController: KZViewController {

    open var tableView: UITableView? = nil
    open var items = [Any]()
    open var createTable = true

    //MARK: Setup View

    public convenience init(createTable: Bool) {
        self.init()
        self.createTable = createTable
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        if createTable {
            tableView = UITableView(frame: view.bounds, style: .grouped)
            tableView!.delegate = self
            tableView!.dataSource = self
            tableView?.separatorStyle = .none
            tableView?.showsVerticalScrollIndicator = false
            tableView?.sectionIndexBackgroundColor = RGB(224)
            tableView?.sectionIndexColor = RGB(103)
            view.addSubview(tableView!)
        }
    }

    override open func setupConstraints() {
        super.setupConstraints()

        if createTable {
            tableView!.autoPin(toTopLayoutGuideOf: self, withInset: 0.0)
            tableView!.autoPinEdge(toSuperviewEdge: .left)
            tableView!.autoPinEdge(toSuperviewEdge: .right)
            tableView!.autoPinEdge(toSuperviewEdge: .bottom)
        }
    }

    open override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return items
    }
}

public struct TableSection {
    public var sectionName: String
    public var sectionObjects: [Any]

    public init(sectionName: String, sectionObjects: [Any]) {
        self.sectionName = sectionName
        self.sectionObjects = sectionObjects
    }
}
