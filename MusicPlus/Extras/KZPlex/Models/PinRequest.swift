//
//  PinRequest.swift
//  Music+
//
//  Created by kezi on 2018/10/25.
//  Copyright © 2018 Kesi Maduka. All rights reserved.
//

import Foundation

class PinRequest: Codable, CustomStringConvertible {
    let id: Int
    let code: String
    let expiresAt: Date
    let userId: Int?
    let clientIdentifier: String
    let trusted: Bool
    let authToken: String?
}
