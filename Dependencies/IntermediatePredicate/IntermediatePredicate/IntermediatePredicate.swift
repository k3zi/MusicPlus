//
//  NSIntermediatePredicate.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/23.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

// Start = no or/and
// Connector = yes or/and
// End = yes no/end

enum IntermediatePredicateConnectorType: String {
    case or = "OR"
    case and = "AND"
}

public struct IntermediatePredicateStart<T>: IntermediatePredicateQueryable, IntermediatePredicateResult {

    public typealias Base = T

    public let result: String

    internal init() {
        result = ""
    }

    internal init(_ intermediateResult: String) {
        result = intermediateResult
    }

}

public struct IntermediatePredicateEnd<T>: IntermediatePredicateQueryable {

    public typealias Base = T

    public let result: String

    internal init() {
        result = ""
    }

    fileprivate init(_ intermediateResult: String, connector: IntermediatePredicateConnectorType) {
        result = [intermediateResult, connector.rawValue].joined(separator: " ")
    }

}

public struct IntermediatePredicateConnector<T>: IntermediatePredicateResult {

    typealias End = IntermediatePredicateEnd<T>

    internal let result: String

    internal init(_ intermediateResult: String) {
        result = intermediateResult
    }

    var or: End {
        return End(result, connector: .or)
    }
    var and: End {
        return End(result, connector: .and)
    }

}

protocol IntermediatePredicateResult {

    var result: String { get }

}

extension IntermediatePredicateResult {

    internal var prefixableResult: String {
        return result.isEmpty ? "" : "\(result) "
    }

    var stringResult: String {
        return result
    }

    var predicateResult: NSPredicate {
        return NSPredicate(format: result)
    }

}

public protocol IntermediatePredicateQueryable {

    associatedtype Base

    var result: String { get }

}

fileprivate extension IntermediatePredicateQueryable {

    fileprivate var prefixableResult: String {
        return result.isEmpty ? "" : "\(result) "
    }

}

public extension IntermediatePredicateQueryable {

    subscript(_ keyPath: String) -> IntermediatePredicateQuery<Base> {
        return property(keyPath)
    }

    subscript<Value>(_ keyPath: KeyPath<Base, Value>) -> IntermediatePredicateQuery<Base> where Base: NSObject {
        return property(keyPath)
    }

    func property(_ keyPath: String) -> IntermediatePredicateQuery<Base> {
        return IntermediatePredicateQuery<Base>("\(prefixableResult)\(keyPath)")
    }

    func property<Value>(_ keyPath: KeyPath<Base, Value>) -> IntermediatePredicateQuery<Base> where Base: NSObject {
        return IntermediatePredicateQuery<Base>("\(prefixableResult)\(NSExpression(forKeyPath: keyPath).keyPath)")
    }

}

public struct IntermediatePredicateQuery<T>: IntermediatePredicateResult {

    typealias Connector = IntermediatePredicateConnector<T>

    internal let result: String

    internal init(_ intermediateResult: String) {
        result = intermediateResult
    }

    internal func escaped(value: Any) -> String {
        switch value {
        case is String:
            return "\"\(value)\""
        default:
            return "\(value)"
        }
    }

    internal func generateFlags(caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> String {
        var flags = [String]()
        if caseInsensitive {
            flags.append("c")
        }
        if diacriticInsensitive {
            flags.append("d")
        }
        return flags.isNotEmpty ? "[\(flags.joined())]" : ""
    }

    func equal(to value: Any) -> Connector {
        return Connector("\(result) == \(escaped(value: value))")
    }

    func notEqual(to value: Any) -> Connector {
        return Connector("\(result) != \(escaped(value: value))")
    }

    func greater(than value: Any) -> Connector {
        return Connector("\(result) > \(escaped(value: value))")
    }

    func greater(thanOrEqualTo value: Any) -> Connector {
        return Connector("\(result) >= \(escaped(value: value))")
    }

    func less(than value: Any) -> Connector {
        return Connector("\(result) < \(escaped(value: value))")
    }

    func less(thanOrEqualTo value: Any) -> Connector {
        return Connector("\(result) <= \(escaped(value: value))")
    }

    func containing(_ value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        let flagString = generateFlags(caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
        return Connector("\(result) CONTAINS\(flagString) \(escaped(value: value))")
    }

    func notContaining(_ value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        let flagString = generateFlags(caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
        return Connector("\(result) NOT CONTAINS\(flagString) \(escaped(value: value))")
    }

    func begins(with value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        let flagString = generateFlags(caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
        return Connector("\(result) BEGINSWITH\(flagString) \(escaped(value: value))")
    }

    func ends(with value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        let flagString = generateFlags(caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
        return Connector("\(result) ENDSWITH\(flagString) \(escaped(value: value))")
    }

    func matches(_ value: Any) -> Connector {
        return Connector("\(result) MATCHES \(escaped(value: value))")
    }

}

extension NSPredicate {

    public class func form<T>(with type: T.Type) -> IntermediatePredicateStart<T> {
        return .init()
    }

}
