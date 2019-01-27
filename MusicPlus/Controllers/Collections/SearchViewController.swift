//
//  SearchViewController.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/27.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class SearchViewController: KZViewController {

    static let shared = SearchViewController()
    var tableView = UITableView(frame: .zero, style: .plain)
    let shadowView = UIView()
    let shadowLayer = CAGradientLayer()
    var shadowTopConstraint: NSLayoutConstraint?
    var topLayoutGuideConstraint: NSLayoutConstraint?

    // MARK: Setup View

    override func viewDidLoad() {
        fetchAUtomatically = false
        super.viewDidLoad()

        title = "Advanced Search"
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
        shadowLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        shadowView.layer.insertSublayer(shadowLayer, at: 0)
        shadowView.alpha = 0.0
        view.addSubview(shadowView)
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        shadowView.alpha = min(scrollView.contentOffset.y / 300.0, 0.3)
    }

}
