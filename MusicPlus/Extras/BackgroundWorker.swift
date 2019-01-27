//
//  BackgroundWorker.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

class BackgroundWorker: NSObject {
    private var thread: Thread!
    private var block: (() -> Void)!

    @objc internal func runBlock() { block() }

    public func start(_ block: @escaping () -> Void) {
        self.block = block

        let threadName = String(describing: self).components(separatedBy: .punctuationCharacters)[1]

        thread = Thread { [weak self] in
            while let self = self, !self.thread.isCancelled {
                RunLoop.current.run(mode: .default, before: Date.distantFuture)
            }
            Thread.exit()
        }
        thread.name = "\(threadName)-\(UUID().uuidString)"
        thread.start()

        perform(#selector(runBlock), on: thread, with: nil, waitUntilDone: false, modes: [RunLoop.Mode.default.rawValue])
    }

    public func stop() {
        thread.cancel()
    }
}
