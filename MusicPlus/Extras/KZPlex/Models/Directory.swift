//
//  Directory.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper
import PromiseKit
import AwaitKit

enum DirectoryType: String {
    case artist
    case movie
    case show
}

class Directory: XMLMappable, Hashable {

    static func == (lhs: Directory, rhs: Directory) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    var nodeName: String!
    var plex: KZPlex!
    var device: Device!

    var allowSync: Bool!
    var art: String!
    var composite: String!
    var filters: Bool!
    var refreshing: Bool!
    var thumb: String!
    var key: Int!
    var type: DirectoryType!
    var title: String!
    var agent: String!
    var scanner: String!
    var language: String!
    var uuid: String!

    var updatedAt: Date!
    var createdAt: Date!
    var scannedAt: Date!

    var locations: [Location]!
    var connection: Connection!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        allowSync <- (map.attributes["allowSync"], XMLBoolFromIntTransform())
        art <- map.attributes["art"]
        composite <- map.attributes["composite"]
        filters <- (map.attributes["filters"], XMLBoolFromIntTransform())
        refreshing <- (map.attributes["refreshing"], XMLBoolFromIntTransform())
        thumb <- map.attributes["thumb"]
        key <- map.attributes["key"]
        type <- map.attributes["type"]
        title <- map.attributes["title"]
        agent <- map.attributes["agent"]
        scanner <- map.attributes["scanner"]
        language <- map.attributes["language"]
        uuid <- map.attributes["uuid"]

        updatedAt <- (map.attributes["updatedAt"], XMLDateTransform())
        createdAt <- (map.attributes["createdAt"], XMLDateTransform())
        scannedAt <- (map.attributes["scannedAt"], XMLDateTransform())

        locations <- map["Location"]
    }

    func all() -> Promise<LibrarySectionsAllGETResponse> {
        return async {
            let url = "\(KZPlex.Path.library(self.connection).section(id: self.key).all)?type=10&includeRelated=1&includeCollections=1"
            let result = try await(self.plex.get(url, token: self.device.accessToken))

            guard let data = String(bytes: result.data, encoding: .utf8) else {
                throw KZPlex.Error.dataParsingError
            }

            guard let response = LibrarySectionsAllGETResponse(XMLString: data) else {
                throw KZPlex.Error.dataParsingError
            }

            response.plex = self.plex
            response.tracks.forEach {
                $0.directory = self
                $0.connection = self.connection
                $0.plex = self.plex
                $0.device = self.device
            }
            return response
        }
    }

    func syncItems(syncItemId: Int) -> Promise<LibrarySectionsAllGETResponse> {
        return async {
            let url = KZPlex.Path.library(self.connection).syncItems(id: syncItemId)
            let result = try await(self.plex.get(url, token: self.device.accessToken))

            guard let data = String(bytes: result.data, encoding: .utf8) else {
                throw KZPlex.Error.dataParsingError
            }

            guard let response = LibrarySectionsAllGETResponse(XMLString: data) else {
                throw KZPlex.Error.dataParsingError
            }

            response.plex = self.plex
            response.tracks.forEach {
                $0.directory = self
                $0.connection = self.connection
                $0.plex = self.plex
                $0.device = self.device
            }
            return response
        }
    }
}
