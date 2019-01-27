//
//  PopupItemView.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/15.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

class PopupItemView: UIView {

    var isSelected: Bool = false {
        didSet {
            backgroundColor = isSelected ? Constants.UI.Color.popupMenuItemSelected : Constants.UI.Color.popupMenuItem
        }
    }

    var didSelect: (() -> Void)?

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }

        if point(inside: touch.location(in: self), with: event) {
            if !isSelected {
                isSelected = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } else if isSelected {
            isSelected = false
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isSelected {
            isSelected = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            didSelect?()
        }
    }
}
