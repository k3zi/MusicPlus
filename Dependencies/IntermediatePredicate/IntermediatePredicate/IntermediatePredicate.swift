//
//  NSIntermediatePredicate.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/23.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

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

    var prefixableResult: String {
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
        case is Bool:
            return value as! Bool ? "YES" : "NO"
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
        return !flags.isEmpty ? "[\(flags.joined())]" : ""
    }

    internal func generateBinaryConnector(with symbol: String, value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        let flagString = generateFlags(caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
        return Connector("\(result) \(symbol)\(flagString) \(escaped(value: value))")
    }

    func equal(to value: Any) -> Connector {
        return generateBinaryConnector(with: "==", value: value)
    }

    func notEqual(to value: Any) -> Connector {
        return generateBinaryConnector(with: "!=", value: value)
    }

    func greater(than value: Any) -> Connector {
        return generateBinaryConnector(with: ">", value: value)
    }

    func greaterThanOrEqual(to value: Any) -> Connector {
        return generateBinaryConnector(with: ">=", value: value)
    }

    func less(than value: Any) -> Connector {
        return generateBinaryConnector(with: "<", value: value)
    }

    func lessThanOrEqual(to value: Any) -> Connector {
        return generateBinaryConnector(with: "<=", value: value)
    }

    func containing(_ value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        return generateBinaryConnector(with: "CONTAINS", value: value, caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
    }

    func notContaining(_ value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        return generateBinaryConnector(with: "NOT CONTAINS", value: value, caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
    }

    func begins(with value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        return generateBinaryConnector(with: "BEGINSWITH", value: value, caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
    }

    func ends(with value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        return generateBinaryConnector(with: "ENDSWITH", value: value, caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
    }

    func like(_ value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        return generateBinaryConnector(with: "LIKE", value: value, caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
    }

    func matches(_ value: Any, caseInsensitive: Bool = false, diacriticInsensitive: Bool = false) -> Connector {
        return generateBinaryConnector(with: "MATCHES", value: value, caseInsensitive: caseInsensitive, diacriticInsensitive: diacriticInsensitive)
    }

}

extension NSPredicate {

    public class func with<T>(type: T.Type) -> IntermediatePredicateStart<T> {
        return .init()
    }

}
