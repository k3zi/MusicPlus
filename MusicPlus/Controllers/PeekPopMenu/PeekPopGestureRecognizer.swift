//
//  PeekPopGestureRecognizer.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/14.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import UIKit

class PeekPopGestureRecognizer: UIGestureRecognizer {

    var context: PreviewingContext?
    let peekPopManager: PeekPopManager

    let interpolationSpeed: CGFloat = 0.4
    let previewThreshold: CGFloat = 0.66
    let commitThreshold: CGFloat = 0.99

    var progress: CGFloat = 0.0
    var targetProgress: CGFloat = 0.0 {
        didSet {
            updateProgress()
        }
    }

    var firstHit = true

    override var state: UIGestureRecognizer.State {
        didSet {
            if state == .began {
                firstHit = true
            }
        }
    }

    var initialMajorRadius: CGFloat = 0.0
    var displayLink: CADisplayLink?

    var peekPopStarted = false

    // MARK: Lifecycle

    init(peekPop: PeekPop) {
        self.peekPopManager = PeekPopManager(peekPop: peekPop)
        super.init(target: nil, action: nil)
        self.delaysTouchesBegan = true
    }

    // MARK: Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first, let context = context, isTouchValid(touch) else {
            state = .failed
            return
        }

        let touchLocation = touch.location(in: self.view)
        state = (context.delegate?.previewingContext(context, viewForLocation: touchLocation) != nil) ? .possible : .failed
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if firstHit {
            peekPopManager.targetView?.touchesBegan(touches, with: event)
            firstHit = false
        } else {
            peekPopManager.targetView?.touchesMoved(touches, with: event)
        }

        if state == .failed {
            self.cancelTouches()
        }

        guard let touch = touches.first else {
            return
        }

        if touch.force > (touch.maximumPossibleForce / 2) && state == .possible {
            perform(#selector(delayedFirstTouch), with: touch)
        }

        if peekPopStarted == true {
            testForceChange(touch.majorRadius)
        }
    }

    @objc func delayedFirstTouch(_ touch: UITouch) {
        guard isTouchValid(touch), state != .began else {
            return
        }

        state = .began
        if let context = context {
            let touchLocation = touch.location(in: self.view)
            _ = peekPopManager.peekPopPossible(context, touchLocation: touchLocation)
        }
        peekPopStarted = true
        firstHit = true
        initialMajorRadius = touch.majorRadius
        peekPopManager.peekPopBegan()
        targetProgress = previewThreshold
    }

    func testForceChange(_ majorRadius: CGFloat) {
        if initialMajorRadius / majorRadius < 0.6 {
            targetProgress = 0.99
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.cancelTouches()
        super.touchesEnded(touches, with: event)
        peekPopManager.targetView?.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        self.cancelTouches()
        super.touchesCancelled(touches, with: event)
    }

    func resetValues() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        peekPopStarted = false
        progress = 0.0
    }

    fileprivate func cancelTouches() {
        self.state = .cancelled
        peekPopStarted = false
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if progress < commitThreshold {
            targetProgress = 0.0
        }
    }

    func isTouchValid(_ touch: UITouch) -> Bool {
        let sourceRect = context?.sourceView.frame ?? CGRect.zero
        let touchLocation = touch.location(in: self.view?.superview)
        return sourceRect.contains(touchLocation)
    }

    func updateProgress() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(animateToTargetProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc func animateToTargetProgress() {
        if progress < targetProgress {
            progress = min(progress + interpolationSpeed, targetProgress)
            if progress >= targetProgress {
                displayLink?.invalidate()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        } else {
            progress = max(progress - interpolationSpeed*2, targetProgress)
            if progress <= targetProgress {
                progress = 0.0
                displayLink?.invalidate()
                peekPopManager.peekPopEnded()
            }
        }

        peekPopManager.animateProgressForContext(progress / targetProgress, context: context)
    }

}
