// 
//  MPListedCollectionViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPSectionedTableViewController: KZViewController {

    var sections = [TableSection]()

    var tableView = UITableView(frame: CGRect.zero, style: .grouped)
    let shadowView = UIView()
    let shadowLayer = CAGradientLayer()
    var shadowTopConstraint: NSLayoutConstraint?

    // MARK: Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Collection"
        view.backgroundColor = UIColor.clear
        automaticallyAdjustsScrollViewInsets = false

        setupMenuToggle()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = RGB(255)
        view.addSubview(tableView)

        shadowView.backgroundColor = UIColor.clear
        shadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        shadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        shadowLayer.colors = [RGB(0).cgColor, UIColor.clear.cgColor]
        shadowView.layer.insertSublayer(shadowLayer, at: 0)
        shadowView.alpha = 0.0
        view.addSubview(shadowView)

        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: Constants.Notification.libraryDataDidChange, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        shadowLayer.frame = CGRect(x: 0, y: 0, width: shadowView.frame.size.width, height: 10)
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        tableView.autoPinEdge(toSuperviewEdge: .left)
        tableView.autoPinEdge(toSuperviewEdge: .right)
        tableView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)

        shadowTopConstraint = shadowView.autoPinEdge(.top, to: .top, of: tableView)
        shadowView.autoPinEdge(toSuperviewEdge: .left)
        shadowView.autoPinEdge(toSuperviewEdge: .right)
        shadowView.autoSetDimension(.height, toSize: 21)
    }

    // MARK: Table View Delegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return sections[section].sectionObjects
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].sectionName
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return MPSongTableViewCell.self
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let percent = min(scrollView.contentOffset.y/300.0, 0.3)
        shadowView.alpha = percent
        NotificationCenter.default.post(name: Constants.Notification.hidePopup, object: nil)
    }

    override func tableViewShowsSectionHeader(_ tableView: UITableView) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableViewShowsSectionHeader(tableView), let name = self.tableView(tableView, titleForHeaderInSection: section) {
            return MPSectionHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: 20), name: name)
        }

        return nil
    }

}
