// 
//  MPNavigationController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPNavigationController: UINavigationController {

    let backgroundView = MPBackgroundView()

    // MARK: Setup View

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: RGB(255), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)]
        navigationBar.tintColor = RGB(255)

        view.insertSubview(backgroundView, at: 0)

        setupConstraints()
    }

    func setupConstraints() {
        backgroundView.autoPinEdgesToSuperviewEdges()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    // MARK: Side Menu

    func toggleMenu() {
        guard let parentViewController = parent as? MPContainerViewController else {
            return
        }

        parentViewController.toggleMenu()
    }
}
