// 
//  self.swift
//  KZPlayer
// 
//  Created by Kesi Maduka on 10/24/15.
//  Copyright © 2015 Storm Edge Apps LLC. All rights reserved.
// 
// swiftlint:disable force_try

import UIKit
import AVFoundation
import Accelerate
import Alamofire
import AlamofireImage
import MediaPlayer
import CoreSpotlight
import MobileCoreServices

import RealmSwift
import PRTween
import SceneKit

// MARK: Settings

struct Settings {
    var repeatMode: KZPLayerRepeatMode = .repeatAll
    var shuffleMode: KZPLayerShuffleMode = .noShuffle
    var crossfade: Bool {
        return UserDefaults.standard.bool(forKey: Constants.Settings.crossfade)
    }
    var crossfadeAtSeconds: Double {
        return max(UserDefaults.standard.double(forKey: Constants.Settings.crossfadeAtSeconds), Constants.Settings.Options.crossfadeAtSeconds[0])
    }
    var crossfadeDurationSeconds: Double {
        return max(UserDefaults.standard.double(forKey: Constants.Settings.Info.crossfadeDurationSeconds.accessor), Constants.Settings.Options.crossfadeDurationSeconds[0])
    }
    var crossfadeOnNext: Bool {
        return UserDefaults.standard.bool(forKey: Constants.Settings.Info.crossfadeOnNext.accessor)
    }
    var crossfadeOnPrevious: Bool {
        return UserDefaults.standard.bool(forKey: Constants.Settings.Info.crossfadeOnPrevious.accessor)
    }
    var upNextPreserve: Bool {
        return UserDefaults.standard.bool(forKey: Constants.Settings.Info.upNextPreserve.accessor)
    }
}

enum KZPlayerState {
    case starting
    case ready
    case playing
    case paused
}

enum KZPLayerRepeatMode {
    case noRepeat
    case repeatSong
    case repeatAll
}

enum KZPLayerShuffleMode {
    case noShuffle
    case shuffle
}

enum KZPLayerCrossFadeMode {
    case noCrossfade
    case crossfade
}

// MARK: Main Player
class KZPlayer: NSObject {
    static let sharedInstance = KZPlayer()
    static let libraryQueue = DispatchQueue(label: "io.kez.musicplus.librarythread", qos: .userInitiated, attributes: .concurrent)
    static let uiQueue = DispatchQueue(label: "io.kez.musicplus.uithread", qos: .userInteractive, attributes: .concurrent)
    static let analysisQueue = DispatchQueue(label: "io.kez.musicplus.analysis", qos: .background, attributes: .concurrent)
    static var activeWorkers = [BackgroundWorker]()

    static let libraryQueueKey = DispatchSpecificKey<Void>()

    /// ------- Player ------- ///
    var audioEngine: AVAudioEngine
    var shouldBeRunning = false
    var audioSession: AVAudioSession
    var audioSessionNotifications = [NSObjectProtocol]()
    var auPlayerSets = [Int: KZAudioPlayerSet]()
    var auMixer: AVAudioMixerNode

    var activePlayer = -1

    var itemBeforeUpNextKey: String?
    var cachedActiveItemKey: String?
    var cachedActiveItem: KZPlayerHistoryItem?

    /// These are tokens that obsevre the current queue's original collections and update them accordingly.
    var currentQueueNotificationTokens = [NotificationToken]()

    var settings = Settings()
    var state = KZPlayerState.starting

    var checkTimeFunctioning = false

    var crossfading = false
    var crossfadeCount = 0

    // Volume
    var averagePower: Float = 0.0
    var volumeView = MPVolumeView()

    var currentTimeObservationHandler: ((_ currentTime: Double, _ duration: Double) -> Void)?

