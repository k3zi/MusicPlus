// 
//  UIColor+Chroma.swift
//  Chroma
// 
//  Created by Satyam Ghodasara on 2/4/16.
//  Copyright © 2016 Satyam Ghodasara. All rights reserved.
// 

import UIKit

extension UIColor {

    func isBlackOrWhite() -> Bool {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        if (r > 0.91 && g > 0.91 && b > 0.91) || (r < 0.09 && g < 0.09 && b < 0.09) {
            return true
        } else {
            return false
        }
    }

}
