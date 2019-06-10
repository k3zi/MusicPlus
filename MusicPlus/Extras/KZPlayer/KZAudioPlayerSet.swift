//
//  KZAudioPlayerSet.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import AVFoundation

class KZAudioPlayerSet: StreamingDelegate {

    let auPlayer: AVAudioPlayerNode
    let auSpeed: AVAudioUnitTimePitch
    let auEqualizer: AVAudioUnitEQ
    let itemKey: String

    var shouldUseCallback = true

    /// Whether the set has or will be removed from the audio engine and should thus be disregarded
    var isRemoved = false {
        didSet {
            if let overrideURL = overrideURL {
                try? FileManager.default.removeItem(at: overrideURL)
            }
        }
    }

    var isSeeking = false
    var item: KZPlayerItem
    var itemReference: KZThreadSafeReference<KZPlayerItem>
    var libraryIdentifier: String?
    var lastSeekTime: TimeInterval?
    var startTime: TimeInterval = 0
    var completionHandler: AVAudioNodeCompletionHandler?

    var overrideURL: URL?

    init(item: KZPlayerItem) {
        self.item = item
        itemReference = KZThreadSafeReference(to: item)
        libraryIdentifier = item.libraryUniqueIdentifier
        if item.isStoredLocally {
            auPlayer = AVAudioPlayerNode()
        } else {
            auPlayer = KZRemoteAudioPlayerNode()
        }
        auSpeed = AVAudioUnitTimePitch()
        auEqualizer = AVAudioUnitEQ(numberOfBands: 10)
        itemKey = item.systemID

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

    func callCompletionHandler() {
        if isRemoved || isSeeking {
            return
        }

        if let item = itemReference.resolve() {
            let currentTime = self.currentTime()
            let duration = self.duration()
            try? item.realm?.write {
                item.playCount += (currentTime - startTime) / duration
            }
        }

        if let handler = completionHandler {
            handler()
        }
    }

    func schedule(completionHandler: AVAudioNodeCompletionHandler?) {
        if let auPlayer = auPlayer as? KZRemoteAudioPlayerNode, overrideURL == nil {
            auPlayer.firstPacketPushedHandler = {
                DispatchQueue.main.async {
                    guard let item = self.itemReference.resolve() else {
                        return
                    }
                    KZPlayer.sharedInstance.updateNowPlayingInfo(item)
                }
            }
            auPlayer.schedule(url: overrideURL ?? item.fileURL(), durationHint: item.duration) {
                self.callCompletionHandler()
            }
        } else {
            let fileURL = overrideURL ?? item.fileURL()
            guard let file  = try? AVAudioFile(forReading: fileURL) else {
                return
            }

            self.completionHandler = completionHandler
            auPlayer.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { _ in
                self.callCompletionHandler()
            }
        }
    }

    func streamer(_ streamer: Streaming, alternativeURLForFailedDownload download: Downloading) -> URL? {
        guard let item = itemReference.resolve() else {
            return nil
        }

        let newUrl = item.fileURL()
        return download.url != newUrl ? newUrl : nil
    }

    func streamer(_ streamer: Streaming, urlForFailedDownload download: Downloading, percentDownloaded: Double) -> URL? {
        guard let item = itemReference.resolve() else {
            return nil
        }

        return item.fileURL(from: percentDownloaded * duration(item: item))
    }

    func streamer(_ streamer: Streaming, didResolveDownloadTo location: URL) {
        overrideURL = location
        schedule(completionHandler: completionHandler)
    }

    func pause() {
        guard auPlayer.isPlaying else {
            return
        }

        auPlayer.pause()
    }

    func play() {
        guard !auPlayer.isPlaying else {
            return
        }

        auPlayer.play()
    }

    func stop() {
        guard auPlayer.isPlaying else {
            return
        }

        auPlayer.stop()
    }

    func reset() {
        auPlayer.reset()
    }

    func lastRenderTime() -> AVAudioTime? {
        return auPlayer.lastRenderTime
    }

    func currentTime(item: KZPlayerItemBase? = nil) -> Double {
        guard auPlayer.isPlaying && auPlayer.engine != nil else {
            return 0
        }

        if overrideURL == nil, let auPlayer = auPlayer as? KZRemoteAudioPlayerNode, let currentTime = auPlayer.currentTime {
            return currentTime
        }

        guard let nodeTime = auPlayer.lastRenderTime, let playerTime = auPlayer.playerTime(forNodeTime: nodeTime) else {
            return 0
        }

        guard let item = item ?? itemReference.resolve() else {
            return 0
        }

        return (lastSeekTime ?? 0) + (Double(playerTime.sampleTime) / Double(playerTime.sampleRate)) - item.startTime
    }

    func duration(item: KZPlayerItemBase? = nil) -> Double {
        guard let item = item ?? itemReference.resolve() else {
            return 0
        }

        return item.duration
    }

    func seek(to time: TimeInterval, completionHandler: @escaping AVAudioNodeCompletionHandler) throws {
        guard let item = itemReference.resolve() else {
            return
        }

        let currentTime = self.currentTime()
        let duration = self.duration()
        try? item.realm?.write {
            item.playCount += (currentTime - startTime) / duration
        }
        startTime = time

        isSeeking = true
        lastSeekTime = time
        if overrideURL == nil, let auPlayer = auPlayer as? KZRemoteAudioPlayerNode {
            self.completionHandler = completionHandler
            try auPlayer.seek(to: time) {
                self.callCompletionHandler()
            }
            isSeeking = false
            return
        }

        var value = time
        if item.startTime != 0.0 {
            value += TimeInterval(item.startTime)
        }

        if value < 0.0 {
            value = 0.0
        }

        let audioFile = try AVAudioFile(forReading: overrideURL ?? item.fileURL())
        guard let nodeTime = auPlayer.lastRenderTime, let playerTime = auPlayer.playerTime(forNodeTime: nodeTime) else {
            isSeeking = false
            return
        }

        let startingFrame = AVAudioFramePosition(playerTime.sampleRate * value)
        let frameLength =  AVAudioFrameCount(playerTime.sampleRate * (item.endTime - value))
        auPlayer.stop()
        self.completionHandler = completionHandler
        if #available(iOS 11.0, *) {
            auPlayer.scheduleSegment(audioFile, startingFrame: startingFrame, frameCount: frameLength, at: nil, completionCallbackType: .dataPlayedBack) { _ in
                os_log("data finished playing back")
                self.callCompletionHandler()
            }
        } else {
            auPlayer.scheduleSegment(audioFile, startingFrame: startingFrame, frameCount: frameLength, at: nil) {
                self.callCompletionHandler()
            }
        }
        auPlayer.play()
        isSeeking = false
    }
}
