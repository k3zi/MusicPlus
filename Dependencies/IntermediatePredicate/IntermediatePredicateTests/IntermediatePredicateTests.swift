//
//  IntermediatePredicateTests.swift
//  IntermediatePredicateTests
//
//  Created by kezi on 2019/01/24.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import XCTest
@testable import IntermediatePredicate

@objcMembers
class Apple: NSObject {

    let type = "Fuji"

}

class IntermediatePredicateTests: XCTestCase {

    func testEmpty() {
        let test = NSPredicate.form(with: Any.self)
        XCTAssertEqual(test.stringResult, "")
    }

    func testPropertyMatchesInt() {
        let test = NSPredicate.form(with: Any.self)
            .property("count").matches(5)
        XCTAssertEqual(test.stringResult, "count MATCHES 5")
    }

    func testPropertyMatchesString() {
        let test = NSPredicate.form(with: Any.self)
            .property("name").matches("John Doe")
        XCTAssertEqual(test.predicateResult, NSPredicate(format: "name MATCHES %@", argumentArray: ["John Doe"]))
    }

    func testPropertyKeyPath() {
        let test = NSPredicate.form(with: Apple.self)[\.type].matches("Fuji")
        XCTAssertEqual(test.predicateResult, NSPredicate(format: "type MATCHES %@", argumentArray: ["Fuji"]))
    }

    func testPropertyOrProperty() {
        let test = NSPredicate.form(with: Apple.self)[\.type].matches("Fuji")
            .or[\.type].matches("Gala")
        XCTAssertEqual(test.predicateResult, NSPredicate(format: "type MATCHES %@ OR type MATCHES %@", argumentArray: ["Fuji", "Gala"]))
    }

}
