//
//  NSIntermediatePredicate.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/23.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
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
        result = "\(intermediateResult)  \(connector.rawValue)"
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

    subscript(_ keyPath: String) -> IntermediatePredicateQuery<Base, Any> {
        return property(keyPath)
    }

    subscript<Value>(_ keyPath: KeyPath<Base, Value>) -> IntermediatePredicateQuery<Base, Value> where Base : NSObject {
        return property(keyPath)
    }

    func property(_ keyPath: String) -> IntermediatePredicateQuery<Base, Any> {
        return IntermediatePredicateQuery<Base, Any>("\(prefixableResult)\(keyPath)")
    }

    func property<Value>(_ keyPath: KeyPath<Base, Value>) -> IntermediatePredicateQuery<Base, Value> where Base : NSObject {
        return IntermediatePredicateQuery<Base, Value>("\(prefixableResult)\(NSExpression(forKeyPath: keyPath).keyPath)")
    }

}

public struct IntermediatePredicateQuery<T, Value>: IntermediatePredicateResult {

    typealias Connector = IntermediatePredicateConnector<T>

    internal let result: String

    internal init(_ intermediateResult: String) {
        result = intermediateResult
    }

    internal func escaped(value: Value) -> String {
        if let value = value as? String {
            return "\"\(value)\""
        }

        return "\(value)"
    }

    func matches(_ value: Value) -> Connector {
        return Connector("\(result) MATCHES \(escaped(value: value))")
    }

}

extension NSPredicate {

    public class func form<T>(with type: T.Type) -> IntermediatePredicateStart<T> {
        return IntermediatePredicateStart<T>()
    }

}
