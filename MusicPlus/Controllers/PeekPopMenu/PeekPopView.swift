//
//  PeekPopView.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/14.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import UIKit

class PeekPopView: UIView {

    var targetView: UIView? {
        didSet {
            guard let targetView = targetView else {
                return
            }

            targetViewContainer.subviews.forEach { $0.removeFromSuperview() }
            targetViewContainer.addSubview(targetView)
            targetView.autoPinEdgesToSuperviewEdges()
        }
    }

    // MARK: Subviews
    let blurViewHolder = UIView()
    let blurView = CustomIntensityVisualEffectView(effect: UIBlurEffect(style: .light), intensity: 0.5)

    // Target preview view
    var targetViewContainer = UIView()

    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        os_log("setup")
        blurViewHolder.addSubview(blurView)
        addSubview(blurViewHolder)

        targetViewContainer.layer.cornerRadius = 15
        targetViewContainer.clipsToBounds = true
        addSubview(targetViewContainer)

        blurViewHolder.autoPinEdgesToSuperviewEdges()
        blurView.autoPinEdgesToSuperviewEdges()

        targetViewContainer.autoPinEdge(toSuperviewEdge: .left, withInset: 15)
        targetViewContainer.autoPinEdge(toSuperviewEdge: .right, withInset: 15)
        targetViewContainer.autoCenterInSuperview()
    }

    func didAppear() {
        os_log("didAppear")
        blurViewHolder.alpha = 0.0
        targetView?.becomeFirstResponder()
    }

    func animateProgress(_ progress: CGFloat) {
        os_log("animateProgress: %d", progress)
        UIView.animate(withDuration: 0.5, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.blurViewHolder.alpha = min(progress, 0.9)
        }, completion: nil)
    }

}
