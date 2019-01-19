//
//  KZPlayerItemBase.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/19.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import MediaPlayer

protocol KZPlayerItemBase: class, RealmGenerating, ThreadConfined {

    var orig: KZPlayerItem? { get }

    var title: String { get set }
    var albumArtist: String { get set }
    var genre: String { get set }
    var composer: String { get set }
    var assetURL: String { get set }
    var artworkURL: String { get set }
    var systemID: String { get set }
    var plexLibraryUniqueIdentifier: String { get set }

    var localAssetURL: String? { get set }

    var trackNum: Int { get set }
    var playCount: Int { get set }
    var position: Int { get set }

    var startTime: Double { get set }
    var endTime: Double { get set }
    var tempo: Double { get set }
    var bpm: Double { get set }
    var lastBeatPosition: Double { get set }
    var firstBeatPosition: Double { get set }

    var liked: Bool { get set }
    var isDocumentURL: Bool { get set }

    var tags: List<KZPlayerTag> { get }

    var artist: KZPlayerArtist? { get set }
    var album: KZPlayerAlbum? { get set }
    var plexTrack: KZPlayerPlexTrack? { get set }

    func fileURL() -> URL

    func fetchArtwork(completionHandler: @escaping (_ artwork: MPMediaItemArtwork) -> Void)
}

extension KZPlayerItemBase {
    var title: String {
        get { return orig!.title }
        set { orig!.title = newValue }
    }
    var albumArtist: String {
        get { return orig!.albumArtist }
        set { orig!.albumArtist = newValue }
    }
    var genre: String {
        get { return orig!.genre }
        set { orig!.genre = newValue }
    }
    var composer: String {
        get { return orig!.composer }
        set { orig!.composer = newValue }
    }
    var assetURL: String {
        get { return orig!.assetURL }
        set { orig!.assetURL = newValue }
    }
    var artworkURL: String {
        get { return orig!.artworkURL }
        set { orig!.artworkURL = newValue }
    }
    var systemID: String {
        get { return orig!.systemID }
        set { orig!.title = systemID }
    }
    var plexLibraryUniqueIdentifier: String {
        get { return orig!.plexLibraryUniqueIdentifier }
        set { orig!.plexLibraryUniqueIdentifier = newValue }
    }

    var localAssetURL: String? {
        get { return orig!.localAssetURL }
        set { orig!.localAssetURL = newValue }
    }

    var trackNum: Int {
        get { return orig!.trackNum }
        set { orig!.trackNum = newValue }
    }
    var playCount: Int {
        get { return orig!.playCount }
        set { orig!.playCount = newValue }
    }

    var startTime: Double {
        get { return orig!.startTime }
        set { orig!.startTime = newValue }
    }
    var endTime: Double {
        get { return orig!.endTime }
        set { orig!.endTime = newValue }
    }
    var tempo: Double {
        get { return orig!.tempo }
        set { orig!.tempo = newValue }
    }
    var bpm: Double {
        get { return orig!.bpm }
        set { orig!.bpm = newValue }
    }
    var firstBeatPosition: Double {
        get { return orig!.firstBeatPosition }
        set { orig!.firstBeatPosition = newValue }
    }
    var lastBeatPosition: Double {
        get { return orig!.lastBeatPosition }
        set { orig!.lastBeatPosition = newValue }
    }

    var liked: Bool {
        get { return orig!.liked }
        set { orig!.liked = newValue }
    }
    var isDocumentURL: Bool {
        get { return orig!.isDocumentURL }
        set { orig!.isDocumentURL = newValue }
    }

    var tags: List<KZPlayerTag> {
        get { return orig!.tags }
    }

    var artist: KZPlayerArtist? {
        get { return orig!.artist }
        set { orig!.artist = newValue }
    }
    var album: KZPlayerAlbum? {
        get { return orig!.album }
        set { orig!.album = newValue }
    }
    var plexTrack: KZPlayerPlexTrack? {
        get { return orig!.plexTrack }
        set { orig!.plexTrack = newValue }
    }

    var originalItem: KZPlayerItem {
        return orig!
    }

    func realmGenerator() -> (() -> Realm?) {
        // First aquire things that can not go across threads
        let identifier = plexLibraryUniqueIdentifier
        return {
            guard let library = KZPlexLibrary.plexLibraries.first(where: { $0.uniqueIdentifier == identifier }) else {
                return nil
            }

            return library.realm()
        }
    }

    func fileURL() -> URL {
        return originalItem.fileURL()
    }

    func realm() -> Realm? {
        return realmGenerator()()
    }

    func fetchArtwork(completionHandler: @escaping (_ artwork: MPMediaItemArtwork) -> Void) {
        orig?.fetchArtwork(completionHandler: completionHandler)
    }

    func duration() -> Double {
        return endTime - startTime
    }

    func artistName() -> String {
        let result = artist?.name ?? albumArtist
        return result.count > 0 ? result : "Unknown Artist"
    }

    func albumName() -> String {
        return album?.name ?? ""
    }

    func titleText() -> String {
        guard title.count > 0 else {
            return "Unknown Title"
        }

        return title
    }

    func subtitleText() -> String {
        let artist = albumArtist.count > 0 ? albumArtist : artistName()

        let text = [albumName(), artist].filter({ $0.count > 0 }).joined(separator: " - ")
        if text.count > 0 {
            return text
        }

        return "Unknown Metadata"
    }

    func firstUnplayedBeat(currentTime: Double) -> Double {
        self.analyzeAudio()
        guard bpm > 0 else {
            return currentTime
        }

        var result = lastBeatPosition
        let bps = bpm / 60.0
        while (result - bps) > currentTime {
            result -= bps
        }

        return result
    }
}
