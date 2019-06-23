//
//  Strings.swift
//  MusicPlus
//
//  Created by kezi on R 1/06/22.
//  Copyright © Reiwa 1 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

enum Strings {

    enum Placeholders { }
    enum Titles {}

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
