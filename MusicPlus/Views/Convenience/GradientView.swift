// 
//  GradientView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class GradientView: UIView {
    var gradientLayer: CAGradientLayer? {
        return layer as? CAGradientLayer
    }

    var colors: [Any]? {
        set {
            guard let gradientLayer = layer as? CAGradientLayer else {
                return
            }

            gradientLayer.colors = newValue
        }

        get {
            guard let gradientLayer = layer as? CAGradientLayer else {
                return nil
            }

            return gradientLayer.colors
        }
    }

    var startPoint: CGPoint? {
        get {
            guard let gradientLayer = layer as? CAGradientLayer else {
                return nil
            }

            return gradientLayer.startPoint
        }

        set {
            guard let gradientLayer = layer as? CAGradientLayer, let newValue = newValue else {
                return
            }

            gradientLayer.startPoint = newValue
        }
    }

    var endPoint: CGPoint? {
        get {
            guard let gradientLayer = layer as? CAGradientLayer else {
                return nil
            }

            return gradientLayer.endPoint
        }

        set {
            guard let gradientLayer = layer as? CAGradientLayer, let newValue = newValue else {
                return
            }

            gradientLayer.endPoint = newValue
        }
    }

    override public class var layerClass: Swift.AnyClass {
        return CAGradientLayer.self
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        guard let gradientLayer = layer as? CAGradientLayer else {
            return
        }

        gradientLayer.colors = [UIColor.red.cgColor, UIColor.white.cgColor]
    }
}
