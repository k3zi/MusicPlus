//
//  SliderView.swift
//  Music+
//
//  Created by kezi on 2018/10/28.
//  Copyright © 2018 Kesi Maduka. All rights reserved.
//

import Combine
import Gooey
import UIKit

class SliderView: UIView {

    // MARK: Background Track

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

    // MARK: Progress Track

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

    static let outerScrubberHeight: CGFloat = 24.0

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

    var progressConstraint: NSLayoutConstraint?

    private var isSliding = false
    var updateWhenOffScreen = false

    let progress = CurrentValueSubject<CGFloat, Never>(0.0)

    // Initialization

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundTrackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundTrackView)

        progressTrackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressTrackView)

        outerScrubberView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outerScrubberView)

        innerScrubberView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(innerScrubberView)

        setupConstraints()

        _ = progress
            .sink { [unowned self] value in
            guard !self.isSliding, self.updateWhenOffScreen || UIView.isVisible(view: self) else {
                return
            }

            if value.isInfinite {
                self.progress.send(1)
                return
            }

            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction], animations: {
                self.progressConstraint?.autoRemove()
                self.progressConstraint = self.progressTrackView.autoMatch(.width, to: .width, of: self.backgroundTrackView, withMultiplier: max(min(value, 1), 0.0))

                self.layoutIfNeeded()
            }, completion: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -CGFloat.goo.systemSpacing, dy: -CGFloat.goo.systemSpacing).contains(point)
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
        progressConstraint?.autoRemove()
        progressConstraint = progressTrackView.autoMatch(.width, to: .width, of: backgroundTrackView, withMultiplier: progress)
        self.progress.send(progress)
        self.layoutIfNeeded()
    }

    func setupConstraints() {
        NSLayoutConstraint.goo.activate([
            backgroundTrackView.goo.boundingAnchor.makeHorizontalEdgesEqualToSuperview(insets: .both(type(of: self).outerScrubberHeight / CGFloat(2))),
            backgroundTrackView.heightAnchor.constraint(equalToConstant: CGFloat.goo.systemSpacing),
            backgroundTrackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            progressTrackView.leadingAnchor.constraint(equalTo: backgroundTrackView.leadingAnchor),
            progressTrackView.heightAnchor.constraint(equalTo: backgroundTrackView.heightAnchor),
            progressTrackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            outerScrubberView.goo.boundingAnchor.makeVerticalEdgesEqualToSuperview(),
            outerScrubberView.widthAnchor.constraint(equalToConstant: SliderView.outerScrubberHeight),
            outerScrubberView.heightAnchor.constraint(equalTo: outerScrubberView.widthAnchor),
            outerScrubberView.trailingAnchor.constraint(equalTo: progressTrackView.trailingAnchor, constant: SliderView.outerScrubberHeight / 2),

            innerScrubberView.widthAnchor.constraint(equalToConstant: SliderView.innerScrubberHeight),
            innerScrubberView.heightAnchor.constraint(equalTo: innerScrubberView.widthAnchor),
            innerScrubberView.centerYAnchor.constraint(equalTo: outerScrubberView.centerYAnchor),
            innerScrubberView.centerXAnchor.constraint(equalTo: outerScrubberView.centerXAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        innerScrubberView.layer.cornerRadius = innerScrubberView.bounds.height / 2
        outerScrubberView.layer.cornerRadius = outerScrubberView.bounds.height / 2
    }

}
