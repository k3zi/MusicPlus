//
//  UserDefaults+Codable.swift
//  Music+
//
//  Created by kezi on 2019/01/05.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

public extension UserDefaults {

    /// Set UserDefaults object for key to value of Codable object
    ///
    /// - Parameters:
    ///   - object: Codable Object
    ///   - forKey: Key string
    /// - Throws: UserDefaults Error
    public func set<T: Codable>(object: T, forKey: String) throws {
        set(try JSONEncoder().encode(object), forKey: forKey)
    }

    /// Get Codable object for specified key from UserDefaults
    ///
    /// - Parameters:
    ///   - object: Codable Object
    ///   - forKey: Key string
    /// - Throws: UserDefaults Error
    public func get<T: Codable>(objectType: T.Type, forKey: String) throws -> T? {
        guard let result = value(forKey: forKey) as? Data else {
            return nil
        }

        return try JSONDecoder().decode(objectType, from: result)
    }
}
