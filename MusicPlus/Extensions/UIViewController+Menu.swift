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

}
