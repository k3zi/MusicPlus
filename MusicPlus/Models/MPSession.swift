// 
//  MPSession.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/11/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import Foundation

class MPSession {
    var tintColor: UIColor? = Constants.UI.Color.defaultTint {
        didSet {
            if tintColor == nil {
                tintColor = Constants.UI.Color.defaultTint
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .tintColorDidChange, object: nil)
            }
        }
    }

    var backgroundImage: UIImage? = Constants.UI.Image.defaultBackground {
        didSet {
            if backgroundImage == nil {
                backgroundImage = Constants.UI.Image.defaultBackground
            }

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .backgroundImageDidChange, object: nil)
            }
        }
    }

    func reset() {
        self.tintColor = nil
        self.backgroundImage = nil
    }
}
