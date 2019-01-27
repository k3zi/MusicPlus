// 
//  MPNavigationController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
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
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)]
        navigationBar.tintColor = .white

        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
            navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }

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
