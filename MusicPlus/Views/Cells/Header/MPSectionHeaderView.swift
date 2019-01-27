// 
//  MPSectionHeaderView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class MPSectionHeaderView: UIView {

    let label = UILabel()
    let name: String

    init(frame: CGRect, name: String) {
        self.name = name
        super.init(frame: frame)

        setupView()

        NotificationCenter.default.addObserver(self, selector: #selector(updateTint), name: .tintColorDidChange, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupView() {
        backgroundColor = .init(white: 0, alpha: 0.2)

        label.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
        label.textColor = AppDelegate.del().session.tintColor
        addSubview(label)

        label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))

        fillInView()
        setupConstraints()
    }

    func fillInView() {
        label.text = self.name
    }

    func setupConstraints() {
        label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
    }

    @objc func updateTint() {
        label.textColor = AppDelegate.del().session.tintColor
    }

}
