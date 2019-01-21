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

class PlexRealmLibraryConfig: Object, RealmGenerating {

    @objc dynamic var authToken: String = ""
    @objc dynamic var clientIdentifier: String = ""
    @objc dynamic var dircetoryUUID: String = ""

    @objc dynamic var connectionURI: String = ""

    convenience init(authToken: String, clientIdentifier: String, dircetoryUUID: String, connectionURI: String) {
        self.init()
        self.authToken = authToken
        self.clientIdentifier = clientIdentifier
        self.dircetoryUUID = dircetoryUUID
        self.connectionURI = connectionURI
    }

    func realmGenerator() -> (() -> Realm?) {
        return {
            return Realm.main
        }
    }

}
