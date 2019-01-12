//
//  CustomStringConvertible.swift
//  Music+
//
//  Created by kezi on 2018/10/26.
//  Copyright © 2018 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

extension CustomStringConvertible {
    var description: String {
        var description = "\(type(of: self)) {\n"
        let selfMirror = Mirror(reflecting: self)
        for child in selfMirror.children {
            if let propertyName = child.label {
                description += "    \(propertyName): \(child.value)\n"
            }
        }
        description += "}\n"
        return description
    }
}
