//
//  UIViewController+Menu.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

extension UIViewController {

    func setupMenuToggle() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "menuBT"), style: .plain, target: MPContainerViewController.sharedInstance, action: #selector(MPContainerViewController.toggleMenu))
    }

    open func presentAlert(_ viewControllerToPresent: UIAlertController, animated flag: Bool, completion: (() -> Void)?) {
        self.present(viewControllerToPresent, animated: flag) {
            viewControllerToPresent.view.superview?.subviews.first?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissPopup)))
        }
    }

}
