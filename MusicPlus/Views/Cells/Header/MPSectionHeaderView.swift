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

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.semibold)
        label.textColor = AppDelegate.del().session.tintColor
        addSubview(label)

        fillInView()
        setupConstraints()
    }

    func fillInView() {
        label.text = self.name
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leftAnchor.constraint(equalToSystemSpacingAfter: leftAnchor, multiplier: 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    @objc func updateTint() {
        label.textColor = AppDelegate.del().session.tintColor
    }

}
