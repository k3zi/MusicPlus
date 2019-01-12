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
    var crossFadeMode: KZPLayerCrossFadeMode = .crossFade
    var crossFadePrevious = false
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
    case noCrossFade
    case crossFade
}

class KZAudioPlayerSet: StreamingDelegate {
    var auPlayer: AVAudioPlayerNode
    var auSpeed: AVAudioUnitVarispeed
    var auEqualizer: AVAudioUnitEQ
    var itemKey: String?
    var shouldUseCallback = true
    var item: KZPlayerItem
    var itemReference: KZThreadSafeReference<KZPlayerItem>
    var libraryIdentifier: String?

    init(item: KZPlayerItem) {
        self.item = item
        itemReference = KZThreadSafeReference(to: item)
        libraryIdentifier = item.plexLibraryUniqueIdentifier
        if item.isStoredLocally {
            auPlayer = AVAudioPlayerNode()
        } else {
            auPlayer = KZRemoteAudioPlayerNode()
        }
        auSpeed = AVAudioUnitVarispeed()
        auEqualizer = AVAudioUnitEQ(numberOfBands: 10)

        if let player = auPlayer as? KZRemoteAudioPlayerNode {
            player.delegate = self
        }
    }

    var volume: Float {
        set {
            auPlayer.volume = newValue
        }

        get {
            return auPlayer.volume
        }
    }

    func schedule(completionHandler: @escaping AVAudioNodeCompletionHandler) {
        if let auPlayer = auPlayer as? KZRemoteAudioPlayerNode {
            auPlayer.firstPacketPushedHandler = {
                KZPlayer.sharedInstance.updateNowPlayingInfo(self.item)
            }
            auPlayer.schedule(url: item.fileURL(), durationHint: item.duration(), completionHandler: completionHandler)
        } else {
            let fileURL = item.fileURL()
            guard let file  = try? AVAudioFile(forReading: fileURL) else {
                return
            }

            auPlayer.scheduleFile(file, at: nil, completionHandler: completionHandler)
        }
    }

    func streamer(_ streamer: Streaming, alternativeURLForFailedDownload download: Downloading) -> URL? {
        guard let item = itemReference.resolve() else {
            return nil
        }

        let newUrl = item.fileURL()
        return download.url != newUrl ? newUrl : nil
    }

    func pause() {
        auPlayer.pause()
    }

    func play() {
        auPlayer.play()
    }

    func stop() {
        auPlayer.stop()
    }

    func lastRenderTime() -> AVAudioTime? {
        return auPlayer.lastRenderTime
    }

    func currentTime() -> Double {
        if let auPlayer = auPlayer as? KZRemoteAudioPlayerNode, let currentTime = auPlayer.currentTime {
            return currentTime
        }

        guard let nodeTime = auPlayer.lastRenderTime, let playerTime = auPlayer.playerTime(forNodeTime: nodeTime) else {
            return 0.0
        }

        guard let item = itemReference.resolve() else {
            return 0.0
        }

        return (Double(playerTime.sampleTime) / Double(playerTime.sampleRate)) - item.startTime
    }

    func seek(to time: TimeInterval, completionHandler: @escaping AVAudioNodeCompletionHandler) throws {
        if let auPlayer = auPlayer as? KZRemoteAudioPlayerNode {
            return try auPlayer.seek(to: time, completionHandler: completionHandler)
        }

        var value = time
        if item.startTime != 0.0 {
            value += TimeInterval(item.startTime)
        }

        if value < 0.0 {
            value = 0.0
        }

        let audioFile = try AVAudioFile(forReading: item.fileURL())
        guard let nodeTime = auPlayer.lastRenderTime, let playerTime = auPlayer.playerTime(forNodeTime: nodeTime) else {
            return
        }

        let startingFrame = AVAudioFramePosition(playerTime.sampleRate * value)
        let frameLength =  AVAudioFrameCount(playerTime.sampleRate * (item.endTime - value))
        auPlayer.stop()
        auPlayer.scheduleSegment(audioFile, startingFrame: startingFrame, frameCount: frameLength, at: nil, completionHandler: completionHandler)
    }
}

