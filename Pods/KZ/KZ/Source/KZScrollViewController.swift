//
//  KZScrollViewController.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

open class KZScrollViewController: KZViewController {
    open var scrollView = UIScrollView()
    open var contentView = UIView()


    override open func viewDidLoad() {
        super.viewDidLoad()

        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
    }

    open override func setupConstraints() {
        super.setupConstraints()

        scrollView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        contentView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        contentView.autoMatch(.width, to: .width, of: view)
    }
}
