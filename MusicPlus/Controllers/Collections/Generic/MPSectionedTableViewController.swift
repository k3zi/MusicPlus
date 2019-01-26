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

    var tableView = UITableView(frame: .zero, style: .grouped)
    let shadowView = UIView()
    let shadowLayer = CAGradientLayer()
    var shadowTopConstraint: NSLayoutConstraint?
    var topLayoutGuideConstraint: NSLayoutConstraint?

    // MARK: Setup View

    override func viewDidLoad() {
        fetchAUtomatically = false
        super.viewDidLoad()

        title = "Collection"
        view.backgroundColor = .clear

        setupMenuToggle()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = .white
        tableView.tableHeaderView = UIView.init(frame: .init(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.contentInsetAdjustmentBehavior = .always
        view.addSubview(tableView)

        shadowView.backgroundColor = .clear
        shadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        shadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        shadowLayer.colors = [RGB(0).cgColor, UIColor.clear.cgColor]
        shadowView.layer.insertSublayer(shadowLayer, at: 0)
        shadowView.alpha = 0.0
        view.addSubview(shadowView)

        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: .libraryDataDidChange, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        shadowLayer.frame = CGRect(x: 0, y: 0, width: shadowView.frame.size.width, height: 10)

        topLayoutGuideConstraint?.autoRemove()
        topLayoutGuideConstraint = tableView.autoPinEdge(toSuperviewEdge: .top, withInset: view.safeAreaInsets.top)
    }

    override func setupConstraints() {
        super.setupConstraints()

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

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let targetNumber = 30
        var result = [(title: String, numberOfItems: Int, originalIndex: Int)]()
        for i in 0 ..< numberOfSections(in: tableView) {
            if let s = self.tableView(tableView, titleForHeaderInSection: i) {
                result.append((title: s, numberOfItems: self.tableViewCellData(tableView, section: i).count, originalIndex: i))
            }
        }

        let numberToRemove = result.count - targetNumber
        if numberToRemove > 0 {
            // targetNumber is way greater than 2 so the array will have 2 elements to remove
            let first = result.removeFirst()
            let last = result.removeLast()
            result.sort { $0.numberOfItems > $1.numberOfItems }
            result.removeLast(numberToRemove)
            result.sort { $0.originalIndex < $1.originalIndex }
            result.insert(first, at: 0)
            result.append(last)
        }

        return result.map { $0.title }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return sections.firstIndex { $0.sectionName == title }!
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return MPSongTableViewCell.self
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        shadowView.alpha = min(scrollView.contentOffset.y / 300.0, 0.3)
    }

    override func tableViewShowsSectionHeader(_ tableView: UITableView) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableViewCellClass(tableView, indexPath: indexPath) == MPSongTableViewCell.self {
            return 56 + 1 / 3
        }

        return super.tableView(tableView, estimatedHeightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableViewShowsSectionHeader(tableView), let name = self.tableView(tableView, titleForHeaderInSection: section) {
            return MPSectionHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: 20), name: name)
        }

        return nil
    }

}
