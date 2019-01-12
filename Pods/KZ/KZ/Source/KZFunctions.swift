//
//  KZFunctions.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

public func RGB(_ r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) -> UIColor {
	return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
}

public func RGB(_ x: CGFloat, a: CGFloat = 1.0) -> UIColor {
	return RGB(x, g: x, b: x, a: a)
}

public func HEX(_ str: String) -> UIColor {
	let hex = str.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
	var int = UInt32()
	Scanner(string: hex).scanHexInt32(&int)
	let r, g, b: UInt32
	switch hex.count {
	case 3:
		(r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
	case 6:
		(r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
	default:
		(r, g, b) = (1, 1, 0)
	}

	return RGB(CGFloat(r), g: CGFloat(g), b: CGFloat(b))
}

public func delay(_ delay: Double, closure: @escaping () -> ()) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
