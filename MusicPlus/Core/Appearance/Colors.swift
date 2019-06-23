//
//  Colors.swift
//  MusicPlus
//
//  Created by kezi on 6/23/19.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

enum Colors {

    static var artistAlbumToggleButton: UIColor { color() }

    static var minimizeButton: UIColor { color() }

}

private func color(withName name: String = #function, inBundle bundle: Bundle = Bundle.main) -> UIColor {
    return UIColor(named: name, in: bundle, compatibleWith: nil)!
}
