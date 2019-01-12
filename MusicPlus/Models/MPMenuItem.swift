// 
//  MPMenuItem.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/12/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import Foundation

class MPMenuItem {
    let name: String
    let icon: UIImage
    let controller: KZViewController
    let shouldPresent: Bool

    init(name: String, imageName: String, controller: KZViewController, shouldPresent: Bool = false) {
        self.name = name
        self.icon = UIImage(named: imageName) ?? UIImage()
        self.controller = controller
        self.shouldPresent = shouldPresent
    }
}
