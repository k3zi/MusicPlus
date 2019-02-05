//
//  KZRemoteAudioPlayerNode.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import AVFoundation
import Foundation
import os.log

open class KZRemoteAudioPlayerNode: AVAudioPlayerNode, Streaming {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Streamer")

    public internal(set) var state: StreamingState = .stopped {
        didSet {
            delegate?.streamer(self, changedState: state)
        }
    }

    public var url: URL? {
        didSet {
            reset()

            if let url = url {
                downloader.url = url
                downloader.start()
            }
        }
    }

    public var durationHint: TimeInterval? {
        didSet {
            parser?.durationHint = durationHint
        }
    }

    var completionHandler: AVAudioNodeCompletionHandler?
    var firstPacketPushedHandler: (() -> Void)?
    var timesFailed: Int = 0
    var timer: Timer?

    // MARK: - Properties

    /// A `TimeInterval` used to calculate the current play time relative to a seek operation.
    var currentTimeOffset: TimeInterval = 0
    var timePaused: TimeInterval?

    /// A `Bool` indicating whether the file has been completely scheduled into the player node.
    var isFileSchedulingComplete = false

    var hasPushedAPacket = false

    var rawCurrentTime: TimeInterval? {
        guard let nodeTime = self.lastRenderTime, let playerTime = self.playerTime(forNodeTime: nodeTime) else {
            return 0
        }

        return TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
    }

    public var currentTime: TimeInterval? {
        guard hasPushedAPacket else {
            return currentTimeOffset
        }

        guard let rawCurrentTime = self.rawCurrentTime else {
                return currentTimeOffset
        }

        return rawCurrentTime + currentTimeOffset
    }

    public var delegate: StreamingDelegate?
    public internal(set) var duration: TimeInterval?
    public internal(set) var parser: Parsing?
    public internal(set) var reader: Reading?

    public lazy var downloader: Downloading = {
        let downloader = Downloader()
        downloader.delegate = self
        return downloader
    }()

    public func callCompletionHandler() {
        completionHandler?()
        completionHandler = nil
    }

    convenience init(delegate: StreamingDelegate) {
        self.init()
        self.delegate = delegate
    }

    // MARK: - Scheduling Buffers
    func scheduleNextBuffer() {
        guard let reader = reader else {
            // os_log("No reader yet...", log: KZRemoteAudioPlayerNode.logger, type: .debug)
            return
        }

        guard !isFileSchedulingComplete else {
            return
        }

        do {
            let nextScheduledBuffer = try reader.read(readBufferSize)
            self.scheduleBuffer(nextScheduledBuffer)
            if !hasPushedAPacket {
                hasPushedAPacket = true
                if let currentTime = currentTime, let rawTime = rawCurrentTime {
                    currentTimeOffset = currentTime - rawTime
                }
                firstPacketPushedHandler?()
            }
        } catch ReaderError.reachedEndOfFile {
            os_log("Scheduler reached end of file", log: KZRemoteAudioPlayerNode.logger, type: .debug)
            isFileSchedulingComplete = true

            if !hasPushedAPacket {
                self.callCompletionHandler()
            }
        } catch {
            os_log("Cannot schedule buffer: %@", log: KZRemoteAudioPlayerNode.logger, type: .debug, error.localizedDescription)
        }
    }

    // MARK: - Handling Time Updates

    /// Handles the duration value, explicitly checking if the duration is greater than the current value. For indeterminate streams we can accurately estimate the duration using the number of packets parsed and multiplying that by the number of frames per packet.
    func handleDurationUpdate() {
        if let newDuration = parser?.duration {
            // Check if the duration is either nil or if it is greater than the previous duration
            var shouldUpdate = false
            if duration == nil {
                shouldUpdate = true
            } else if let oldDuration = duration, oldDuration < newDuration {
                shouldUpdate = true
            }

            // Update the duration value
            if shouldUpdate {
                self.duration = newDuration
                notifyDurationUpdate(newDuration)
            }
        }
    }

    /// Handles the current time relative to the duration to make sure current time does not exceed the duration
    func handleTimeUpdate() {
        guard self.engine != nil else {
            return
        }

        guard let currentTime = currentTime, let duration = durationHint ?? duration else {
            return
        }

        if currentTime >= duration {
            try? seek(to: 0)
            pause()
            callCompletionHandler()
        }
    }

