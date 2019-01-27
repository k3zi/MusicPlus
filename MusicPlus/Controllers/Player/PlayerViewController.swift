//
//  PlayerViewController.swift
//  Music+
//
//  Created by kezi on 2018/10/27.
//  Copyright © 2018 Kesi Maduka. All rights reserved.
//

import UIKit

fileprivate extension UIImage {

    static let play = #imageLiteral(resourceName: "playBT").af_imageAspectScaled(toFit: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 60))
    static let pause = #imageLiteral(resourceName: "pauseBT").af_imageAspectScaled(toFit: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 60))
    static let next = #imageLiteral(resourceName: "nextBT").af_imageAspectScaled(toFit: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 60))
    static let previous = #imageLiteral(resourceName: "Image").af_imageAspectScaled(toFit: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 60))
    static let smallPause = #imageLiteral(resourceName: "smallPauseBT")

}

class PlayerViewController: MPViewController, PeekPopPreviewingDelegate {

    static let shared = PlayerViewController()
    lazy var minimizeButton: ExtendedButton = {
        let button = ExtendedButton()
        button.setImage(#imageLiteral(resourceName: "largeArrowDown"), for: .normal)
        button.addTarget(MPContainerViewController.sharedInstance, action: #selector(MPContainerViewController.minimizePlayer), for: .touchUpInside)
        return button
    }()

    lazy var miniPlayerView: MiniPlayerView = {
        let view = MiniPlayerView()
        view.autoSetDimension(.height, toSize: .miniPlayerViewHeight)

        let tapRecognizer = UITapGestureRecognizer(target: MPContainerViewController.sharedInstance, action: #selector(MPContainerViewController.maximizePlayer))
        tapRecognizer.cancelsTouchesInView = true
        view.addGestureRecognizer(tapRecognizer)

        return view
    }()

    lazy var volumeSlider: SliderView = {
        let view = SliderView()
        view.backgroundTrackColor = UIColor.white.withAlphaComponent(0.3)
        view.progressTrackColor = .white
        view.innerScrubberColor = .white
        view.outerScrubberColor = UIColor.white.withAlphaComponent(0.2)
        view.updateWhenOffScreen = true
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

    let infoHolderView = UIView()
    lazy var songTitleLabel: UILabel = {
        let view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        view.textAlignment = .center
        return view
    }()

    lazy var albumTitleLabel: UILabel = {
        let view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        view.textAlignment = .center
        return view
    }()

    lazy var artistTitleLabel: UILabel = {
        let view = UILabel()
        view.textColor = .white
        view.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        view.textAlignment = .center
        return view
    }()

    lazy var playPauseButton: UIButton = {
        let view = UIButton()
        view.tintColor = AppDelegate.del().session.tintColor ?? .white
        view.setImage(.play, for: .normal)
        view.addTarget(KZPlayer.sharedInstance, action: #selector(KZPlayer.togglePlay), for: .touchUpInside)
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()

    lazy var previousButton: UIButton = {
        let view = ExtendedButton()
        view.tintColor = AppDelegate.del().session.tintColor ?? .white
        view.setImage(.previous, for: .normal)
        view.addTarget(KZPlayer.sharedInstance, action: #selector(KZPlayer.prev), for: .touchUpInside)
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()

    lazy var nextButton: UIButton = {
        let view = ExtendedButton()
        view.tintColor = AppDelegate.del().session.tintColor ?? .white
        view.setImage(.next, for: .normal)
        view.addTarget(KZPlayer.sharedInstance, action: #selector(KZPlayer.next), for: .touchUpInside)
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()

    let artworkViewHolder = UIView()
    let artworkViewHolderViewHolder = UIView()
    var artworkViews = [UIImageView]()
    var artworkViewConstraints = [NSLayoutConstraint]()
    // Must be an odd number
    let numberOfArtworkViews = 13
    var loadArtworkNumber = 0
    var peekPop: PeekPop!

    var currentArtworkView: UIImageView {
        return artworkViews[numberOfArtworkViews / 2]
    }

    var previousArtworkView: UIImageView {
        return artworkViews[numberOfArtworkViews / 2 - 1]
    }

    var nextArtworkView: UIImageView {
        return artworkViews[numberOfArtworkViews / 2 + 1]
    }

    // MARK: Setup View

    override func viewDidLoad() {
        view.addSubview(miniPlayerView)
        view.addSubview(minimizeButton)
        view.addSubview(volumeSlider)
        view.addSubview(timeSlider)

        infoHolderView.addSubview(songTitleLabel)
        infoHolderView.addSubview(albumTitleLabel)
        infoHolderView.addSubview(artistTitleLabel)
        view.addSubview(infoHolderView)

        view.addSubview(previousButton)
        view.addSubview(playPauseButton)
        view.addSubview(nextButton)

        artworkViewHolder.clipsToBounds = false
        artworkViewHolderViewHolder.addSubview(artworkViewHolder)

        artworkViewHolderViewHolder.clipsToBounds = true
        view.addSubview(artworkViewHolderViewHolder)

        for _ in 0..<numberOfArtworkViews {
            addArtwork(at: 0)
        }

        super.viewDidLoad()

        peekPop = PeekPop(viewController: self)
        peekPop.registerForPreviewingWithDelegate(self, sourceView: infoHolderView)
        peekPop.registerForPreviewingWithDelegate(self, sourceView: artworkViewHolder)

        KZPlayer.sharedInstance.audioSession.addObserver(self, forKeyPath: Constants.Observation.outputVolume, options: [.initial, .new], context: nil)

        NotificationCenter.default.addObserver(forName: .tintColorDidChange, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let self = self else {
                return
            }

            let color = AppDelegate.del().session.tintColor ?? .white
            self.timeSlider.progressTrackColor = color
            self.playPauseButton.tintColor = color
            self.previousButton.tintColor = color
            self.nextButton.tintColor = color
        }

        NotificationCenter.default.addObserver(forName: .songDidChange, object: nil, queue: .main) { [weak self] _ in
            guard let self = self, let song = KZPlayer.sharedInstance.itemForChannel(allowUpNext: true)  else {
                return
            }

            self.songTitleLabel.text = song.title
            self.albumTitleLabel.text = song.albumName()
            self.artistTitleLabel.text = song.artistName()

            UIView.performWithoutAnimation {
                self.miniPlayerView.songTitleLabel.text = song.title
                self.miniPlayerView.subTitleLabel.text = song.subtitleText()
            }
            if self.currentArtworkView.image == nil {
                self.loadArtwork()
            }
        }

        NotificationCenter.default.addObserver(forName: .didStartNewCollection, object: nil, queue: .main) { [weak self] _ in
            guard let self = self, self.currentArtworkView.image != nil else {
                return
            }

            self.loadArtwork()
        }

        NotificationCenter.default.addObserver(forName: .didAddUpNext, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.loadArtwork()
        }

        NotificationCenter.default.addObserver(forName: .nextSongDidPlay, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.goToNextArtwork()
        }

        NotificationCenter.default.addObserver(forName: .previousSongDidPlay, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.goToPreviousArtwork()
        }

        NotificationCenter.default.addObserver(forName: .playStateDidChange, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.playPauseButton.setImage(KZPlayer.sharedInstance.audioEngine.isRunning ? .pause : .play, for: .normal)
            self?.miniPlayerView.playPauseButton.setImage(KZPlayer.sharedInstance.audioEngine.isRunning ? .pause : .play, for: .normal)
        }

        KZPlayer.sharedInstance.currentTimeObservationHandler = { [weak self] currentTime, duration in
            DispatchQueue.main.async {
                self?.timeSlider.progress = CGFloat(currentTime / duration)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        volumeSlider.progress = CGFloat(KZPlayer.sharedInstance.systemVolume)
    }

    override func setupConstraints() {
        super.setupConstraints()

        miniPlayerView.autoPinEdge(toSuperviewEdge: .left)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .right)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .top)

        minimizeButton.autoPinEdge(.top, to: .bottom, of: miniPlayerView, withOffset: 30)
        minimizeButton.autoAlignAxis(toSuperviewAxis: .vertical)

        artworkViewHolderViewHolder.autoPinEdge(.top, to: .bottom, of: minimizeButton, withOffset: 18)
        artworkViewHolderViewHolder.autoPinEdge(toSuperviewEdge: .left)
        artworkViewHolderViewHolder.autoPinEdge(toSuperviewEdge: .right)
        artworkViewHolder.autoAlignAxis(toSuperviewAxis: .vertical)
        artworkViewHolder.autoMatch(.width, to: .width, of: artworkViewHolderViewHolder, withMultiplier: 0.9)

        resetArtwork()

        timeSlider.autoPinEdge(.top, to: .bottom, of: artworkViewHolderViewHolder, withOffset: 18)
        timeSlider.autoMatch(.width, to: .width, of: view, withMultiplier: 0.9)
        timeSlider.autoAlignAxis(toSuperviewAxis: .vertical)

        infoHolderView.autoPinEdge(.top, to: .bottom, of: timeSlider, withOffset: 18)
        infoHolderView.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        infoHolderView.autoPinEdge(toSuperviewEdge: .right, withInset: 18)

        songTitleLabel.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)

        albumTitleLabel.autoPinEdge(.top, to: .bottom, of: songTitleLabel, withOffset: 9)
        albumTitleLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 0)
        albumTitleLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 0)

        artistTitleLabel.autoPinEdge(.top, to: .bottom, of: albumTitleLabel, withOffset: 9)
        artistTitleLabel.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        artistTitleLabel.autoMatch(.height, to: .height, of: albumTitleLabel)

        playPauseButton.autoSetDimension(.height, toSize: 80)
        previousButton.autoSetDimension(.height, toSize: 70)
        nextButton.autoSetDimension(.height, toSize: 70)

        playPauseButton.autoPinEdge(.top, to: .bottom, of: infoHolderView, withOffset: 18)
        playPauseButton.autoAlignAxis(toSuperviewAxis: .vertical)

        previousButton.autoPinEdge(.right, to: .left, of: playPauseButton, withOffset: -60)
        previousButton.autoAlignAxis(.horizontal, toSameAxisOf: playPauseButton)

        nextButton.autoPinEdge(.left, to: .right, of: playPauseButton, withOffset: 60)
        nextButton.autoAlignAxis(.horizontal, toSameAxisOf: playPauseButton)

        volumeSlider.autoPinEdge(.top, to: .bottom, of: playPauseButton, withOffset: 18)
        volumeSlider.autoPinEdge(toSuperviewEdge: .left, withInset: 18)
        volumeSlider.autoPinEdge(toSuperviewEdge: .right, withInset: 18)
        volumeSlider.autoPinEdge(toSuperviewEdge: .bottom, withInset: 18)
    }

    func previewingContext(_ previewingContext: PreviewingContext, viewForLocation location: CGPoint) -> UIView? {
        guard let item = KZPlayer.sharedInstance.itemForChannel(allowUpNext: true) else {
            return nil
        }

        return PopupMenuItemView(item: item, exclude: [.play]) { action in
            switch action {
            case .addUpNext:
                KZPlayer.sharedInstance.addUpNext(item.originalItem)
            case .goToArtist:
                guard let artist = item.artist else {
                    return
                }
                let vc = ArtistViewController(artist: artist)
                MPContainerViewController.sharedInstance.currentNavigationController?.pushViewController(vc, animated: true)
                MPContainerViewController.sharedInstance.playerViewStyle = .mini
            case .goToAlbum:
                guard let album = item.album else {
                    return
                }
                let vc = AlbumViewController(album: album)
                MPContainerViewController.sharedInstance.currentNavigationController?.pushViewController(vc, animated: true)
                MPContainerViewController.sharedInstance.playerViewStyle = .mini
            default:
                break
            }
        }
    }

    func appendArtwork() -> UIImageView {
        return addArtwork(at: artworkViews.count)
    }

    @discardableResult
    func addArtwork(at index: Int) -> UIImageView {
        let artworkView = UIImageView()
        artworkView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.7)
        artworkViewHolder.addSubview(artworkView)
        artworkViews.insert(artworkView, at: index)
        return artworkView
    }

    func resetArtwork() {
        for i in 0..<artworkViews.count {
            let artworkView = artworkViews[i]
            if artworkView == currentArtworkView {
                artworkViewConstraints.append(contentsOf: artworkView.autoPinEdgesToSuperviewEdges())
            } else {
                artworkViewConstraints.append(artworkView.autoAlignAxis(.horizontal, toSameAxisOf: currentArtworkView))
                artworkViewConstraints.append(artworkView.autoMatch(.width, to: .width, of: currentArtworkView, withMultiplier: 0.8))
            }
            artworkViewConstraints.append(artworkView.autoMatch(.height, to: .width, of: artworkView))

            if i > 0 {
                let prevArtworkView = artworkViews[i - 1]
                artworkViewConstraints.append(artworkView.autoPinEdge(.left, to: .right, of: prevArtworkView, withOffset: 18))
            }
        }
    }

    func goToNextArtwork() {
        let firstArtwork = artworkViews.removeFirst()
        firstArtwork.removeFromSuperview()
        let newArtwork = self.appendArtwork()
        newArtwork.isHidden = true

        UIView.animate(withDuration: 1, delay: 0.0, options: [.beginFromCurrentState], animations: {
            self.artworkViewConstraints.forEach { $0.autoRemove() }
            self.artworkViewConstraints.removeAll()
            self.resetArtwork()
            self.view.layoutIfNeeded()
        }) { _ in
            newArtwork.isHidden = false
            self.loadArtwork()
        }
    }

    func goToPreviousArtwork() {
        let lastArtwork = artworkViews.removeLast()
        lastArtwork.removeFromSuperview()
        let newArtwork = self.addArtwork(at: 0)
        newArtwork.isHidden = true

        UIView.animate(withDuration: 1, delay: 0.0, options: [.beginFromCurrentState], animations: {
            self.artworkViewConstraints.forEach { $0.autoRemove() }
            self.artworkViewConstraints.removeAll()
            self.resetArtwork()
            self.view.layoutIfNeeded()
        }) { _ in
            newArtwork.isHidden = false
            self.loadArtwork()
        }
    }

    func loadArtwork() {
        guard let song = KZPlayer.sharedInstance.itemForChannel(allowUpNext: true) else {
            return
        }

        loadArtworkNumber += 1
        let currentNumber = loadArtworkNumber
        currentArtworkView.setImage(with: song)
        let centerIndex = artworkViews.firstIndex(of: currentArtworkView)!

        for i in 0..<centerIndex {
            guard let song = KZPlayer.sharedInstance.previouslyPlayedItem(index: i) else {
                break
            }

            artworkViews[centerIndex - 1 - i].setImage(with: song) {
                return currentNumber == self.loadArtworkNumber
            }
        }

        for i in 0..<centerIndex {
            guard let song = KZPlayer.sharedInstance.nextSong(index: i, forPlay: false) else {
                break
            }

            artworkViews[centerIndex + 1 + i].setImage(with: song) {
                return currentNumber == self.loadArtworkNumber
            }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == nil, keyPath == Constants.Observation.outputVolume, let volume = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)?.floatValue else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }

        volumeSlider.progress = CGFloat(volume)
    }

}