// MARK: Main Player
class KZPlayer: NSObject {
    static let sharedInstance = KZPlayer()
    static let libraryQueue = DispatchQueue(label: "io.kez.musicplus.librarythread", attributes: .concurrent)
    static let uiQueue = DispatchQueue(label: "io.kez.musicplus.uithread", attributes: .concurrent)

    static let libraryQueueKey = DispatchSpecificKey<Void>()

    /// ------- Player ------- ///
    var audioEngine: AVAudioEngine
    var audioSession: AVAudioSession
    var auPlayerSets = [Int: KZAudioPlayerSet]()
    var auMixer: AVAudioMixerNode

    var activePlayer = -1

    var itemBeforeUpNextKey: String?
    var cachedActiveItemKey: String?
    var cachedActiveItem: KZPlayerItem?

    var settings = Settings()
    var state = KZPlayerState.starting

    var checkTimeFunctioning = false

    var crossFading = false
    var crossFadeDuration = 10.0, crossFadeTime = 10.0
    var crossFadeCount = 0

    // Volume
    var averagePower: Float = 0.0
    var volumeView = MPVolumeView()

    // Library
    var currentLibrary: KZLibrary? {
        didSet {
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Constants.Notification.libraryDidChange, object: nil)
            })

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

    static var imageDownloader: ImageDownloader = {
        return ImageDownloader()
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
            self.checkTime()
        }

        #if !targetEnvironment(simulator)
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine")
        }
        #endif
    }

    func addPlayerSet(bus: Int, item: KZPlayerItem) -> KZAudioPlayerSet {
        let set = KZAudioPlayerSet(item: item)
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

        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            if self.audioEngine.isRunning {
                self.resume()
            }
        }

        volumeView.frame = CGRect(x: -2000, y: -2000, width: 0, height: 0)
        volumeView.alpha = 0.1
        volumeView.clipsToBounds = true

        volumeView.isUserInteractionEnabled = false

        if let window = UIApplication.shared.windows.first {
            window.addSubview(volumeView)
        }

        AppDelegate.del().window?.addSubview(volumeView)

        MPRemoteCommandCenter.shared().playCommand.addTarget(self, action: #selector(self.resume))
        MPRemoteCommandCenter.shared().pauseCommand.addTarget(self, action: #selector(self.pause))
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget(self, action: #selector(self.next))
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget(self, action: #selector(self.prev))
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
        guard !item.isInvalidated, let realm = currentLibrary?.realm() else {
            return
        }

        let itemRefrence = ThreadSafeReference(to: item)
        guard let item = realm.resolve(itemRefrence) else {
            return
        }

        let center = MPNowPlayingInfoCenter.default()

        autoreleasepool {
            var dict = [String: Any]()
            dict[MPMediaItemPropertyTitle] = item.title
            dict[MPMediaItemPropertyArtist] = item.artistName()
            dict[MPMediaItemPropertyAlbumTitle] = item.album?.name ?? ""
            dict[MPMediaItemPropertyPlaybackDuration] = item.endTime - item.startTime
            dict[MPNowPlayingInfoPropertyPlaybackRate] = self.audioEngine.isRunning ? 1.0 : 0.0
            dict[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime()
            if #available(iOS 10.0, *) {
                dict[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
            }

            let systemID = item.systemID
            item.fetchArtwork { artwork in
                guard let currentItem = self.itemForChannel(), systemID == currentItem.systemID else {
                    return
                }

                if let image = artwork.image(at: Constants.UI.Screen.bounds.size) {
                    dict[MPMediaItemPropertyArtwork] = artwork
                    AppDelegate.del().session.backgroundImage = image
                    AppDelegate.del().session.tintColor = ObjectiveCProcessing.getDominatingColor(image)
                } else {
                    dict[MPMediaItemPropertyArtwork] = nil
                    AppDelegate.del().session.backgroundImage = nil
                    AppDelegate.del().session.tintColor = nil
                }

                center.nowPlayingInfo = dict
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

    // MARK: Play

    /// Plays the provided items
    ///
    /// - Parameters:
    ///   - items: the collection of items that will replavethe current collection
    ///   - initialSong: the first song to play, if nil then it will be the first item in `items`
    ///   - shuffle: whether to shuffle the items, nil ensures that the previous value is used
    func play(_ items: KZPlayerItemCollection, initialSong: KZPlayerItem? = nil, shuffle: Bool? = nil) {
        guard DispatchQueue.getSpecific(key: KZPlayer.libraryQueueKey) != nil else {
            return KZPlayer.libraryQueue.sync {
                self.play(items, initialSong: initialSong, shuffle: true)
            }
        }

        let shuffle = setShuffle(shuffle)
        resetPlayer()
        setCollection(items, initialSong: initialSong, shuffle: shuffle)

        var index = 0
        if !shuffle, let initialSong = initialSong {
            // If we are browsing the collection as normal and the initial
            // song was specified then let's find it's index

            // `setCollection` guarantees that if we shuffle then the `initialSong`
            // will be the first
            index = items.index(of: initialSong) ?? 0
        }

        resetPlayer()
        var collection = shuffle ? Array(sessionShuffledQueue()) as Array<KZPlayerItem> : Array(sessionQueue()) as Array<KZPlayerItem>

        guard collection.count > 0 else {
            return
        }

        persistentPlayNextSong(collection[index], times: collection.count)
    }

    // Play Single Item
    func play(_ item: KZPlayerItem, silent: Bool = false, isQueueItem: Bool = false) -> Bool {
        if !Thread.current.isMainThread {
            let threadSafeItem = KZThreadSafeReference(to: item)
            return DispatchQueue.main.sync {
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

        let tempo = item.tempo

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

        playerSet.play()
        print("started playing \"\(item.title)\" on channel: \(channel)")

        updateNowPlayingInfo(item)
        return true
    }

    @objc func resume() {
        do {
            try audioEngine.start()
            auPlayerSets.forEach({ $0.value.play() })

            if let item = itemForChannel() {
                updateNowPlayingInfo(item)
            }
        } catch {
            print("Error starting audio engine")
        }
    }

    @objc func pause() {
        if audioEngine.isRunning {
            auPlayerSets.forEach({ $0.value.pause() })
            audioEngine.pause()
        }
    }

    func togglePlay() {
        if audioEngine.isRunning {
            pause()
        } else {
            resume()
        }
    }

    @objc func next() {
        playerCompleted(activePlayer, force: true)
    }

    func backgroundNext() {
        DispatchQueue.main.sync {
            self.next()
        }
    }

    @objc func prev() -> Bool {
        guard let prevItem = prevSong() else {
            return false
        }

        print("previous = \(prevItem.title)")

        if settings.crossFadeMode == .crossFade && settings.crossFadePrevious {
            return crossFadeTo(prevItem)
        }

        stopCrossfade()
        let result = play(prevItem)

        for channel in auPlayerSets.keys where channel != activePlayer {
            removeChannel(channel: channel)
        }

        return result
    }

    func setSpeed(_ value: AudioUnitParameterValue, channel: Int = -1) {
        var value = value
        if value < 1 || value > 16 {
            value = 4
        }

        speedNodeForChannel(channel)?.rate = value/4
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

    func currentTime(_ channel: Int = -1, item: KZPlayerItem? = nil) -> Double {
        guard let filePlayer = setForChannel(channel) else {
            return 0.0
        }

        return filePlayer.currentTime()
    }

    func setCurrentTime(_ value: Double, channel: Int = -1) -> Bool {
        guard let item = itemForChannel(channel) else {
            return false
        }

        let timeInterval = TimeInterval(value)
        do {
            guard let filePlayer = setForChannel(channel) else {
                return false
            }
            try filePlayer.seek(to: timeInterval) {
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
            set.auPlayer.stop()
            for unit in [set.auPlayer, set.auEqualizer, set.auSpeed] as [AVAudioNode] {
                self.audioEngine.detach(unit)
            }
            self.auPlayerSets.removeValue(forKey: channel)
        }
    }

    func playerCompleted(_ channel: Int, force: Bool = false) {
        // If the active channel has completed and we are still crossfading then either
        // the next player has not been set yet or there was an error and the active player
        // could not play.
        guard force || !crossFading || channel == activePlayer else {
            return
        }

        persistentPlayNextSong()
    }

    func persistentPlayNextSong(_ item: KZPlayerItem? = nil, times: Int = 1) {
        var played = false
        var i = 0
        while !played && i < times {
            played = playNextSong(item)
            i += 1
        }
    }

    func playNextSong(_ item: KZPlayerItem? = nil) -> Bool {
        guard let nextItem = item ?? rotateSongs() else {
            return true
        }

        let isQueueItem = nextItem is KZPlayerHistoryItem

        if !isQueueItem { // = Not an item that was added to the queue
            itemBeforeUpNextKey = nil
        } else if itemBeforeUpNextKey == nil {
            itemBeforeUpNextKey = itemForChannel(activePlayer)?.systemID
        }

        if settings.crossFadeMode == .crossFade {
            return crossFadeTo(nextItem)
        }

        for channel in auPlayerSets.keys {
            removeChannel(channel: channel)
        }

        stopCrossfade()
        return play(nextItem, isQueueItem: nextItem is KZPlayerHistoryItem)
    }
}

// MARK: CrossFade Functions
extension KZPlayer {

    func checkTime() {
        var item: KZPlayerItem?
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

        if !checkTimeFunctioning && settings.crossFadeMode == .crossFade && !crossFading && (currentItem.endTime - currentTime(item: item)) < crossFadeTime {
            checkTimeFunctioning = true
            backgroundNext()
            checkTimeFunctioning = false
        }
    }

    func stopCrossfade() {
        guard crossFading else {
            return
        }

        crossFadeCount += 1
        PRTween.sharedInstance().removeAllTweenOperations()
        crossFading = false
    }

    func crossFadeTo(_ item: KZPlayerItem) -> Bool {
        stopCrossfade()
        print("crossFadeCount = \(crossFadeCount)")
        print("pre crossFading = \(crossFading)")
        let currentCFCount = crossFadeCount
        crossFading = true

        guard play(item, silent: true, isQueueItem: item is KZPlayerHistoryItem) else {
            crossFading = false
            return false
        }

        guard let p1 = playerForChannel() else {
            crossFading = false
            return false
        }

        let duration = CGFloat(crossFadeDuration)
        guard let period1 = PRTweenPeriod.period(withStartValue: CGFloat(p1.volume), endValue: 1.0, duration: duration) as? PRTweenPeriod else {
             crossFading = false
            return false
        }

        let operation1 = PRTweenOperation()
        operation1.period = period1
        operation1.target = self
        operation1.timingFunction = PRTweenTimingFunctionLinear
        operation1.updateBlock = { (p: PRTweenPeriod!) in
            if currentCFCount == self.crossFadeCount {
                p1.volume = Float(p.tweenedValue)
            }
        }
        operation1.completeBlock = { (completed: Bool) -> Void in
            if currentCFCount == self.crossFadeCount {
                self.crossFading = false
            }
        }

        for previousChannel in auPlayerSets.keys where previousChannel != activePlayer {
            if let p2 = playerForChannel(previousChannel), let period2 = PRTweenPeriod.period(withStartValue: CGFloat(p2.volume), endValue: 0.0, duration: duration * CGFloat(p2.volume)) as? PRTweenPeriod {
                let operation2 = PRTweenOperation()
                operation2.period = period2
                operation2.target = self
                operation2.timingFunction = PRTweenTimingFunctionLinear
                operation2.updateBlock = { (p: PRTweenPeriod!) in
                    if currentCFCount == self.crossFadeCount {
                        p2.volume = Float(p.tweenedValue)
                    }
                }
                operation2.completeBlock = { (completed: Bool) -> Void in
                    if currentCFCount == self.crossFadeCount {
                        self.removeChannel(channel: previousChannel)
                    }
                }

                PRTween.sharedInstance().add(operation2)
            }
        }

        PRTween.sharedInstance().add(operation1)
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

    func speedNodeForChannel(_ channel: Int = -1) -> AVAudioUnitVarispeed? {
        let channel = channel == -1 ? activePlayer : channel

        guard let set = auPlayerSets.filter({ $0.key == channel }).first?.value else {
            return nil
        }

        return set.auSpeed
    }

    func primaryKeyForChannel(_ channel: Int = -1) -> String? {
        let channel = channel == -1 ? activePlayer : channel

        guard let set = auPlayerSets.filter({ $0.key == channel }).first?.value else {
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

    func setItemForChannel(_ item: KZPlayerItem, channel: Int = -1) {
        let channel = channel == -1 ? activePlayer : channel

        guard let set = auPlayerSets.filter({ $0.key == channel }).first?.value else {
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
        auPlayerSets.forEach({
            $0.value.auPlayer.stop()
        })
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

    func prevSong() -> KZPlayerItem? {
        if currentTime() > 3 {
            return itemForChannel()
        }

        var x: KZPlayerItem?

        let collection = currentCollection()

        if collection.count > 0 {
            x = collection[0]
        }

        if let item = itemForChannel() {
            if let position = collection.index(of: item) {
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

    func rotateSongs() -> KZPlayerItem? {
        if settings.repeatMode == .repeatSong {
            return itemForChannel()
        }

        if let item = popUpNext() {
            return item
        }

        var x: KZPlayerItem?
        let collection = currentCollection()

        if collection.count > 0 {
            x = collection[0]
        }

        guard let item = itemForChannel(), let position = collection.index(of: item) else {
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

    func currentCollection() -> [KZPlayerItem] {
        return settings.shuffleMode == .shuffle ? Array(sessionShuffledQueue()) as Array<KZPlayerItem> : Array(sessionQueue()) as Array<KZPlayerItem>
    }

    func resetCollections() {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

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

        realm.beginWrite()

        for i in 0..<items.count {
            let queueItem = KZPlayerQueueItem(orig: items[i])
            queueItem.position = i
            realm.add(queueItem)
        }

        if shuffle {
            let shuffled = items.shuffled()
            for item in shuffled {
                let queueItem = KZPlayerShuffleQueueItem(orig: item)
                if item.originalItem().systemID == initialSong?.originalItem().systemID {
                    queueItem.position = -1
                }
                realm.add(queueItem)
            }
        }

         try! realm.commitWrite()
    }

    func addUpNext(_ orig: KZPlayerItem) {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        let newItem = KZPlayerUpNextItem(orig: orig)

        try! realm.write {
            realm.add(newItem)
        }
    }

    func popUpNext() -> KZPlayerHistoryItem? {
        guard let realm = currentLibrary?.realm() else {
            fatalError("No library is currently set.")
        }

        let upNextItems = realm.objects(KZPlayerUpNextItem.self)
        var result: KZPlayerHistoryItem?

        if upNextItems.count > 0 {
            if let item = upNextItems.first {
                result = KZPlayerHistoryItem(orig: item)
                try! realm.write {
                    realm.delete(item)
                }
            }
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
