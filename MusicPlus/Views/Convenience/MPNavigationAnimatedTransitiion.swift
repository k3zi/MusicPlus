// 
//  MPNavigationAnimatedTransitiion.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class MPNavigationAnimatedTransitiion: NSObject, UIViewControllerAnimatedTransitioning {

    let operation: UINavigationController.Operation

    init(operation: UINavigationController.Operation) {
        self.operation = operation
    }

    @objc func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.UI.Animation.controllerPushPop
    }

    @objc func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from), let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }

        let fromView = fromVC.view
        let toView = toVC.view

        let containerWidth = container.frame.width

        var toInitialFrame = container.frame
        var fromDestinationFrame = fromView?.frame

        if operation == .push {
            toInitialFrame.origin.x = containerWidth
            toView?.frame = toInitialFrame
            fromDestinationFrame?.origin.x = -containerWidth
        } else if operation == .pop {
            toInitialFrame.origin.x = -containerWidth
            toView?.frame = toInitialFrame
            fromDestinationFrame?.origin.x = containerWidth
        }

        toView?.isUserInteractionEnabled = false
        if !container.subviews.contains(toView!) {
            container.addSubview(toView!)
        }

        UIView.animate(withDuration: Constants.UI.Animation.controllerPushPop, delay: 0.0, usingSpringWithDamping: 1000, initialSpringVelocity: 1, options: [], animations: {
            toView?.frame = container.frame
            fromView?.frame = fromDestinationFrame!
            }) { (_) in
                toView?.frame = container.frame
                toView?.isUserInteractionEnabled = true
                fromView?.removeFromSuperview()
                transitionContext.completeTransition(true)
        }
    }
}
