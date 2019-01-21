//
//  KZPlayerItemBase+Analyze.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/19.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import aubio

extension KZPlayerItemBase {

    func analyzeAudio() {
        guard bpm == 0.0 || lastBeatPosition == 0.0 else {
            return
        }

        let url = fileURL()
        guard url.isFileURL else {
            return
        }

        let path = url.path
        let accuracy: uint_t = 2 // 1-10??
        let win_size: uint_t = 1024
        let hop_size: uint_t = win_size / accuracy
        let input = new_fvec(hop_size)
        let output = new_fvec(2)
        let source = new_aubio_source(path, 0, hop_size)
        print("")
        print("analyzed sample rate: \(aubio_source_get_samplerate(source))")
        print("analyzed channels: \(aubio_source_get_channels(source))")
        print("analyzed duration: \(aubio_source_get_duration(source))")
        let tempo = new_aubio_tempo("default", win_size, hop_size, aubio_source_get_samplerate(source))
        var read: uint_t = 0
        var total_frames: uint_t = 0
        var firstBeatPosition = 0.0
        while true {
            aubio_source_do(source, input, &read)
            aubio_tempo_do(tempo, input, output)
            if firstBeatPosition == 0 {
                firstBeatPosition = Double(aubio_tempo_get_last_s(tempo))
            }
            total_frames += read
            if read < hop_size { break }
        }

        try! realm?.write {
            self.bpm = Double(aubio_tempo_get_bpm(tempo))
            self.firstBeatPosition = firstBeatPosition
            self.lastBeatPosition = Double(aubio_tempo_get_last_s(tempo))
        }

        print("analyzed a bpm of: \(bpm)")
        print("analyzed a first beat of: \(firstBeatPosition)")
        print("analyzed a last beat of: \(lastBeatPosition)")
        print("total duration: \(duration())")
        print("")

        del_aubio_tempo(tempo)
        del_aubio_source(source)
        del_fvec(input)
        del_fvec(output)
    }

}
