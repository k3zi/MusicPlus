//
//  Connection.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import XMLMapper
import AwaitKit
import PromiseKit

class Connection: XMLMappable {
    var nodeName: String!
    var plex: KZPlex!
    var device: Device!

    var address: String!
    var local: Bool!
    var port: Int!
    var `protocol`: String!
    var relay: Bool!
    var uri: String!

    required init?(map: XMLMap) {}

    func mapping(map: XMLMap) {
        address <- map.attributes["address"]
        local <- (map.attributes["local"], XMLBoolFromIntTransform())
        port <- map.attributes["port"]
        `protocol` <- map.attributes["protocol"]
        relay <- (map.attributes["relay"], XMLBoolFromIntTransform())
        uri <- map.attributes["uri"]
    }

    func sections() -> Promise<LibrarySectionsGETResponse?> {
        return async {
            do {
                let result = try await(self.plex.get(KZPlex.Path.library(self).sections, token: self.device.accessToken))

                guard let data = String(bytes: result.data, encoding: .utf8) else {
                    throw KZPlex.Error.dataParsingError
                }

                guard let response = LibrarySectionsGETResponse(XMLString: data) else {
                    throw KZPlex.Error.dataParsingError
                }

                response.plex = self.plex
                response.directories.forEach {
                    $0.connection = self
                    $0.device = self.device
                }
                return response
            } catch {
                print(error)
            }

            return nil
        }
    }
}