    // Library
    var currentLibrary: KZLibrary? {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Constants.Notification.libraryDidChange, object: nil)
            }

            DispatchQueue.global(qos: .background).async {
                self.currentLibrary?.refresh()
            }
        }
    }

    override init() {
        audioEngine = AVAudioEngine()
        auMixer = audioEngine.mainMixerNode
        audioSession = AVAudioSession.sharedInstance()

        KZPlayer.libraryQueue.setSpecific(key: KZPlayer.libraryQueueKey, value: ())

        super.init()

        DispatchQueue.main.async {
            self.setUpAudioSession()
            self.setupEngine()
            self.state = .ready
        }
    }

    static var sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        return SessionManager(configuration: configuration)
    }()

    open class func imageDownloaderConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default

        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.httpShouldSetCookies = true
        configuration.httpShouldUsePipelining = true

        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.allowsCellularAccess = true
        configuration.timeoutIntervalForRequest = 60

        configuration.urlCache = URLCache(memoryCapacity: 400 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024, diskPath: "io.kez.musicplus.imagecache")

        return configuration
    }

    static var imageDownloader: ImageDownloader = {
        return ImageDownloader(configuration: KZPlayer.imageDownloaderConfiguration(), downloadPrioritization: .lifo, maximumActiveDownloads: 20)
    }()
}

// MARK: Session / Remote / Now Playing
extension KZPlayer {

    func setupEngine() {
        let format = auMixer.inputFormat(forBus: 0)

        auMixer.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, _) -> Void in
            buffer.frameLength = AVAudioFrameCount(1024)
            let inNumberFrames = UInt(buffer.frameLength)
            if let samples = buffer.floatChannelData?[0] {
                var avgValue: Float = 0.0
                vDSP_meamgv(samples, 1, &avgValue, inNumberFrames)
                self.averagePower = Float(avgValue / 1.0)
            }

