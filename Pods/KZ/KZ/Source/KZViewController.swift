//
//  KZViewController.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
import Reusable

open class KZViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var didSetConstraints = false
    open var isReady = false
    open var fetchAUtomatically = true
    open var fetchOnLoad = true
    open var didPresentVC = false
    open var reloadInbackground = false

    var offscreenCells = [String: KZTableViewCell]()
    open var showsNoText = true

    var timer: Timer?

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        self.automaticallyAdjustsScrollViewInsets = false
        if fetchOnLoad && !fetchAUtomatically {
            self.fetchData()
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.setNeedsUpdateConstraints()

        didPresentVC = false
        startTimer()

    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startTimer()
    }

    func startTimer() {
        if timer == nil && fetchAUtomatically {
            timer = Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(KZViewController.fetchData), userInfo: nil, repeats: true)
            timer?.fire()
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if timer != nil && !reloadInbackground {
            timer?.invalidate()
            timer = nil
        }
    }

    override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        super.present(viewControllerToPresent, animated: flag, completion: completion)
        didPresentVC = true
    }

    override open func updateViewConstraints() {
        if !didSetConstraints {
            setupConstraints()
            didSetConstraints = true
        }

        super.updateViewConstraints()
    }

    /**
     Setup any constraints in here
     */
    open func setupConstraints() {

    }

    /**
     Make calls to the network here. NOTICE: By default this is called every 15 seconds
     */
    @objc open dynamic func fetchData() {

    }

    deinit {
        print("\(type(of: self))")
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }


    //MARK: TableView Datasource/Delegate

    /**
     Override to specify a cell class for each row

     - parameter tableView: The table that is requesting a cell's class.
     - parameter indexPath: The indexPath the tableView needs the class for.

     - returns: The class to be used for the tableView at the specified indexPath
     */
    open func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath? = nil) -> KZTableViewCell.Type {
        return KZTableViewCell.self
    }

    /**
     Override to specify the data for each section

     - parameter tableView: The table that is requesting a section's data
     - parameter section:   The section the tableView needs data for

     - returns: The data to be used for the tableView with the specified section
     */
    open func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return []
    }

    /**
     Override to change the text when there is no data

     - parameter tableView: The empty tableView that is requesting text to dipslay

     - returns: The text to be displayed for the empty tableView
     */
    open func tableViewNoDataText(_ tableView: UITableView) -> String {
        return "No Results Found"
    }

    /**
     Override to show a section header

     - parameter tableView: The tableView that is asking whether to show the section header

     - returns: True/False for if the section header should be displayed
     */
    open func tableViewShowsSectionHeader(_ tableView: UITableView) -> Bool {
        return false
    }

    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.tableViewCellData(tableView, section: section).count == 0 && showsNoText {
            return 1
        }

        return self.tableViewCellData(tableView, section: section).count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.tableViewCellData(tableView, section: (indexPath as NSIndexPath).section).count == 0 && showsNoText {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "NoneFound")
            cell.backgroundColor = UIColor.clear
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = tableViewNoDataText(tableView)
            if #available(iOS 8.2, *) {
                cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.light)
            } else {
                cell.textLabel?.font = UIFont.systemFont(ofSize: 20)
            }
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor.gray
            cell.selectionStyle = .none
            return cell
        }

        let cellClass = tableViewCellClass(tableView, indexPath: indexPath)

        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: cellClass)
        cell.setIndexPath(indexPath, last: indexPath.row == (self.tableView(tableView, numberOfRowsInSection: indexPath.section) - 1))
        if tableViewCellData(tableView, section: indexPath.section).count > indexPath.row && cell.tag != -1 {
            cell.setContent(tableViewCellData(tableView, section: indexPath.section)[indexPath.row], shallow: false)
        }

        cell.frame.size.width = tableView.frame.width
        cell.updateConstraintsIfNeeded()
        cell.layoutIfNeeded()

        return cell
    }

    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.tableViewCellData(tableView, section: (indexPath as NSIndexPath).section).count == 0 && showsNoText {
            return tableView.frame.height
        }

        var cell: KZTableViewCell? = offscreenCells[String(describing: tableViewCellClass(tableView, indexPath: indexPath))]
        if cell == nil {
            cell = tableViewCellClass(tableView, indexPath: indexPath).init(style: .default, reuseIdentifier: String(tableView.tag))
            offscreenCells.updateValue(cell!, forKey: String(describing: tableViewCellClass(tableView, indexPath: indexPath)))
        }

        guard let tableCell = cell else {
            return 0
        }

        tableCell.setIndexPath(indexPath, last: ((indexPath as NSIndexPath).row + 1) == tableViewCellData(tableView, section: (indexPath as NSIndexPath).section).count)
        if tableCell.tag != -1 && tableViewCellData(tableView, section: (indexPath as NSIndexPath).section).count > (indexPath as NSIndexPath).row {
            tableCell.setContent(tableViewCellData(tableView, section: (indexPath as NSIndexPath).section)[(indexPath as NSIndexPath).row], shallow: true)
        }

        return tableCell.estimatedHeight()
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableViewCellData(tableView, section: (indexPath as NSIndexPath).section).count == 0 {
            if tableView.frame.size.height > 0 {
                return tableView.frame.size.height
            }

            return 100
        }

        var cell = offscreenCells[String(describing: tableViewCellClass(tableView, indexPath: indexPath))]
        if cell == nil {
            cell = tableViewCellClass(tableView, indexPath: indexPath).init(style: .default, reuseIdentifier: String(tableView.tag))
            offscreenCells.updateValue(cell!, forKey: String(describing: tableViewCellClass(tableView, indexPath: indexPath)))
        }

        guard let tableCell = cell else {
            return 0
        }

        tableCell.setIndexPath(indexPath, last: ((indexPath as NSIndexPath).row + 1) == tableViewCellData(tableView, section: (indexPath as NSIndexPath).section).count)
        if tableCell.tag != -1 {
            tableCell.setContent(tableViewCellData(tableView, section: (indexPath as NSIndexPath).section)[(indexPath as NSIndexPath).row], shallow: true)
        }

        return tableCell.heightForRow()
    }

    open func tableView(_ _tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = UIEdgeInsets.zero
        }

        if cell.responds(to: #selector(setter: UIView.layoutMargins)) {
            cell.layoutMargins = UIEdgeInsets.zero
        }

        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.preservesSuperviewLayoutMargins = false
        }
    }

    //MARK: Section Header/Footer

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableViewShowsSectionHeader(tableView) {
            let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: 20))
            view.backgroundColor = RGB(240)

            let label = UILabel(frame: view.bounds)
            label.font = UIFont.systemFont(ofSize: 16)
            label.text = self.tableView(tableView, titleForHeaderInSection: section)
            label.sizeToFit()
            label.frame.size.height = view.frame.size.height
            label.frame.origin.x = 18
            view.addSubview(label)

            let line1 = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: (1.0/UIScreen.main.scale)))
            line1.backgroundColor = RGB(217)
            view.addSubview(line1)

            let line2 = UIView(frame: CGRect(x: 0, y: view.frame.size.height - 1, width: view.frame.size.width, height: (1.0/UIScreen.main.scale)))
            line2.backgroundColor = RGB(217)
            view.addSubview(line2)

            return view
        }

        return nil
    }

    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableViewShowsSectionHeader(tableView) {
            return "Pending"
        }

        return nil
    }

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableViewShowsSectionHeader(tableView) {
            return 19.0
        }

        return CGFloat.leastNormalMagnitude
    }

    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var x = [String]()
        if tableViewShowsSectionHeader(tableView) {
            for i in 0 ..< numberOfSections(in: tableView) {
                if let s = self.tableView(tableView, titleForHeaderInSection: i) {
                    x.append(s)
                }
            }
            
            return x
        }
        
        return []
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
