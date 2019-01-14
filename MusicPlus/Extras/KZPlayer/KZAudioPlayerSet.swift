//
//  KZAudioPlayerSet.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation

class KZAudioPlayerSet: StreamingDelegate {
    var auPlayer: AVAudioPlayerNode
    var auSpeed: AVAudioUnitVarispeed
    var auEqualizer: AVAudioUnitEQ
    var itemKey: String?
    var shouldUseCallback = true

    /// Whether the set has or will be removed from the audio engine and should thus be disregarded
    var isRemoved = false

    var isSeeking = false
    var item: KZPlayerItem
    var itemReference: KZThreadSafeReference<KZPlayerItem>
    var libraryIdentifier: String?
    var lastSeekTime: TimeInterval?

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

    func callCompletionHandler(_ handler: AVAudioNodeCompletionHandler) {
        if isRemoved || isSeeking {
            return
        }

        handler()
    }

    func schedule(completionHandler: @escaping AVAudioNodeCompletionHandler) {
        if let auPlayer = auPlayer as? KZRemoteAudioPlayerNode {
            auPlayer.firstPacketPushedHandler = {
                DispatchQueue.main.async {
                    guard let item = self.itemReference.resolve() else {
                        return
                    }
                    KZPlayer.sharedInstance.updateNowPlayingInfo(item)
                }
            }
            auPlayer.schedule(url: item.fileURL(), durationHint: item.duration()) {
                self.callCompletionHandler(completionHandler)
            }
        } else {
            let fileURL = item.fileURL()
            guard let file  = try? AVAudioFile(forReading: fileURL) else {
                return
            }

            auPlayer.scheduleFile(file, at: nil) {
                self.callCompletionHandler(completionHandler)
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

    func currentTime(item: KZPlayerItemBase? = nil) -> Double {
        if let auPlayer = auPlayer as? KZRemoteAudioPlayerNode, let currentTime = auPlayer.currentTime {
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

    func seek(to time: TimeInterval, completionHandler: @escaping AVAudioNodeCompletionHandler) throws {
        guard DispatchQueue.getSpecific(key: KZPlayer.libraryQueueKey) != nil else {
            return try KZPlayer.libraryQueue.sync {
                return try self.seek(to: time, completionHandler: completionHandler)
            }
        }

        guard let item = itemReference.resolve() else {
            return
        }

        isSeeking = true
        lastSeekTime = time
        if let auPlayer = auPlayer as? KZRemoteAudioPlayerNode {
            try auPlayer.seek(to: time) {
                self.callCompletionHandler(completionHandler)
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

        let audioFile = try AVAudioFile(forReading: item.fileURL())
        guard let nodeTime = auPlayer.lastRenderTime, let playerTime = auPlayer.playerTime(forNodeTime: nodeTime) else {
            isSeeking = false
            return
        }

        let startingFrame = AVAudioFramePosition(playerTime.sampleRate * value)
        let frameLength =  AVAudioFrameCount(playerTime.sampleRate * (item.endTime - value))
        auPlayer.stop()
        auPlayer.scheduleSegment(audioFile, startingFrame: startingFrame, frameCount: frameLength, at: nil) {
            self.callCompletionHandler(completionHandler)
        }
        auPlayer.play()
        isSeeking = false
    }
}