            DispatchQueue.mainSyncSafe {
                self.checkTime()
            }
        }

        #if !targetEnvironment(simulator)
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine")
        }
        #endif
    }

    func addPlayerSet(bus: Int, item: KZPlayerItemBase) -> KZAudioPlayerSet {
        let set = KZAudioPlayerSet(item: item.originalItem)
        let format = auMixer.inputFormat(forBus: 0)

        for unit in [set.auPlayer, set.auEqualizer, set.auSpeed] as [AVAudioNode] {
            audioEngine.attach(unit)
        }

        audioEngine.connect(set.auPlayer, to: set.auSpeed, format: format)
        audioEngine.connect(set.auSpeed, to: set.auEqualizer, format: format)
        audioEngine.connect(set.auEqualizer, to: auMixer, fromBus: 0, toBus: bus, format: format)

        set.volume = 0.0

        return set
    }

    func setUpAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            let ioBufferDuration = 128.0 / 44100.0
            try audioSession.setPreferredIOBufferDuration(ioBufferDuration)
            try audioSession.setActive(true)
        } catch {
            print("Error starting audio sesssion")
        }

        audioSessionNotifications.forEach(NotificationCenter.default.removeObserver)

        audioSessionNotifications.append(NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: OperationQueue.main) { _ in
            self.pause()
        })

        audioSessionNotifications.append(NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: OperationQueue.main) { notification in
            guard let reasonInt = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt, let reason = AVAudioSession.RouteChangeReason(rawValue: reasonInt) else {
                return
            }

            if self.audioEngine.isRunning {
                self.pause()
                switch reason {
                case .oldDeviceUnavailable:
                    self.shouldBeRunning = false
                    break
                default:
                    self.resume()
                }
            }
        })

        audioSessionNotifications.append(NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: OperationQueue.main) { notification in
            guard let notifyingEngine = notification.object as? AVAudioEngine, notifyingEngine == self.audioEngine else {
                return
            }

            if self.shouldBeRunning {
                self.setUpAudioSession()
                self.pause()
                self.resume()
            }
        })

        volumeView.frame = CGRect(x: -2000, y: -2000, width: 0, height: 0)
        volumeView.alpha = 0.1
        volumeView.clipsToBounds = true

        volumeView.isUserInteractionEnabled = false

        if let window = UIApplication.shared.windows.first {
            window.addSubview(volumeView)
        }

        AppDelegate.del().window?.addSubview(volumeView)

        MPRemoteCommandCenter.shared().playCommand.addTarget(self, action: #selector(resume))
        MPRemoteCommandCenter.shared().pauseCommand.addTarget(self, action: #selector(pause))
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget(self, action: #selector(next))
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget(self, action: #selector(prev))
        // MPRemoteCommandCenter.sharedCommandCenter().likeCommand.addTarget(self, action: #selector(self.toggleLike))
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { event -> MPRemoteCommandHandlerStatus in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            return self.setCurrentTime(event.positionTime) ? .success : .commandFailed
        }

        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = true
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = true
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.isEnabled = true
    }

    func updateNowPlayingInfo(_ item: KZPlayerItem) {
        guard !item.isInvalidated else {
            return
        }

        let center = MPNowPlayingInfoCenter.default()

        autoreleasepool {
            var dict = [String: Any]()
            dict[MPMediaItemPropertyTitle] = item.title
            dict[MPMediaItemPropertyArtist] = item.artistName()
            dict[MPMediaItemPropertyAlbumTitle] = item.album?.name ?? ""
            dict[MPMediaItemPropertyPlaybackDuration] = item.endTime - item.startTime
            dict[MPNowPlayingInfoPropertyPlaybackRate] = audioEngine.isRunning ? 1.0 : 0.0
            dict[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime(item: item)
            if #available(iOS 10.0, *) {
                dict[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
            }

            let systemID = item.systemID
            item.fetchArtwork { artwork in
                let delegate = AppDelegate.del()
                center.nowPlayingInfo = dict
                DispatchQueue.global(qos: .background).async {
                    guard let currentItem = self.itemForChannel(), systemID == currentItem.systemID else {
                        return
                    }

                    dict[MPMediaItemPropertyArtwork] = artwork
                    DispatchQueue.main.async {
                        center.nowPlayingInfo = dict
                    }

                    if let image = artwork.image(at: Constants.UI.Screen.bounds.size) {
                        delegate.session.tintColor = ObjectiveCProcessing.getDominatingColor(image)
                        delegate.session.backgroundImage = image
                    } else {
                        delegate.session.tintColor = nil
                        delegate.session.backgroundImage = nil
                    }
                }
            }
        }
    }

    func toggleLike() {
        guard let item = itemForChannel() else {
            return
        }

        if item.liked {
            unLikeItem(item)
        } else {
            likeItem(item)
        }

        // MPRemoteCommandCenter.sharedCommandCenter().likeCommand.active = item.liked
    }
}

// MARK: Settings
extension KZPlayer {

    /// Adjusts the settings to reflect the passed in value
    ///
    /// - Parameter inSetting: the new shuffle setting or null if unchanged
    /// - Returns: whether the mode is .shuffle after the reflected changes
    func setShuffle(_ inSetting: Bool? = nil) -> Bool {
        guard let inSetting = inSetting else {
            return settings.shuffleMode == .shuffle
        }

        settings.shuffleMode = inSetting ? .shuffle : .noShuffle
        return inSetting
    }

}

// MARK: - Basic Functions
extension KZPlayer {

    class func executeOn(queue: DispatchQueue, event: @escaping () -> Void) {
        queue.async {
            let timer = BackgroundWorker()
            timer.start {
                event()
                self.activeWorkers.remove(object: timer)
                timer.stop()
            }
            self.activeWorkers.append(timer)
        }
    }

    // MARK: Play

    /// Plays the provided items
    ///
    /// - Parameters:
    ///   - items: the collection of items that will replavethe current collection
    ///   - initialSong: the first song to play, if nil then it will be the first item in `items`
    ///   - shuffle: whether to shuffle the items, nil ensures that the previous value is used
    func play(_ items: KZPlayerItemCollection, initialSong: KZPlayerItem? = nil, shuffle: Bool? = nil) {
        resetPlayer()

        let shuffle = setShuffle(shuffle)
        setCollection(items, initialSong: initialSong, shuffle: shuffle)

        var index = 0
        if !shuffle, let initialSong = initialSong {
            // If we are browsing the collection as normal and the initial
            // song was specified then let's find it's index

            // `setCollection` guarantees that if we shuffle then the `initialSong`
            // will be the first
            index = items.index(of: initialSong) ?? 0
        }

        let collection: [KZPlayerItemBase] = shuffle ? Array(sessionShuffledQueue()) : Array(sessionQueue())

        guard collection.count > 0 else {
            return
        }

        persistentPlayNextSong(collection[index], times: collection.count, shouldCrossfadeOnSkip: settings.crossfadeOnNext)
    }

    // Play Single Item
    func play(_ item: KZPlayerItemBase, silent: Bool = false, isQueueItem: Bool = false, tempo customTempo: Double? = nil) -> Bool {
        guard DispatchQueue.getSpecific(key: KZPlayer.libraryQueueKey) != nil else {
            let threadSafeItem = KZThreadSafeReference(to: item.originalItem)
            return KZPlayer.libraryQueue.sync {
                guard let item = threadSafeItem.resolve() else {
                    return false
                }
                return self.play(item, silent: silent, isQueueItem: isQueueItem)
            }
        }

        let channel = rotateChannelInt()
        let playerSet = addPlayerSet(bus: channel, item: item)
        auPlayerSets[channel] = playerSet
        print("will attempt to play \(item.title) on channel \(channel)")

        let tempo = customTempo ?? item.tempo

        if !audioEngine.isRunning {
            try? audioEngine.start()
        }

        print("activePlayer = \(channel)")
        activePlayer = channel

        if silent {
            playerSet.volume = 0.0
        } else {
            playerSet.volume = 1.0
        }

        setSpeed(AudioUnitParameterValue(tempo), channel: channel)

        playerSet.schedule { () -> Void in
            DispatchQueue.main.async {
               self.playerCompleted(channel)
            }
        }

        if !isQueueItem {
            setItemForChannel(item)
        }

        let threadSafeItem = KZThreadSafeReference(to: item.originalItem)
        KZPlayer.executeOn(queue: KZPlayer.analysisQueue) {
            threadSafeItem.resolve()?.analyzeAudio()
        }

        playerSet.play()
        print("started playing \"\(item.title)\" on channel: \(channel)")
        updateNowPlayingInfo(item.originalItem)
        return true
    }

    @objc func resume() {
        do {
            try audioEngine.start()
            auPlayerSets.forEach { $0.value.play() }

            if let item = itemForChannel() {
                updateNowPlayingInfo(item)
            }
        } catch {
            print("Error starting audio engine")
        }
        print("player did resume")
        shouldBeRunning = true
    }

    @objc func pause() {
        print("player pause called")
        guard audioEngine.isRunning else {
            return
        }

        auPlayerSets.forEach { $0.value.pause() }
        audioEngine.pause()
        print("player paused")
        shouldBeRunning = false
    }

    func togglePlay() {
        if audioEngine.isRunning {
            pause()
        } else {
            resume()
        }
    }

    @objc func next() {
        playerCompleted(activePlayer, force: true, shouldCrossfadeOnSkip: settings.crossfadeOnNext)
    }

    func backgroundNext() {
        DispatchQueue.mainSyncSafe {
            self.playerCompleted(activePlayer, force: true)
        }
    }

    @objc func prev() -> Bool {
        guard let prevItem = prevSong() else {
            return false
        }

        print("previous = \(prevItem.title)")

        if settings.crossfade && settings.crossfadeOnPrevious {
            return crossfadeTo(prevItem)
        }

        stopCrossfade()
        let result = play(prevItem)

        for channel in auPlayerSets.keys where channel != activePlayer {
            removeChannel(channel: channel)
        }

        return result
    }

    func setSpeed(_ value: AudioUnitParameterValue, channel: Int = -1) {
        speedNodeForChannel(channel)?.rate = value
    }

    var systemVolume: Float {
        set {
            if volumeView.superview == nil {
                AppDelegate.del().window?.addSubview(volumeView)
            }
            volumeView.superview?.bringSubviewToFront(volumeView)

            guard let view = volumeView.subviews.filter({ $0 is UISlider }).first as? UISlider else {
                return
            }

            view.value = newValue
        }

        get {
            if let view = volumeView.subviews.first as? UISlider {
                return view.value
            }
            return 0.0
        }
    }

    private func volume(_ channel: Int = -1) -> Float {
        return setForChannel(channel)?.volume ?? 0.0
    }

    private func setVolume(_ value: Float, channel: Int = -1) {
        setForChannel(channel)?.volume = value
    }

    func currentTime(_ channel: Int = -1, item: KZPlayerItemBase? = nil) -> Double {
        guard let set = setForChannel(channel) else {
            return 0.0
        }

        return set.currentTime(item: item)
    }

    func duration(_ channel: Int = -1, item: KZPlayerItemBase? = nil) -> Double {
        guard let set = setForChannel(channel) else {
            return 0.0
        }

        return set.duration(item: item)
    }

    @discardableResult
    func setCurrentTime(_ value: Double, channel: Int = -1) -> Bool {
        guard let item = itemForChannel(channel) else {
            return false
        }

        if duration(item: item) <= value {
            next()
            return true
        }

        do {
            guard let set = setForChannel(channel) else {
                return false
            }
            try set.seek(to: value) {
                DispatchQueue.main.async {
                    self.playerCompleted(channel)
                }
            }
            updateNowPlayingInfo(item)
            return true
        } catch {
            return false
        }
    }

    func removeChannel(channel: Int) {
        guard let set = auPlayerSets[channel] else {
            return
        }

        DispatchQueue.global(qos: .background).async {
            set.isRemoved = true
            set.stop()
            for unit in [set.auPlayer, set.auEqualizer, set.auSpeed] as [AVAudioNode] {
                self.audioEngine.detach(unit)
            }
            self.auPlayerSets.removeValue(forKey: channel)
        }
    }

    func playerCompleted(_ channel: Int, force: Bool = false, shouldCrossfadeOnSkip: Bool = true) {
        // If the active channel has completed and we are still crossfading then either
        // the next player has not been set yet or there was an error and the active player
        // could not play.
        guard force || !crossfading || channel == activePlayer else {
            return
        }

        persistentPlayNextSong(shouldCrossfadeOnSkip: shouldCrossfadeOnSkip)
    }

    func persistentPlayNextSong(_ item: KZPlayerItemBase? = nil, times: Int = 1, shouldCrossfadeOnSkip: Bool = true) {
        var played = false
        var i = 0
        while !played && i < times {
            played = playNextSong(item, shouldCrossfadeOnSkip: shouldCrossfadeOnSkip)
            i += 1
        }
    }

    func playNextSong(_ item: KZPlayerItemBase? = nil, shouldCrossfadeOnSkip: Bool = true) -> Bool {
        guard let nextItem = item ?? rotateSongs() else {
            return true
        }

        let isQueueItem = nextItem is KZPlayerHistoryItem

        if !isQueueItem { // = Not an item that was added to the queue
            itemBeforeUpNextKey = nil
        } else if itemBeforeUpNextKey == nil {
            itemBeforeUpNextKey = itemForChannel(activePlayer)?.systemID
        }

        if settings.crossfade && shouldCrossfadeOnSkip {
            return crossfadeTo(nextItem)
        }

        for channel in auPlayerSets.keys {
            removeChannel(channel: channel)
        }

        stopCrossfade()
        return play(nextItem, isQueueItem: nextItem is KZPlayerHistoryItem)
    }
}

// MARK: crossfade Functions
extension KZPlayer {

    func checkTime() {
        var item: KZPlayerHistoryItem?
        guard let currentKey = primaryKeyForChannel() else {
            return
        }

        if let cachedKey = cachedActiveItemKey, cachedKey == currentKey {
            item = cachedActiveItem
        } else {
            cachedActiveItemKey = currentKey
            if let temp = itemForPrimaryKey(currentKey) {
                item = KZPlayerHistoryItem(orig: temp)
                cachedActiveItem = item
            }
        }

        guard let currentItem = item else {
            return
        }

        let currentTime = self.currentTime(item: currentItem)
        if !checkTimeFunctioning && settings.crossfade && !crossfading && (currentItem.endTime - currentTime) < settings.crossfadeAtSeconds {
            checkTimeFunctioning = true
            backgroundNext()
            checkTimeFunctioning = false
        }

        currentTimeObservationHandler?(currentTime, self.duration(item: currentItem))
    }

    func stopCrossfade() {
        guard crossfading else {
            return
        }

        crossfadeCount += 1
        PRTween.sharedInstance().removeAllTweenOperations()
        crossfading = false
    }

    func crossfadeTo(_ item: KZPlayerItemBase) -> Bool {
        stopCrossfade()
        print("crossfadeCount = \(crossfadeCount)")
        print("pre crossfading = \(crossfading)")
        let currentCFCount = crossfadeCount
        crossfading = true

        var fadeOutDelay: Double = 0.0
        var fadeInDelay: Double = 0.0
        var startBPM: Double = 0.0
        var endBPM: Double = 0.0
        var shouldMatchBPM = false
        var overrideTempo = 1.0

        // This should make the two playing sets start on the same beat
        if auPlayerSets.count == 1, let previousPlayer = auPlayerSets.first?.value, let oldItem = previousPlayer.itemReference.resolve() {
            let firstBeat = item.firstUnplayedBeat(currentTime: 0)
            fadeInDelay = firstBeat

            print("will delay crossfade in by: \(firstBeat)")

            let currentTime = previousPlayer.currentTime()
            let firstUnplayedBeat = oldItem.firstUnplayedBeat(currentTime: currentTime)
            fadeOutDelay = max(firstUnplayedBeat - currentTime, 0)

            print("first unplayed beat: \(firstUnplayedBeat)")
            print("will delay crossfade out by: \(fadeOutDelay)")
            shouldMatchBPM = true
            startBPM = oldItem.bpm
            endBPM = item.bpm
            overrideTempo = startBPM / endBPM
        }

        print("\n\n\n\n")
        print("start bpm = \(startBPM)")
        print("end bpm = \(endBPM)")

        guard play(item, silent: true, isQueueItem: item is KZPlayerHistoryItem, tempo: overrideTempo) else {
            crossfading = false
            return false
        }

        guard let p1 = playerForChannel() else {
            crossfading = false
            return false
        }

        let duration = CGFloat(settings.crossfadeDurationSeconds)
        guard let period1 = PRTweenPeriod.period(withStartValue: CGFloat(p1.volume), endValue: 1.0, duration: duration) as? PRTweenPeriod else {
             crossfading = false
            return false
        }
        period1.delay = CGFloat(fadeOutDelay)

        let operation1 = PRTweenOperation()
        operation1.period = period1
        operation1.target = self
        operation1.timingFunction = PRTweenTimingFunctionLinear
        operation1.updateBlock = { (p: PRTweenPeriod!) in
            guard currentCFCount == self.crossfadeCount else {
                return
            }

            p1.volume = Float(p.tweenedValue)
            if startBPM > 0, endBPM > 0 {
                let progress = abs(Double(p.tweenedValue / (p.endValue - p.startValue)))
                let deltaRatio = (endBPM / startBPM) - 1
                let speedValue = overrideTempo + (deltaRatio * progress)
                self.setSpeed(AudioUnitParameterValue(speedValue))
                print("setting new channel speed: \(speedValue)")
            }
        }
        operation1.completeBlock = { (completed: Bool) -> Void in
            if currentCFCount == self.crossfadeCount {
                self.crossfading = false
            }
        }

        let operation1BPM = PRTweenOperation()
        operation1BPM.period = (PRTweenPeriod.period(withStartValue: CGFloat(overrideTempo), endValue: 1.0, duration: duration) as! PRTweenPeriod)
        operation1BPM.period.duration = operation1.period.duration
        operation1BPM.period.delay = operation1.period.delay
        operation1BPM.timingFunction = operation1.timingFunction
        operation1BPM.updateBlock = { (p: PRTweenPeriod!) in
            guard currentCFCount == self.crossfadeCount else {
                return
            }
            self.setSpeed(AudioUnitParameterValue(p.tweenedValue))
            print("setting new channel speed: \(p.tweenedValue)")
        }

        for previousChannel in auPlayerSets.keys where previousChannel != activePlayer {
            guard let set = setForChannel(previousChannel) else {
                continue
            }
            let startValue = CGFloat(set.volume)
            guard let period2 = PRTweenPeriod.period(withStartValue: startValue, endValue: 0.0, duration: duration * startValue) as? PRTweenPeriod else {
                continue
            }
            period2.delay = CGFloat(fadeInDelay)

            let operation2 = PRTweenOperation()
            operation2.period = period2
            operation2.target = self
            operation2.timingFunction = PRTweenTimingFunctionLinear
            operation2.updateBlock = { (p: PRTweenPeriod!) in
                guard currentCFCount == self.crossfadeCount else {
                    return
                }

                set.volume = Float(p.tweenedValue)
            }
            operation2.completeBlock = { (completed: Bool) -> Void in
                guard currentCFCount == self.crossfadeCount else {
                    return
                }

                self.removeChannel(channel: previousChannel)
            }

            let operation2BPM = PRTweenOperation()
            operation2BPM.period = (PRTweenPeriod.period(withStartValue: 1.0, endValue: CGFloat(overrideTempo / 1), duration: duration) as! PRTweenPeriod)
            operation2BPM.period.duration = operation2.period.duration
            operation2BPM.period.delay = operation2.period.delay
            operation2BPM.timingFunction = operation2.timingFunction
            operation2BPM.updateBlock = { (p: PRTweenPeriod!) in
                guard currentCFCount == self.crossfadeCount else {
                    return
                }
                self.setSpeed(AudioUnitParameterValue(p.tweenedValue), channel: previousChannel)
                print("setting old channel speed: \(p.tweenedValue)")
            }

            PRTween.sharedInstance().add(operation2)
            PRTween.sharedInstance()?.add(operation2BPM)
        }

        PRTween.sharedInstance().add(operation1)
        PRTween.sharedInstance()?.add(operation1BPM)
        return true
    }
}

// MARK: Helper
extension KZPlayer {

    func rotateChannelInt() -> Int {
        activePlayer = 0

        while auPlayerSets.keys.contains(activePlayer) {
            activePlayer += 1
        }

        return activePlayer
    }

    func setForChannel(_ channel: Int = -1) -> KZAudioPlayerSet? {
        let channel = channel == -1 ? activePlayer : channel

        guard let set = auPlayerSets.filter({ $0.key == channel }).first?.value else {
            return nil
        }

        return set
    }

    func playerForChannel(_ channel: Int = -1) -> AVAudioPlayerNode? {
        return setForChannel(channel)?.auPlayer
    }

    func speedNodeForChannel(_ channel: Int = -1) -> AVAudioUnitTimePitch? {
        let channel = channel == -1 ? activePlayer : channel

        guard let set = auPlayerSets.filter({ $0.key == channel }).first?.value else {
            return nil
        }

        return set.auSpeed
    }

    func primaryKeyForChannel(_ channel: Int = -1) -> String? {
        guard let set = setForChannel(channel) else {
            return nil
        }

        guard let primaryKey = itemBeforeUpNextKey ?? set.itemKey else {
            return nil
        }

        return primaryKey
    }

    func itemForChannel(_ channel: Int = -1) -> KZPlayerItem? {
        guard let primaryKey = primaryKeyForChannel(channel) else {
            return nil
        }

        return itemForPrimaryKey(primaryKey)
    }

    func setItemForChannel(_ item: KZPlayerItemBase, channel: Int = -1) {
        guard let set = setForChannel(channel) else {
            return
        }

        set.itemKey = item.systemID
    }

    func itemForPrimaryKey(_ primaryKey: String) -> KZPlayerItem? {
        guard let realm = currentLibrary?.realm() else {
            return nil
        }

        let parts = primaryKey.components(separatedBy: "-")

        guard let classString = parts.first, let itemClass = NSClassFromString("MusicPlus.\(classString)") as? KZPlayerItem.Type else {
            return nil
        }

        return realm.object(ofType: itemClass, forPrimaryKey: primaryKey as AnyObject)
    }

    func resetPlayer() {
        activePlayer = -1
        auPlayerSets.forEach {
            $0.value.isRemoved = true
            $0.value.auPlayer.stop()
        }
        stopCrossfade()
        auPlayerSets.removeAll()
        averagePower = 0.0
    }
}

// MARK: - Library
extension KZPlayer {
    func find(_ q: String) -> Results<KZPlayerItem> {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        return realm.objects(KZPlayerItem.self).filter("title CONTAINS[c] %@ OR artist CONTAINS[c] %@ OR album CONTAINS[c] %@ OR albumArtist CONTAINS[c] %@", q, q, q, q)
    }

    // MARK: Collection

    func sessionShuffledQueue() -> Results<KZPlayerShuffleQueueItem> {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        return realm.objects(KZPlayerShuffleQueueItem.self).sorted(byKeyPath: "position")
    }

    func sessionQueue() -> Results<KZPlayerQueueItem> {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        return realm.objects(KZPlayerQueueItem.self).sorted(byKeyPath: "position")
    }

    // MARK: Session

    func prevSong() -> KZPlayerItemBase? {
        if currentTime() > 3 {
            return itemForChannel()
        }

        var x: KZPlayerItemBase?

        let collection = currentCollection()

        if collection.count > 0 {
            x = collection[0]
        }

        if let item = itemForChannel() {
            if let position = collection.firstIndex(where: { $0.originalItem == item }) {
                if (position - 1) < collection.count && (position - 1) > -1 {
                    x = collection[position - 1]
                } else {
                    if settings.repeatMode == .repeatAll {
                        x = collection[collection.count - 1]
                    } else {
                        x = item
                    }
                }
            }
        }

        return x
    }

    func rotateSongs() -> KZPlayerItemBase? {
        if settings.repeatMode == .repeatSong {
            return itemForChannel()
        }

        if let item = popUpNext() {
            return item
        }

        var x: KZPlayerItemBase?
        let collection = currentCollection()

        if collection.count > 0 {
            x = collection[0]
        }

        guard let item = itemForChannel(), let position = collection.firstIndex(where: { $0.originalItem == item }) else {
            return x
        }

        if (position + 1) < collection.count {
            x = collection[position + 1]
        } else {
            if settings.repeatMode == .repeatAll {
                x = collection[0]
            } else {
                x = nil
            }
        }

        return x
    }

    func currentCollection() -> Array<KZPlayerItemBase> {
        return settings.shuffleMode == .shuffle ? Array(sessionShuffledQueue()) : Array(sessionQueue())
    }

    func resetCollections() {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        currentQueueNotificationTokens.forEach { $0.invalidate() }

        realm.beginWrite()
        realm.delete(realm.objects(KZPlayerQueueItem.self))
        realm.delete(realm.objects(KZPlayerShuffleQueueItem.self))
        try! realm.commitWrite()
    }

    func setCollection(_ items: KZPlayerItemCollection?, initialSong: KZPlayerItem?, shuffle: Bool) {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        resetCollections()

        guard let items = items else {
            return
        }

        // Realm is reaally slow if we try reading from the base collection.
        // Converting it to an array speeds up the process x25
        let itemsAsArray = items.toArray()

        realm.beginWrite()

        for i in 0..<itemsAsArray.count {
            let queueItem = KZPlayerQueueItem(orig: itemsAsArray[i])
            queueItem.position = i
            realm.add(queueItem)
        }

        if shuffle {
            let shuffled = itemsAsArray.withShuffledPosition()
            for item in shuffled {
                let queueItem = KZPlayerShuffleQueueItem(orig: item)
                if item.originalItem().systemID == initialSong?.originalItem().systemID {
                    queueItem.position = -1
                }
                realm.add(queueItem)
            }
        }

         try! realm.commitWrite()

        let queueNotificationToken = items.observe { changes in
            switch changes {
            case .initial:
                break
            case .update(_, let deletions, let insertions, _):
                let objects = realm.objects(KZPlayerQueueItem.self).toArray()

                // Handle deletions
                objects.filter { deletions.contains($0.position) }.forEach { realm.delete($0) }

                // Handle insertions
                objects.forEach { object in
                    object.position += insertions.filter { object.position >= $0 }.count
                }
                insertions.forEach { i in
                    let queueItem = KZPlayerQueueItem(orig: items[i])
                    queueItem.position = i
                    realm.add(queueItem)
                }

                // No need to handle modifications as the queue items report back to their original items
                break
            case .error:
                break
            }
        }

        currentQueueNotificationTokens.append(queueNotificationToken)
    }

    func addUpNext(_ orig: KZPlayerItem) {
        addUpNext([orig])
    }

    func addUpNext(_ originalItems: [KZPlayerItem]) {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        try! realm.write {
            for originalItem in originalItems {
                realm.add(KZPlayerUpNextItem(orig: originalItem))
            }
        }
    }

    func popUpNext() -> KZPlayerHistoryItem? {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        let upNextItems = realm.objects(KZPlayerUpNextItem.self)

        guard let item = upNextItems.first else {
            return nil
        }

        let result = KZPlayerHistoryItem(orig: item.originalItem)
        try! realm.write {
            realm.delete(item)
        }

        return result
    }

    // MARK: - Song Interaction

    func likeItem(_ item: KZPlayerItem) {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        try! realm.write {
            item.originalItem().liked = true
        }
    }

    func unLikeItem(_ item: KZPlayerItem) {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        try! realm.write {
            item.originalItem().liked = false
        }
    }

    // MARK: Adding Items

    func addMediaItem(at fileURL: URL, update: Bool = true) {
        guard let library = currentLibrary else {
            fatalError("No library is currently set.")
        }

        guard let localLibrary = library as? KZLocalLibrary else {
            fatalError("This operation requires a local library.")
        }

        localLibrary.addMediaItem(at: fileURL, update: update)
    }
}
