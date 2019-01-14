//
//  PeekPopView.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/14.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import UIKit
class PeekPopView: UIView {

    // MARK: Constants

    // These are 'magic' values
    let targePreviewPadding = CGSize(width: 28, height: 140)

    var targetView: UIView? {
        didSet {
            guard let targetView = targetView else {
                return
            }

            targetPreviewView.targetViewContainer.addSubview(targetView)
            targetView.autoPinEdgesToSuperviewEdges()
        }
    }

    // MARK: Subviews
    // Blurry image views, used for interpolation
    let blurViewHolder = UIView()
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    // Overlay view
    var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.85, alpha: 0.5)
        return view
    }()

    // Source image view
    var sourceImageView = UIImageView()

    // Target preview view
    var targetPreviewView = PeekPopTargetPreviewView()

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
        blurViewHolder.addSubview(blurView)
        self.addSubview(blurViewHolder)
        blurViewHolder.autoPinEdgesToSuperviewEdges()
        blurView.autoPinEdgesToSuperviewEdges()
    }

    func didAppear() {
        blurViewHolder.alpha = 0.0
        overlayView.frame = self.bounds
    }

    func animateProgress(_ progress: CGFloat) {
        blurViewHolder.alpha = progress
    }
}

class PeekPopTargetPreviewView: UIView {

    var targetViewContainer = UIView()
    var imageViewFrame = CGRect.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        targetViewContainer.frame = self.bounds
    }

    func setup() {
        self.addSubview(targetViewContainer)
        targetViewContainer.layer.cornerRadius = 15
        targetViewContainer.clipsToBounds = true
    }
}
