//
//  Streamer+DownloadingDelegate.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 6/5/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import os.log

extension KZRemoteAudioPlayerNode: DownloadingDelegate {

    public func download(_ download: Downloading, completedWithError error: Error?) {
        os_log("%@ - %d [error: %@]", log: KZRemoteAudioPlayerNode.logger, type: .debug, #function, #line, String(describing: error?.localizedDescription))

        guard let error = error, let url = download.url else {
            return
        }

        if timesFailed > 2 {
            if let newUrl = delegate?.streamer(self, alternativeURLForFailedDownload: download) {
                timesFailed = 0
                download.url = newUrl
                download.start()
            } else {
                delegate?.streamer(self, failedDownloadWithError: error, forURL: url)
                callCompletionHandler()
            }
        } else {
            timesFailed += 1
            download.url = delegate?.streamer(self, urlForFailedDownload: download, percentDownloaded: Double(download.progress)) ?? url
            download.start()
        }
    }

    public func download(_ download: Downloading, changedState downloadState: DownloadingState) {
        os_log("%@ - %d [state: %@]", log: KZRemoteAudioPlayerNode.logger, type: .debug, #function, #line, String(describing: downloadState))
    }

    public func download(_ download: Downloading, didReceiveData data: Data, progress: Float) {
        os_log("%@ - %d", log: KZRemoteAudioPlayerNode.logger, type: .debug, #function, #line)

        guard let parser = parser else {
            os_log("Expected parser, bail...", log: KZRemoteAudioPlayerNode.logger, type: .error)
            return
        }

        /// Parse the incoming audio into packets
        do {
            let chunkSize = 8192
            try stride(from: 0, to: data.count, by: chunkSize).forEach {
                let end = min($0 + chunkSize, data.count)
                try parser.parse(data: data[$0..<end])
            }
        } catch {
            os_log("Failed to parse: %@", log: KZRemoteAudioPlayerNode.logger, type: .error, error.localizedDescription)
        }

        /// Once there's enough data to start producing packets we can use the data format
        if reader == nil && parser.dataFormat != nil {
            do {
                reader = try Reader(parser: parser, readFormat: readFormat)
            } catch {
                os_log("Failed to create reader: %@", log: KZRemoteAudioPlayerNode.logger, type: .error, error.localizedDescription)
            }
        }

        /// Update the progress UI
        DispatchQueue.main.async {
            [weak self] in

            // Notify the delegate of the new progress value of the download
            self?.notifyDownloadProgress(progress)

            // Check if we have the duration
            self?.handleDurationUpdate()
        }
    }

    public func download(_ download: Downloading, shouldHoldDataForURL url: URL) -> Bool {
        return ["m4a", "mp3"].contains(url.pathExtension)
    }

    public func download(_ download: Downloading, didSaveDataToURL url: URL) {
        delegate?.streamer(self, didResolveDownloadTo: url)
    }

}
