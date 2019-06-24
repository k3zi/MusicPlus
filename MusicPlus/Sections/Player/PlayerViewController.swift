//
//  PlayerViewController.swift
//  Music+
//
//  Created by kezi on 2018/10/27.
//  Copyright © 2018 Kesi Maduka. All rights reserved.
//

import Combine
import UIKit
import RxSwift

class PlayerViewController: MPViewController, PeekPopPreviewingDelegate {

    static let shared = PlayerViewController()

    let disposeBag = DisposeBag()
    var cancellables = [AnyCancellable]()

    lazy var minimizeButton: ExtendedButton = {
        let view = ExtendedButton()
        view.setImage(Images.chevronDown, for: .normal)
        view.tintColor = Colors.minimizeButton
        view.addTarget(MPContainerViewController.sharedInstance, action: #selector(MPContainerViewController.minimizePlayer), for: .touchUpInside)
        view.imageView?.contentMode = .scaleAspectFit
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        return view
    }()

    lazy var volumeSlider: SliderView = {
        let view = SliderView()
        view.backgroundTrackColor = UIColor.white.withAlphaComponent(0.3)
        view.progressTrackColor = .white
        view.innerScrubberColor = .white
        view.outerScrubberColor = UIColor.white.withAlphaComponent(0.2)
        view.updateWhenOffScreen = true
        cancellables += view.progress
            .map { Float($0) }
            .sink {
                KZPlayer.sharedInstance.systemVolume = $0
            }

        return view
    }()

    lazy var timeSlider: SliderView = {
        let view = SliderView()
        view.backgroundTrackColor = UIColor.white.withAlphaComponent(0.3)
        view.progressTrackColor = AppDelegate.del().session.tintColor ?? .white
        view.innerScrubberColor = .white
        view.outerScrubberColor = UIColor.white.withAlphaComponent(0.2)
        cancellables += view.userDidUpdate
            .map { Double($0) * KZPlayer.sharedInstance.duration() }
            .sink {
                KZPlayer.sharedInstance.setCurrentTime($0)
            }
        return view
    }()

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
        view.setImage(Images.play, for: .normal)
        view.addTarget(KZPlayer.sharedInstance, action: #selector(KZPlayer.togglePlay), for: .touchUpInside)
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()

    lazy var previousButton: UIButton = {
        let view = ExtendedButton()
        view.tintColor = AppDelegate.del().session.tintColor ?? .white
        view.setImage(Images.previous, for: .normal)
        view.addTarget(KZPlayer.sharedInstance, action: #selector(KZPlayer.prev), for: .touchUpInside)
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()

    lazy var nextButton: UIButton = {
        let view = ExtendedButton()
        view.tintColor = AppDelegate.del().session.tintColor ?? .white
        view.setImage(Images.next, for: .normal)
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

    let contentStackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        artworkViewHolder.translatesAutoresizingMaskIntoConstraints = false
        artworkViewHolder.clipsToBounds = false
        artworkViewHolderViewHolder.addSubview(artworkViewHolder)

        artworkViewHolderViewHolder.clipsToBounds = true

        for _ in 0..<numberOfArtworkViews {
            addArtwork(at: 0)
        }

        let controlsStackView = UIStackView(arrangedSubviews: [previousButton, playPauseButton, nextButton])
        controlsStackView.spacing = CGFloat.goo.systemSpacing(multiplier: 7)
        controlsStackView.alignment = .center

        let currentPlayingInfoStackView = UIStackView(arrangedSubviews: [
            songTitleLabel,
            albumTitleLabel,
            artistTitleLabel
        ])
        currentPlayingInfoStackView.axis = .vertical
        currentPlayingInfoStackView.spacing = CGFloat.goo.systemSpacing

        let volumeMuteImageView = UIImageView(image: Images.volumeMute)
        volumeMuteImageView.contentMode = .scaleAspectFit
        volumeMuteImageView.tintColor = Colors.volumeLevelAccessory
        let volumeHighImageView = UIImageView(image: Images.volumeHigh)
        volumeHighImageView.contentMode = .scaleAspectFit
        volumeHighImageView.tintColor = Colors.volumeLevelAccessory

        let volumeSliderStackView = UIStackView(arrangedSubviews: [
            volumeMuteImageView,
            volumeSlider,
            volumeHighImageView
        ])
        volumeSliderStackView.spacing = CGFloat.goo.systemSpacing(multiplier: 0.5)

        let detailsStackView = UIStackView(arrangedSubviews: [
            timeSlider,
            currentPlayingInfoStackView,
            controlsStackView,
            volumeSliderStackView
        ])
        detailsStackView.axis = .vertical
        detailsStackView.alignment = .center
        detailsStackView.distribution = .equalSpacing
        detailsStackView.spacing = CGFloat.goo.systemSpacing(multiplier: 2)
        detailsStackView.isLayoutMarginsRelativeArrangement = true
        detailsStackView.layoutMargins = UIEdgeInsets.goo.systemSpacingInsets(top: 0, left: 1, bottom: 0, right: 1)

        contentStackView.addArrangedSubview(artworkViewHolderViewHolder)
        contentStackView.addArrangedSubview(detailsStackView)
        contentStackView.axis = .vertical

        let stackView = UIStackView(arrangedSubviews: [
            minimizeButton,
            contentStackView
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = CGFloat.goo.systemSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets.goo.systemSpacingInsets(top: 1, left: 0, bottom: 2, right: 0)
        view.addSubview(stackView)
        stackView.goo.boundingAnchor.makeRelativeEdges(equalTo: view.safeAreaLayoutGuide).activate()

        NSLayoutConstraint.goo.activate([
            contentStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            timeSlider.leadingAnchor.constraint(equalToSystemSpacingAfter: detailsStackView.leadingAnchor, multiplier: 1),
            volumeSliderStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: detailsStackView.leadingAnchor, multiplier: 1),
            minimizeButton.widthAnchor.constraint(equalToConstant: CGFloat.goo.touchTargetDimension / 2),
            minimizeButton.heightAnchor.constraint(equalTo: minimizeButton.widthAnchor),

            volumeMuteImageView.widthAnchor.constraint(equalTo: volumeHighImageView.widthAnchor),

            playPauseButton.heightAnchor.constraint(equalToConstant: CGFloat.goo.touchTargetDimension * 2),
            playPauseButton.widthAnchor.constraint(equalTo: playPauseButton.heightAnchor),
            previousButton.heightAnchor.constraint(equalTo: playPauseButton.heightAnchor, multiplier: 0.5),
            nextButton.heightAnchor.constraint(equalTo: previousButton.heightAnchor),
            previousButton.widthAnchor.constraint(equalTo: previousButton.heightAnchor),
            nextButton.widthAnchor.constraint(equalTo: nextButton.heightAnchor)
        ])

        peekPop = PeekPop(viewController: self)
        peekPop.registerForPreviewingWithDelegate(self, sourceView: currentPlayingInfoStackView)
        peekPop.registerForPreviewingWithDelegate(self, sourceView: artworkViewHolder)

        cancellables += KZPlayer.sharedInstance.audioSession.publisher(for: \.outputVolume)
            .receive(on: RunLoop.main)
            .map {
                CGFloat($0)
            }
            .subscribe(volumeSlider.progress)

        NotificationCenter.default.addObserver(forName: .tintColorDidChange, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let self = self else {
                return
            }

            let color = AppDelegate.del().session.tintColor ?? .white
            self.timeSlider.progressTrackColor = color
            self.playPauseButton.tintColor = color
            self.previousButton.tintColor = color
            self.nextButton.tintColor = color
        }.dispose(with: self)

        NotificationCenter.default.addObserver(forName: .songDidChange, object: nil, queue: .main) { [weak self] _ in
            guard let self = self, let song = KZPlayer.sharedInstance.itemForChannel(allowUpNext: true)  else {
                return
            }

            self.songTitleLabel.text = song.title
            self.albumTitleLabel.text = song.albumName
            self.artistTitleLabel.text = song.artistName

            if self.currentArtworkView.image == nil {
                self.loadArtwork()
            }
        }.dispose(with: self)

        NotificationCenter.default.addObserver(forName: .didStartNewCollection, object: nil, queue: .main) { [weak self] _ in
            guard let self = self, self.currentArtworkView.image != nil else {
                return
            }

            self.loadArtwork()
        }.dispose(with: self)

        NotificationCenter.default.addObserver(forName: .didAddUpNext, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.loadArtwork()
        }.dispose(with: self)

        NotificationCenter.default.addObserver(forName: .nextSongDidPlay, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.goToNextArtwork()
        }.dispose(with: self)

        NotificationCenter.default.addObserver(forName: .previousSongDidPlay, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.goToPreviousArtwork()
        }.dispose(with: self)

        NotificationCenter.default.addObserver(forName: .playStateDidChange, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.playPauseButton.setImage(KZPlayer.sharedInstance.audioEngine.isRunning ? Images.pause : Images.play, for: .normal)
        }.dispose(with: self)

        cancellables += KZPlayer.sharedInstance.currentTime
            .receive(on: DispatchQueue.global(qos: .background))
            .map {
                $0.flatMap { CGFloat($0.currentTime / $0.duration) }
            }
            .filter { $0 != nil }.map { min(max($0!, 0), 1) }
            .subscribe(timeSlider.progress)
    }

    deinit {
        disposeAll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        volumeSlider.progress.send(CGFloat(KZPlayer.sharedInstance.systemVolume))
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.layoutIfNeeded()
    }

    override func setupConstraints() {
        super.setupConstraints()

        minimizeButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        artworkViewHolderViewHolder.setContentCompressionResistancePriority(.required, for: .vertical)

        artworkViewHolder.autoAlignAxis(toSuperviewAxis: .vertical)
        artworkViewHolder.autoAlignAxis(toSuperviewAxis: .horizontal)
        artworkViewHolder.autoMatch(.width, to: .width, of: artworkViewHolderViewHolder, withMultiplier: 0.85)

        resetArtwork()

        setupTraitSpecificConstraints()
    }

    func setupTraitSpecificConstraints() {
        if traitCollection.horizontalSizeClass == .compact {
            contentStackView.axis = .vertical
        } else {
            contentStackView.axis = .horizontal
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupTraitSpecificConstraints()
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
        artworkView.translatesAutoresizingMaskIntoConstraints = false
        artworkView.backgroundColor = nil
        artworkView.contentMode = .scaleAspectFit
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
        guard UIView.isVisible(view: view) else {
            self.loadArtwork()
            return
        }

        let firstArtwork = artworkViews.removeFirst()
        firstArtwork.removeFromSuperview()
        let newArtwork = self.appendArtwork()
        newArtwork.isHidden = true

        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.beginFromCurrentState], animations: {
            self.artworkViewConstraints.forEach { $0.autoRemove() }
            self.artworkViewConstraints.removeAll()
            self.resetArtwork()
            self.view.layoutIfNeeded()
        }, completion: { _ in
            newArtwork.isHidden = false
            self.loadArtwork()
        })
    }

    func goToPreviousArtwork() {
        guard UIView.isVisible(view: view) else {
            self.loadArtwork()
            return
        }

        let lastArtwork = artworkViews.removeLast()
        lastArtwork.removeFromSuperview()
        let newArtwork = self.addArtwork(at: 0)
        newArtwork.isHidden = true

        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.beginFromCurrentState], animations: {
            self.artworkViewConstraints.forEach { $0.autoRemove() }
            self.artworkViewConstraints.removeAll()
            self.resetArtwork()
            self.view.layoutIfNeeded()
        }, completion: { _ in
            newArtwork.isHidden = false
            self.loadArtwork()
        })
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

}
