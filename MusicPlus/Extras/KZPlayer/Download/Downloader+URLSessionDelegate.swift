//
//  Downloader+URLSessionDelegate.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import os.log

extension Downloader: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)

        totalBytesCount = response.expectedContentLength
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        os_log("function: %@ - line number: %d data count: %d", log: Downloader.logger, type: .debug, #function, #line, data.count)

        var resultingData = data
        if bytesToSkip >= data.count {
            bytesToSkip -= Int64(data.count)
            return
        } else if bytesToSkip > 0 {
            resultingData = data.advanced(by: Int(bytesToSkip))
            bytesToSkip = 0
        }

        totalBytesReceived += Int64(resultingData.count)
        progress = Float(totalBytesReceived) / Float(totalBytesCount)
        delegate?.download(self, didReceiveData: resultingData, progress: progress)
        progressHandler?(resultingData, progress)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        os_log("%@ - %d", log: Downloader.logger, type: .debug, #function, #line)

        if let error = error, !error.isCancelled, let url = url {
            bytesToSkip = totalBytesReceived
            self.task = session.dataTask(with: url)
            self.task?.resume()
            return
        }

        state = .completed
        delegate?.download(self, completedWithError: error)
        completionHandler?(error)
    }
}
