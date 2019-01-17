//
//  PlayerViewController.swift
//  Music+
//
//  Created by kezi on 2018/10/27.
//  Copyright © 2018 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class PlayerViewController: MPViewController {

    static let shared = PlayerViewController()
    lazy var minimizeButton: ExtendedButton = {
        let button = ExtendedButton()
        button.setImage(#imageLiteral(resourceName: "backBT"), for: .normal)
        button.addTarget(MPContainerViewController.sharedInstance, action: #selector(MPContainerViewController.minimizePlayer), for: .touchUpInside)
        return button
    }()

    lazy var miniPlayerView: MiniPlayerView = {
        let view = MiniPlayerView()
        view.autoSetDimension(.height, toSize: 50)

        let tapRecognizer = UITapGestureRecognizer(target: MPContainerViewController.sharedInstance, action: #selector(MPContainerViewController.maximizePlayer))
        tapRecognizer.cancelsTouchesInView = true
        view.addGestureRecognizer(tapRecognizer)

        let heartButton = UIButton.styleForHeart()
        view.addSubview(heartButton)
        heartButton.autoPinEdge(toSuperviewEdge: .top, withInset: 18)
        heartButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
        heartButton.autoPinEdge(toSuperviewEdge: .right, withInset: 18)

        return view
    }()

    lazy var volumeSlider: SliderView = {
        let view = SliderView()
        view.backgroundTrackColor = UIColor.white.withAlphaComponent(0.3)
        view.progressTrackColor = .white
        view.innerScrubberColor = .white
        view.outerScrubberColor = UIColor.white.withAlphaComponent(0.2)
        view.progressDidChange = { progress, _ in
            KZPlayer.sharedInstance.systemVolume = Float(progress)
        }
        return view
    }()

    lazy var timeSlider: SliderView = {
        let view = SliderView()
        view.backgroundTrackColor = UIColor.white.withAlphaComponent(0.3)
        view.progressTrackColor = AppDelegate.del().session.tintColor ?? .white
        view.innerScrubberColor = .white
        view.outerScrubberColor = UIColor.white.withAlphaComponent(0.2)
        view.progressDidChange = { progress, final in
            guard final else {
                return
            }

            let duration = KZPlayer.sharedInstance.duration()
            KZPlayer.sharedInstance.setCurrentTime(duration * Double(progress))
        }
        return view
    }()

    var artworkViews = [UIImageView]()
    // Must be an odd number
    let numberOfArtworkViews = 5

    var currentArtworkView: UIImageView {
        return artworkViews[numberOfArtworkViews / 2]
    }

    // MARK: Setup View

    override func viewDidLoad() {
        view.addSubview(miniPlayerView)
        view.addSubview(minimizeButton)
        view.addSubview(volumeSlider)
        view.addSubview(timeSlider)

        for _ in 0..<numberOfArtworkViews {
            let artworkView = UIImageView()
            artworkView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.7)
            view.addSubview(artworkView)
            artworkViews.append(artworkView)
        }

        super.viewDidLoad()

        KZPlayer.sharedInstance.audioSession.addObserver(self, forKeyPath: Constants.Observation.outputVolume, options: [.initial, .new], context: nil)

        NotificationCenter.default.addObserver(forName: Constants.Notification.tintColorDidChange, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.timeSlider.progressTrackColor = AppDelegate.del().session.tintColor ?? .white
        }

        KZPlayer.sharedInstance.currentTimeObservationHandler = { [weak self] currentTime, duration in
            DispatchQueue.main.async {
                self?.timeSlider.progress = CGFloat(currentTime / duration)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func setupConstraints() {
        super.setupConstraints()

        miniPlayerView.autoPinEdge(toSuperviewEdge: .left)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .right)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .top)

        minimizeButton.autoPinEdge(.top, to: .bottom, of: miniPlayerView, withOffset: 30)
        minimizeButton.autoPinEdge(toSuperviewEdge: .left, withInset: 18)

        volumeSlider.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        volumeSlider.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
        volumeSlider.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)

        for i in 0..<artworkViews.count {
            let artworkView = artworkViews[i]
            if artworkView == currentArtworkView {
                artworkView.autoPinEdge(.top, to: .bottom, of: minimizeButton, withOffset: 18)
                artworkView.autoAlignAxis(toSuperviewAxis: .vertical)
                artworkView.autoMatch(.width, to: .width, of: view, withMultiplier: 0.9)
            } else {
                artworkView.autoAlignAxis(.horizontal, toSameAxisOf: currentArtworkView)
                artworkView.autoMatch(.width, to: .width, of: currentArtworkView, withMultiplier: 0.8)
            }
            artworkView.autoMatch(.height, to: .width, of: artworkView)

            if i > 0 {
                let prevArtworkView = artworkViews[i - 1]
                artworkView.autoPinEdge(.left, to: .right, of: prevArtworkView, withOffset: 18)
            }
        }

        timeSlider.autoMatch(.width, to: .width, of: view, withMultiplier: 0.9)
        timeSlider.autoPinEdge(.top, to: .bottom, of: currentArtworkView, withOffset: 18)
        timeSlider.autoAlignAxis(toSuperviewAxis: .vertical)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == nil, keyPath == Constants.Observation.outputVolume, let volume = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }

        volumeSlider.progress = CGFloat(volume)
    }

}
