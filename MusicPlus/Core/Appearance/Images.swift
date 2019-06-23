//
//  Images.swift
//  MusicPlus
//
//  Created by kezi on 6/23/19.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

enum Images {

    static var chevronDown: UIImage { image() }

    static var chevronTrailing: UIImage { image() }

    static var chevronUp: UIImage { image() }

    static var next: UIImage { image() }

    static var pause: UIImage { image() }

    static var play: UIImage { image() }

    static var previous: UIImage { image() }

}

private func image(withName name: String = #function, inBundle bundle: Bundle = Bundle.main) -> UIImage {
    return UIImage(named: name, in: bundle, with: nil)!
}
