//
//  SliderView.swift
//  Music+
//
//  Created by kezi on 2018/10/28.
//  Copyright © 2018 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class SliderView: UIView {

    // Background Track

    private lazy var backgroundTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = self.backgroundTrackColor
        return view
    }()

    var backgroundTrackColor: UIColor = .gray {
        didSet {
            backgroundTrackView.backgroundColor = backgroundTrackColor
        }
    }

    // Progress Track

    private lazy var progressTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = self.progressTrackColor
        return view
    }()

    var progressTrackColor: UIColor = .gray {
        didSet {
            progressTrackView.backgroundColor = progressTrackColor
        }
    }

    // Outer Scrubber

    private static let outerScrubberHeight: CGFloat = 24.0

    private lazy var outerScrubberView: UIView = {
        let view = UIView()
        view.backgroundColor = self.outerScrubberColor
        view.clipsToBounds = true
        return view
    }()

    var outerScrubberColor: UIColor = .white {
        didSet {
            outerScrubberView.backgroundColor = outerScrubberColor
        }
    }

    // Inner Scrubber

    private static let innerScrubberHeight: CGFloat = 12.0

    private lazy var innerScrubberView: UIView = {
        let view = UIView()
        view.backgroundColor = self.innerScrubberColor
        view.clipsToBounds = true
        return view
    }()

    var innerScrubberColor: UIColor = .white {
        didSet {
            innerScrubberView.backgroundColor = innerScrubberColor
        }
    }

    // Movement

    var prgressConstraint: NSLayoutConstraint?

    private var isSliding = false

    var progress: CGFloat = 0.0 {
        didSet {
            guard !isSliding, UIView.isVisible(view: self) else {
                return
            }

            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction], animations: {
                self.prgressConstraint?.autoRemove()
                self.prgressConstraint = self.progressTrackView.autoMatch(.width, to: .width, of: self.backgroundTrackView, withMultiplier: self.progress)

                self.layoutIfNeeded()
            }, completion: nil)
        }
    }

    // Delegate

    var progressDidChange: ((_ prgress: CGFloat, _ complete: Bool) -> Void)?

    // Initialization

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(backgroundTrackView)
        addSubview(progressTrackView)

        addSubview(outerScrubberView)
        addSubview(innerScrubberView)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -10, dy: -10).contains(point)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }

        let overallTranslation = touch.location(in: self)
        guard outerScrubberView.frame.insetBy(dx: -40, dy: -20).contains(overallTranslation) else {
            return
        }

        isSliding = true
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        proccess(touches: touches, final: false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        proccess(touches: touches, final: true)
        isSliding = false
    }

    func proccess(touches: Set<UITouch>, final: Bool) {
        guard isSliding, let touch = touches.first else {
            return
        }

        let progressTranslation = touch.location(in: backgroundTrackView)
        let horizontalTranslation = min(max(progressTranslation.x, 0), backgroundTrackView.bounds.width)

        let progress = horizontalTranslation / backgroundTrackView.bounds.width
        prgressConstraint?.autoRemove()
        prgressConstraint = progressTrackView.autoMatch(.width, to: .width, of: backgroundTrackView, withMultiplier: progress)
        self.progress = progress
        self.progressDidChange?(progress, final)
        self.layoutIfNeeded()
    }

    func setupConstraints() {
        backgroundTrackView.autoPinEdge(toSuperviewEdge: .left, withInset: SliderView.outerScrubberHeight / 2)
        backgroundTrackView.autoPinEdge(toSuperviewEdge: .right, withInset: SliderView.outerScrubberHeight / 2)
        backgroundTrackView.autoSetDimension(.height, toSize: 5)
        backgroundTrackView.autoAlignAxis(toSuperviewAxis: .horizontal)

        progressTrackView.autoPinEdge(.left, to: .left, of: backgroundTrackView)
        progressTrackView.autoMatch(.height, to: .height, of: backgroundTrackView)
        progressTrackView.autoAlignAxis(toSuperviewAxis: .horizontal)

        outerScrubberView.autoPinEdge(toSuperviewEdge: .top)
        outerScrubberView.autoPinEdge(toSuperviewEdge: .bottom)
        outerScrubberView.autoSetDimensions(to: .init(width: SliderView.outerScrubberHeight, height: SliderView.outerScrubberHeight))
        outerScrubberView.autoPinEdge(.right, to: .right, of: progressTrackView, withOffset: SliderView.outerScrubberHeight / 2)

        innerScrubberView.autoSetDimensions(to: .init(width: SliderView.innerScrubberHeight, height: SliderView.innerScrubberHeight))
        innerScrubberView.autoAlignAxis(.horizontal, toSameAxisOf: outerScrubberView)
        innerScrubberView.autoAlignAxis(.vertical, toSameAxisOf: outerScrubberView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        innerScrubberView.layer.cornerRadius = innerScrubberView.bounds.height / 2
        outerScrubberView.layer.cornerRadius = outerScrubberView.bounds.height / 2
    }

}
