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
        view.progressDidChange = { progress in
            KZPlayer.sharedInstance.systemVolume = Float(progress)
        }
        return view
    }()

    // MARK: Setup View

    override func viewDidLoad() {
        view.addSubview(miniPlayerView)

        view.addSubview(minimizeButton)

        view.addSubview(volumeSlider)

        super.viewDidLoad()

        KZPlayer.sharedInstance.audioSession.addObserver(self, forKeyPath: Constants.Observation.outputVolume, options: [.initial, .new], context: nil)
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
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == nil, keyPath == Constants.Observation.outputVolume, let volume = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }

        volumeSlider.progress = CGFloat(volume)
    }

}
