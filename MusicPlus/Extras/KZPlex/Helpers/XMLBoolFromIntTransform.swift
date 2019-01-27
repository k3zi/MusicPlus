//
//  XMLBoolFromIntTransform.swift
//  Music+
//
//  Created by kezi on 2019/01/06.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import XMLMapper

open class XMLBoolFromIntTransform: XMLTransformType {
    public typealias Object = Bool
    public typealias XML = String

    public init() {}

    open func transformFromXML(_ value: Any?) -> Bool? {
        guard let boolStr = value as? String else {
            return nil
        }

        if boolStr == "0" {
            return false
        }

        if boolStr == "1" {
            return true
        }

        return nil
    }

    open func transformToXML(_ value: Bool?) -> String? {
        if let bool = value {
            return bool ? "1" : "0"
        }
        return nil
    }
}
