//
//  PeekPopManager.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/14.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

class PeekPopManager {

    let peekPop: PeekPop

    var viewController: UIViewController {
        return peekPop.viewController
    }
    var targetView: UIView?

    fileprivate var peekPopView: PeekPopView?
    fileprivate lazy var peekPopWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = UIWindow.Level.alert
        let vc = MPNavigationController()
        vc.backgroundView.isHidden = true
        window.rootViewController = vc
        return window
    }()

    init(peekPop: PeekPop) {
        self.peekPop = peekPop
    }

    // MARK: PeekPop

    /// Prepare peek pop view if peek and pop gesture is possible
    func peekPopPossible(_ context: PreviewingContext, touchLocation: CGPoint) -> Bool {

        // Return early if no target view controller is provided by delegate method
        guard let targetView = context.delegate?.previewingContext(context, viewForLocation: touchLocation) else {
            return false
        }

        // Create PeekPopView
        let view = PeekPopView()
        peekPopView = view
        peekPopView?.targetView = targetView
        self.targetView = targetView

        return true
    }

    /// Add window to heirarchy when peek pop begins
    func peekPopBegan() {
        peekPopWindow.alpha = 0.0
        peekPopWindow.isHidden = false
        peekPopWindow.makeKeyAndVisible()

        if let peekPopView = peekPopView {
            peekPopWindow.addSubview(peekPopView)
        }

        peekPopView?.frame = UIScreen.main.bounds
        peekPopView?.didAppear()

        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.peekPopWindow.alpha = 1.0
        })
    }

    /**
     Animated progress for context

     - parameter progress: A value between 0.0 and 1.0
     - parameter context:  PreviewingContext
     */
    func animateProgressForContext(_ progress: CGFloat, context: PreviewingContext?) {
        peekPopView?.animateProgress(progress)
    }

    /**
     Commit target.

     - parameter context: PreviewingContext
     */
    func commitTarget(_ context: PreviewingContext?) {
        // peekPopEnded()
    }

    /**
     Peek pop ended

     - parameter animated: whether or not window removal should be animated
     */
    func peekPopEnded() {
        guard let view = peekPopView else {
            return
        }

        UIView.animate(withDuration: 0.2, delay: 0.1, options: [], animations: {
            self.peekPopWindow.alpha = 0.0
        }) { _ in
            self.peekPop.peekPopGestureRecognizer?.resetValues()
            self.peekPopWindow.isHidden = true
            view.removeFromSuperview()
            self.peekPopWindow.resignKey()
            self.peekPopWindow.removeFromSuperview()
        }

        peekPopView = nil
    }

}
