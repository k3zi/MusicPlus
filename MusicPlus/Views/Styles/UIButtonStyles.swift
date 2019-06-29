// 
//  a.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

extension UIButton {

    static func styleForBack() -> UIButton {
        let button = ExtendedButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.horizontalTouchMargin = 20
        button.verticalTouchMargin = 20

        let image = Images.navigationChevronLeading
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(imageView)
        NSLayoutConstraint.goo.activate([
            imageView.goo.boundingAnchor.makeRelativeEdgesEqualToSuperview(insets: .systemMultiples(top: 1.5, left: 0, bottom: 1.5, right: 0))
        ])
        imageView.tintColor = Colors.navigationBackButton
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }

    static func styleForMenu() -> UIButton {
        let button = ExtendedButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.horizontalTouchMargin = 20
        button.verticalTouchMargin = 20

        let image = Images.hamburger
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(imageView)
        NSLayoutConstraint.goo.activate([
            imageView.goo.boundingAnchor.makeRelativeEdgesEqualToSuperview(insets: .systemMultiples(top: 0, left: 0, bottom: 0, right: 1))
        ])
        imageView.tintColor = Colors.navigationBackButton
        imageView.contentMode = .scaleAspectFit
        return button
    }

}
