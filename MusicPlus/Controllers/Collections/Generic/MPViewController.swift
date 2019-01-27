//
//  MPViewController.swift
//  Music+
//
//  Created by kezi on 2018/10/27.
//  Copyright © 2018 Kesi Maduka. All rights reserved.
//

import UIKit

class MPViewController: KZViewController {

    let backgroundView = MPBackgroundView()

    // MARK: - Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        view.insertSubview(backgroundView, at: 0)
    }

    override func setupConstraints() {
        backgroundView.autoPinEdgesToSuperviewEdges()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    // MARK: - Side Menu

    func toggleMenu() {
        if let parentViewController = parent as? MPContainerViewController {
            parentViewController.toggleMenu()
        }
    }

}
