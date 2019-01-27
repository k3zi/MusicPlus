//
//  PeekPop.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/14.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

open class PeekPop: NSObject, UIGestureRecognizerDelegate {

    // MARK: Variables
    fileprivate var previewingContexts = [PreviewingContext]()

    internal var viewController: UIViewController
    internal var peekPopGestureRecognizer: PeekPopGestureRecognizer?

    // MARK: Lifecycle

    /**
     Peek pop initializer

     - parameter viewController: hosting UIViewController

     - returns: PeekPop object
     */
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }

    // MARK: Delegate registration

    /// Registers a view controller to participate with 3D Touch preview (peek) and commit (pop).
    open func registerForPreviewingWithDelegate(_ delegate: PeekPopPreviewingDelegate, sourceView: UIView) {
        let previewing = PreviewingContext(delegate: delegate, sourceView: sourceView)
        previewingContexts.append(previewing)

        let gestureRecognizer = PeekPopGestureRecognizer(peekPop: self)
        gestureRecognizer.context = previewing
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delaysTouchesBegan = true
        gestureRecognizer.delegate = self
        sourceView.addGestureRecognizer(gestureRecognizer)
        peekPopGestureRecognizer = gestureRecognizer
    }

    /// Check whether force touch is available
    func isForceTouchCapable() -> Bool {
        if #available(iOS 9.0, *) {
            return (self.viewController.traitCollection.forceTouchCapability == UIForceTouchCapability.available && TARGET_OS_SIMULATOR != 1)
        }
        return false
    }

}

/// Previewing context struct
open class PreviewingContext {
    /// Previewing delegate
    open weak var delegate: PeekPopPreviewingDelegate?
    /// Source view
    public let sourceView: UIView
    /// Source rect
    open var sourceRect: CGRect

    init(delegate: PeekPopPreviewingDelegate, sourceView: UIView) {
        self.delegate = delegate
        self.sourceView = sourceView
        self.sourceRect = sourceView.frame
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

public protocol PeekPopPreviewingDelegate: class {
    /// Provide view controller for previewing context in location. If you return nil, a preview presentation will not be performed.
    func previewingContext(_ previewingContext: PreviewingContext, viewForLocation location: CGPoint) -> UIView?
}
