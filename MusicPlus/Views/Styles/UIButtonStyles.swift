// 
//  a.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

extension UIButton {

    class func styleForBack() -> UIButton {
        let button = ExtendedButton()
        button.horizontalTouchMargin = 20
        button.verticalTouchMargin = 20
        button.imageEdgeInsets = .init(top: 0, left: -10, bottom: 0, right: 0)

        button.setImage(#imageLiteral(resourceName: "backBT"), for: .normal)
        button.frame.size = CGSize(width: 30, height: 40)
        button.contentMode = .left
        return button
    }

}
