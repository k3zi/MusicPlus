//
//  UIViewController+Menu.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

extension UIViewController {

    func setupMenuToggle() {

        let button = UIButton.styleForMenu()
        button.addTarget(MPContainerViewController.sharedInstance, action: #selector(MPContainerViewController.toggleMenu), for: .touchDown)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    func setUpLibraryBarItem() {
        let barButton = UIBarButtonItem(title: KZPlayer.sharedInstance.currentLibrary?.name ?? "", style: .plain, target: nil, action: nil)
        if (navigationItem.leftBarButtonItems?.count ?? 0) > 1 {
            navigationItem.leftBarButtonItems?[1] = barButton
        } else {
            navigationItem.leftBarButtonItems?.append(barButton)
        }
    }

    open func presentAlert(_ viewControllerToPresent: UIAlertController, animated flag: Bool, completion: (() -> Void)?) {
        self.present(viewControllerToPresent, animated: flag) {
            viewControllerToPresent.view.superview?.subviews.first?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissPopup)))
        }
    }

}