    func schedule(url: URL, durationHint: TimeInterval? = nil, completionHandler: @escaping AVAudioNodeCompletionHandler) {
        self.completionHandler = completionHandler
        self.url = url
        self.durationHint = durationHint
    }

    func addTimer() {
        /// Use timer to schedule the buffers (this is not ideal, wish AVAudioEngine provided a pull-model for scheduling buffers)
        let interval = 1 / (readFormat.sampleRate / Double(readBufferSize))
        self.timer?.invalidate()
        let timer = Timer(timeInterval: interval / 2, repeats: true) {
            [weak self] _ in
            guard self?.isPlaying ?? false else {
                return
            }

            self?.scheduleNextBuffer()
            self?.handleTimeUpdate()
            self?.notifyTimeUpdated()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: - Reset

    override open func reset() {
        os_log("%@ - %d", log: KZRemoteAudioPlayerNode.logger, type: .debug, #function, #line)

        // Reset the playback state
        stop()
        duration = nil
        durationHint = nil
        timesFailed = 0
        reader = nil
        isFileSchedulingComplete = false
        hasPushedAPacket = false
        self.timer?.invalidate()

        // Create a new parser
        do {
            parser = try Parser(extensionHint: url?.pathExtension)
        } catch {
            os_log("Failed to create parser: %@", log: KZRemoteAudioPlayerNode.logger, type: .error, error.localizedDescription)
        }
    }

    // MARK: - Methods

    override open func play() {
        os_log("%@ - %d", log: KZRemoteAudioPlayerNode.logger, type: .debug, #function, #line)

        if let timePaused = timePaused {
            currentTimeOffset -= timePaused
            self.timePaused = nil
        }

        addTimer()

        // Start playback on the player node
        super.play()

        // Update the state
        state = .playing
    }

    override open func pause() {
        os_log("%@ - %d", log: KZRemoteAudioPlayerNode.logger, type: .debug, #function, #line)

        // Check if the player node is playing
        guard self.isPlaying else {
            return
        }

        timer?.invalidate()

        timePaused = self.currentTime

        // Pause the player node and the engine
        super.pause()

        timePaused = self.currentTime

        // Update the state
        state = .paused
    }

    override open func stop() {
        os_log("%@ - %d", log: KZRemoteAudioPlayerNode.logger, type: .debug, #function, #line)

        // Stop the downloader, the player node, and the engine
        downloader.stop()
        super.stop()
        timer?.invalidate()

        // Update the state
        state = .stopped
    }

    public func seek(to time: TimeInterval, completionHandler: AVAudioNodeCompletionHandler? = nil) throws {
        os_log("%@ - %d [%.1f]", log: KZRemoteAudioPlayerNode.logger, type: .debug, #function, #line, time)
        self.completionHandler = completionHandler
        // Make sure we have a valid parser and reader
        guard let parser = parser, let reader = reader else {
            return
        }

        // Get the proper time and packet offset for the seek operation
        guard let frameOffset = parser.frameOffset(forTime: time),
            let packetOffset = parser.packetOffset(forFrame: frameOffset) else {
                return
        }
        currentTimeOffset = time
        isFileSchedulingComplete = false

        // We need to store whether or not the player node is currently playing to properly resume playback after
        let isPlaying = self.isPlaying

        // Stop the player node to reset the time offset to 0
        super.stop()

        // Perform the seek to the proper packet offset
        do {
            try reader.seek(packetOffset)
        } catch {
            os_log("Failed to seek: %@", log: KZRemoteAudioPlayerNode.logger, type: .error, error.localizedDescription)
            return
        }

        // If the player node was previous playing then resume playback
        if isPlaying {
            super.play()
        }

        // Update the current time
        delegate?.streamer(self, updatedCurrentTime: time)
    }

    // MARK: - Notifying The Delegate
    func notifyDownloadProgress(_ progress: Float) {
        guard let url = url else {
            return
        }

        delegate?.streamer(self, updatedDownloadProgress: progress, forURL: url)
    }

    func notifyDurationUpdate(_ duration: TimeInterval) {
        guard url != nil else {
            return
        }

        delegate?.streamer(self, updatedDuration: duration)
    }

    func notifyTimeUpdated() {
        guard self.engine?.isRunning ?? false, self.isPlaying else {
            return
        }

        guard let currentTime = currentTime else {
            return
        }

        delegate?.streamer(self, updatedCurrentTime: currentTime)
    }

}
