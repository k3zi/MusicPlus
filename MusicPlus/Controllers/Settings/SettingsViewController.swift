// 
//  SettingsViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/15/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class SettingsViewController: KZViewController {

    static let shared = SettingsViewController()

    let backgroundView = MPBackgroundView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"
        setupMenuToggle()
        view.addSubview(backgroundView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        backgroundView.autoPinEdgesToSuperviewEdges()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    @objc func dismissPresenting() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

}
