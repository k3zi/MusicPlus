//
//  PlexLibraryConfig.swift
//  Music+
//
//  Created by kezi on 2019/01/09.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

class PlexLibraryConfig: Codable {
    let authToken: String
    let clientIdentifier: String
    let dircetoryUUID: String

    var connectionURI: String

    init(authToken: String, clientIdentifier: String, dircetoryUUID: String, connectionURI: String) {
        self.authToken = authToken
        self.clientIdentifier = clientIdentifier
        self.dircetoryUUID = dircetoryUUID
        self.connectionURI = connectionURI
    }
}
