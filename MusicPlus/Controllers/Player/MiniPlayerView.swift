//
//  MiniPlayerView.swift
//  Music+
//
//  Created by kezi on 2018/10/27.
//  Copyright © 2018 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

fileprivate extension UIImage {

    static let play = #imageLiteral(resourceName: "playBT").af_imageAspectScaled(toFit: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 60))
    static let pause = #imageLiteral(resourceName: "pauseBT").af_imageAspectScaled(toFit: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 60))
    static let next = #imageLiteral(resourceName: "nextBT").af_imageAspectScaled(toFit: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 120))
    static let previous = #imageLiteral(resourceName: "Image").af_imageAspectScaled(toFit: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 60))
}

class MiniPlayerView: UIView {

    let backgroundImageView = UIImageView(image: Constants.UI.Image.defaultBackground)
    let tintOverlayView = GradientView()
    let darkOverlayView = GradientView()

    lazy var playPauseButton: UIButton = {
        let view = UIButton()
        view.tintColor = .white
        view.setImage(.play, for: .normal)
        view.addTarget(KZPlayer.sharedInstance, action: #selector(KZPlayer.togglePlay), for: .touchUpInside)
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()

    lazy var songTitleLabel: UILabel = {
        let view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        view.textAlignment = .center
        return view
    }()

    lazy var nextButton: UIButton = {
        let view = ExtendedButton()
        view.tintColor = .white
        view.setImage(.next, for: .normal)
        view.addTarget(KZPlayer.sharedInstance, action: #selector(KZPlayer.next), for: .touchUpInside)
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()

    lazy var subTitleLabel: UILabel = {
        let view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        view.textAlignment = .center
        return view
    }()

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundImageView.contentMode = .top
        backgroundImageView.clipsToBounds = true
        addSubview(backgroundImageView)

        updateTint()
        addSubview(tintOverlayView)

        darkOverlayView.colors = [RGB(0).withAlphaComponent(0.3).cgColor, RGB(0).withAlphaComponent(0.6).cgColor]
        addSubview(darkOverlayView)

        sendSubviewToBack(darkOverlayView)
        sendSubviewToBack(tintOverlayView)
        sendSubviewToBack(backgroundImageView)

        addSubview(playPauseButton)

        addSubview(songTitleLabel)
        addSubview(subTitleLabel)

        addSubview(nextButton)

        NotificationCenter.default.addObserver(self, selector: #selector(updateBackground), name: .backgroundImageDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(animateTint), name: .tintColorDidChange, object: nil)

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

        playPauseButton.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        playPauseButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        playPauseButton.autoSetDimensions(to: .init(width: 25, height: 25))

        songTitleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 6)
        songTitleLabel.autoPinEdge(.left, to: .right, of: playPauseButton, withOffset: 18)
        songTitleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        subTitleLabel.autoMatch(.width, to: .width, of: songTitleLabel)
        subTitleLabel.autoPinEdge(.top, to: .bottom, of: songTitleLabel, withOffset: 0)
        subTitleLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 6)
        subTitleLabel.autoMatch(.height, to: .height, of: songTitleLabel)
        subTitleLabel.autoAlignAxis(toSuperviewAxis: .vertical)

        nextButton.autoPinEdge(.left, to: .right, of: songTitleLabel, withOffset: 18, relation: .greaterThanOrEqual)
        nextButton.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
        nextButton.autoAlignAxis(toSuperviewAxis: .horizontal)
        nextButton.autoSetDimensions(to: .init(width: 20, height: 20))
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
