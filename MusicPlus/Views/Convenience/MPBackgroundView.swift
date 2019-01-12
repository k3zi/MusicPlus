// 
//  MPBackgroundView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPBackgroundView: UIView {

    let backgroundImageView = UIImageView(image: Constants.UI.Image.defaultBackground)
    let tintOverlayView = GradientView()
    let darkOverlayView = GradientView()

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)

        updateTint()
        addSubview(tintOverlayView)

        darkOverlayView.colors = [RGB(0).withAlphaComponent(0.3).cgColor, RGB(0).withAlphaComponent(0.8).cgColor]
        addSubview(darkOverlayView)

        sendSubviewToBack(darkOverlayView)
        sendSubviewToBack(tintOverlayView)
        sendSubviewToBack(backgroundImageView)

        NotificationCenter.default.addObserver(self, selector: #selector(updateBackground), name: Constants.Notification.backgroundImageDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(animateTint), name: Constants.Notification.tintColorDidChange, object: nil)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupConstraints() {
        backgroundImageView.autoPinEdgesToSuperviewEdges()
        tintOverlayView.autoPinEdgesToSuperviewEdges()
        darkOverlayView.autoPinEdgesToSuperviewEdges()
    }

    @objc func updateBackground() {
        UIView.transition(with: backgroundImageView, duration: Constants.UI.Animation.imageFade, options: [.transitionCrossDissolve], animations: {
            self.backgroundImageView.image = AppDelegate.del().session.backgroundImage
        }, completion: nil)
    }

    @objc func animateTint() {
        UIView.animate(withDuration: Constants.UI.Animation.imageFade, animations: {
            self.updateTint()
        })
    }

    func updateTint() {
        guard let tint = AppDelegate.del().session.tintColor else {
            return
        }

        tintOverlayView.colors = [tint.cgColor, tint.withAlphaComponent(0.0).cgColor]
    }
}
