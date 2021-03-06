//
//  Parser.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

public enum ParserStatus {
    case running
    case stopped
}

/// The `Parser` is a concrete implementation of the `Parsing` protocol used to convert binary data into audio packet data. This class uses the Audio File Stream Services to progressively parse the properties and packets of the incoming audio data.
public class Parser: Parsing {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser")
    static let loggerPacketCallback = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.Packets")
    static let loggerPropertyListenerCallback = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.PropertyListener")

    // MARK: - Parsing props

    public internal(set) var dataFormat: AVAudioFormat?
    public internal(set) var packets = [(Data, AudioStreamPacketDescription?)]()
    public var durationHint: TimeInterval?
    public var totalPacketCount: AVAudioPacketCount? {
        guard let durationHint = durationHint, let sampleRate = dataFormat?.sampleRate, let framesPerPacket = dataFormat?.streamDescription.pointee.mFramesPerPacket else {
            if dataFormat != nil {
                return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packets.count))
            }

            return nil
        }

        let totalFrameCount = UInt32(durationHint * sampleRate)
        return totalFrameCount / framesPerPacket
    }

    // MARK: - Properties

    /// A `UInt64` corresponding to the total frame count parsed by the Audio File Stream Services
    public internal(set) var frameCount: UInt64 = 0

    /// A `UInt64` corresponding to the total packet count parsed by the Audio File Stream Services
    public internal(set) var packetCount: UInt64 = 0

    /// The `AudioFileStreamID` used by the Audio File Stream Services for converting the binary data into audio packets
    fileprivate var streamID: AudioFileStreamID?

    public var status: ParserStatus = .running

    // MARK: - Lifecycle

    /// Initializes an instance of the `Parser`
    ///
    /// - Throws: A `ParserError.streamCouldNotOpen` meaning a file stream instance could not be opened
    public init(extensionHint: String? = nil, durationHint: TimeInterval? = nil) throws {
        self.durationHint = durationHint
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        var type = kAudioFileMP3Type
        if let extensionHint = extensionHint {
            type = hintForFileExtension(fileExtension: extensionHint)
        }
        guard AudioFileStreamOpen(context, ParserPropertyChangeCallback, ParserPacketCallback, type, &streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }

    public func reset() {
        objc_sync_enter(self)
        status = .stopped
        packets = []
        objc_sync_exit(self)
    }

    deinit {
        if let streamID = streamID {
            AudioFileStreamClose(streamID)
        }
        reset()
    }

    private func hintForFileExtension(fileExtension: String) -> AudioFileTypeID {
        var fileTypeHint: AudioFileTypeID = kAudioFileAAC_ADTSType

        switch fileExtension {
        case "aac":
            fileTypeHint = kAudioFileAAC_ADTSType
        case "aifc":
            fileTypeHint = kAudioFileAIFCType
        case "aiff":
            fileTypeHint = kAudioFileAIFFType
        case "caf":
            fileTypeHint = kAudioFileCAFType
        case "flac":
            fileTypeHint = kAudioFileFLACType
        case "mp3":
            fileTypeHint = kAudioFileMP3Type
        case "mp4":
            fileTypeHint = kAudioFileMPEG4Type
        case "m4a":
            fileTypeHint = kAudioFileM4AType
        case "wav":
            fileTypeHint = kAudioFileWAVEType
        default:
            break
        }

        return fileTypeHint
    }

    // MARK: - Methods

    public func parse(data: Data) throws {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)

        try autoreleasepool {
            let streamID = self.streamID!
            let count = data.count
            _ = try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
                let result = AudioFileStreamParseBytes(streamID, UInt32(count), bytes, [])
                guard result == noErr else {
                    os_log("Failed to parse bytes", log: Parser.logger, type: .error)
                    throw ParserError.failedToParseBytes(result)
                }
            }
        }
    }

}
