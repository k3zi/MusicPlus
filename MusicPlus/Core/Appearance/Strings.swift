//
//  Strings.swift
//  MusicPlus
//
//  Created by kezi on R 1/06/22.
//  Copyright © Reiwa 1 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

enum Strings {

    enum Buttons { }
    enum Placeholders { }
    enum Titles { }

}

extension Strings.Buttons {

    static var ok: String {
        return NSLocalizedString("OK", comment: "")
    }

    static var shuffleAll: String {
        return NSLocalizedString("Shuffle All", comment: "")
    }

}

extension Strings.Placeholders {

    static var search: String {
        NSLocalizedString("Search", comment: "")
    }

}

extension Strings.Titles {

    static var songs: String {
        NSLocalizedString("Songs", comment: "")
    }

}
