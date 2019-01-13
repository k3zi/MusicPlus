// 
//  Constants.swift
//  Music+
// 
//  Created by Kesi Maduka on 7/25/15.
//  Copyright (c) 2015 Storm Edge Apps LLC. All rights reserved.
// 

import Foundation
import CoreLocation
import CoreImage
import MediaPlayer

// MARK: Constants
// swiftlint:disable nesting
// swiftlint:disable type_name

typealias KZPlayerItemCollection = AnyRealmCollection<KZPlayerItem>

struct Constants {

	struct Config {

	}

    struct Settings {
        static let libraries = "libraries"
        static let localLibraries = "localLibraries"
        static let plexLibraries = "plexLibraries"
    }

	struct Notification {
        static let hidePopup = NSNotification.Name(rawValue: "MPNotificationHidePopup")
        static let libraryDidChange = NSNotification.Name(rawValue: "MPNotificationLibraryDidChange")
        static let libraryDataDidChange = NSNotification.Name(rawValue: "MPNotificationLibraryDataDidChange")
        static let backgroundImageDidChange = NSNotification.Name(rawValue: "MPNotificationBackgroundImageDidChange")
        static let tintColorDidChange = NSNotification.Name(rawValue: "MPNotificationTintColorDidChange")
	}

    struct Observation {
        static let outputVolume = "outputVolume"
    }

	struct Network {
	}

    struct UI {

        struct Animation {
            static let menuSlide =  TimeInterval(0.3)
            static let imageFade = TimeInterval(0.5)
            static let cellHighlight = TimeInterval(0.3)
            static let controllerPushPop = TimeInterval(0.5)
        }

        struct Color {
            static let defaultTint = RGB(56, g: 155, b: 225)
            static let gray = RGB(198)
        }

        struct Image {
            static let defaultBackground = #imageLiteral(resourceName: "defaultBackground")
        }

        struct Screen {
            static let width = UIScreen.main.bounds.width
            static let height = UIScreen.main.bounds.height
            static let bounds = UIScreen.main.bounds

            static func keyboardAdjustment(_ show: Bool, rect: CGRect) -> CGFloat {
                guard show else {
                    return 0.0
                }

                let height = -rect.size.height

                return height
            }
        }

        struct Navigation {
            static let menuWidth: CGFloat = 120
        }

    }
}

@IBDesignable class ExtendedButton: UIButton {
	@IBInspectable var verticalTouchMargin: CGFloat = 20.0
    @IBInspectable var horizontalTouchMargin: CGFloat = 20.0

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let extendedArea = self.bounds.insetBy(dx: -horizontalTouchMargin, dy: -verticalTouchMargin)
		return extendedArea.contains(point)
	}
}

/**
 Delays code excecution

 - parameter delay:   The number of seconds to delay for
 - parameter closure: The block to be executed after the delay
 */
func delay(_ delay: Double, closure: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

extension UIButton {

    open override var intrinsicContentSize: CGSize {
		let intrinsicContentSize = super.intrinsicContentSize
		let adjustedWidth = intrinsicContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right
		let adjustedHeight = intrinsicContentSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom
		return CGSize(width: adjustedWidth, height: adjustedHeight)
	}

}

extension UITableView {

    func scrollToBottom(_ animated: Bool = true) {
        let section = self.numberOfSections
        guard section > 0 else {
            return
        }

        let row = self.numberOfRows(inSection: section - 1)
        guard row > 0 else {
            return
        }

        let index = IndexPath(row: row - 1, section: section - 1)
        self.scrollToRow(at: index, at: .bottom, animated: animated)
    }

}

extension UIView {

	class func lineWithBGColor(_ backgroundColor: UIColor, vertical: Bool = false, lineHeight: CGFloat = 1.0) -> UIView {
		let view = UIView()
        NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999)) { () -> Void in
			view.autoSetDimension(vertical ? .width : .height, toSize: (lineHeight / UIScreen.main.scale))
		}
		view.backgroundColor = backgroundColor
		return view
	}

    func estimatedHeight(_ maxWidth: CGFloat) -> CGFloat {
        return self.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)).height
    }

}

extension AnyRealmCollection: Equatable where Element: Equatable {
    public static func == (lhs: AnyRealmCollection<Element>, rhs: AnyRealmCollection<Element>) -> Bool {
        return lhs.count == rhs.count && lhs.allSatisfy({ lhs.index(of: $0) == rhs.index(of: $0) })
    }
}

extension Int {

    func hexedString() -> String {
        return String(format: "%02x", self)
    }

   func formatUsingAbbrevation() -> String {
        let numFormatter = NumberFormatter()

        typealias Abbrevation = (threshold: Double, divisor: Double, suffix: String)
        let abbreviations: [Abbrevation] = [(0, 1, ""),
                                           (1000.0, 1000.0, "K"),
                                           (100_000.0, 1_000_000.0, "M"),
                                           (100_000_000.0, 1_000_000_000.0, "B")]

        let startValue = Double(abs(self))
        let abbreviation: Abbrevation = {
            var prevAbbreviation = abbreviations[0]
            for tmpAbbreviation in abbreviations {
                if startValue < tmpAbbreviation.threshold {
                    break
                }
                prevAbbreviation = tmpAbbreviation
            }
            return prevAbbreviation
        }()

        let value = Double(self) / abbreviation.divisor
        numFormatter.positiveSuffix = abbreviation.suffix
        numFormatter.negativeSuffix = abbreviation.suffix
        numFormatter.allowsFloats = true
        numFormatter.minimumIntegerDigits = 1
        numFormatter.minimumFractionDigits = 0
        numFormatter.maximumFractionDigits = 1

        return numFormatter.string(from: NSNumber (value: value as Double)) ?? ""
    }

}

extension Calendar {

    private static let _randomDate = Date()

    func timeIntervalOf(_ component: Calendar.Component) -> TimeInterval {
        let elapsedDate = date(byAdding: component, value: 1, to: Calendar._randomDate)!
        return TimeInterval(dateComponents([.second], from: Calendar._randomDate, to: elapsedDate).second!)
    }

}

extension Date {
    func shortRelativeDate() -> String {

        let timeInterval = -self.timeIntervalSinceNow

        let calendar = Calendar.current
        let oneMinute = calendar.timeIntervalOf(.minute)
        let oneHour = calendar.timeIntervalOf(.hour)
        let oneDay = calendar.timeIntervalOf(.day)
        let oneYear = calendar.timeIntervalOf(.year)

        switch timeInterval {
        case 0..<oneMinute:
            return String(format: "%.fs", timeInterval)
        case oneMinute..<oneHour:
            return String(format: "%.fm", timeInterval / 60)
        case oneHour..<oneDay:
            return String(format: "%.fh", timeInterval / (60 * 60))
        case oneDay..<oneYear:
            return String(format: "%.fd", timeInterval / (60 * 60 * 24))
        default:
            return String(format: "%.fy", timeInterval / (60 * 60 * 24 * 365))
        }
    }
}

extension Data {
    private static let CHexLookup: [Character] =
        [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" ]

    // MARK: - Public methods

    /// Method to convert a byte array into a string containing hex characters, without any
    /// additional formatting.
    public static func byteArrayToHexString(_ byteArray: [UInt8]) -> String {

        var stringToReturn = ""

        for oneByte in byteArray {
            let asInt = Int(oneByte)
            stringToReturn.append(CHexLookup[asInt >> 4])
            stringToReturn.append(CHexLookup[asInt & 0x0f])
        }

        return stringToReturn
    }

    func hexedString() -> String {
        return Data.byteArrayToHexString([UInt8](self))
    }

    func MD5() -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        _ = withUnsafeBytes { (body: UnsafePointer<UInt8>) in
            CC_MD5(body, CC_LONG(self.count), &digest)
        }

        return Data(digest)
    }

    func SHA256() -> Data {
        let length = Int(CC_SHA256_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        _ = withUnsafeBytes { (body: UnsafePointer<UInt8>) in
            CC_SHA256(body, CC_LONG(self.count), &digest)
        }

        return Data(digest)
    }

}

extension String {

    func MD5() -> String {
        return (self as NSString).data(using: String.Encoding.utf8.rawValue)!.MD5().hexedString()
    }

    func SHA256() -> String {
        return (self as NSString).data(using: String.Encoding.utf8.rawValue)!.SHA256().hexedString()
    }

    static func random(length: Int) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""

        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }

    var isNotEmpty: Bool {
        return !isEmpty
    }

}

extension UIImage {

    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }

}

extension UIViewController {

    func donePressed() {
        cancelPressed()
    }

    func cancelPressed() {
        view.endEditing(true)
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func dismissPopup() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension UIScrollView {
    func dg_stopScrollingAnimation() {}
}

extension UIColor {

    var hexString: String {
        guard let components = self.cgColor.components else {
            return "000000"
        }

        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
    }

    open class var nativeBlue: UIColor {
        return RGB(0, g: 122, b: 255)
    }

}

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

extension MutableCollection where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 {
            return
        }

        for i in startIndex ..< endIndex - 1 {
            let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i
            if i != j {
                self.swapAt(i, j)
            }
        }
    }
}

extension MutableCollection where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffle() -> Self {
        var r = self
        if count < 2 {
            return r
        }

        for i in startIndex ..< endIndex - 1 {
            let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i
            if i != j {
                r.swapAt(i, j)
            }
        }

        return r
    }
}

func resizeImage(_ image: UIImage, newWidth: CGFloat) -> UIImage {
    let newWidth = round(newWidth)
    let scale = newWidth / image.size.width
    if scale < 1.0 {
        let newHeight = round(image.size.height * scale)
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    return image
}

func numberOfLinesInLabel(_ yourString: String, labelWidth: CGFloat, labelHeight: CGFloat, font: UIFont) -> Int {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.minimumLineHeight = labelHeight
    paragraphStyle.maximumLineHeight = labelHeight
    paragraphStyle.lineBreakMode = .byWordWrapping

    let attributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: paragraphStyle]

    let constrain = CGSize(width: labelWidth, height: CGFloat(Float.infinity))

    let size = yourString.size(withAttributes: attributes)
    let stringWidth = size.width

    let numberOfLines = ceil(Double(stringWidth/constrain.width))

    return Int(numberOfLines)
}

extension DispatchQueue {

    func ensureMainThread(call: () -> Void) {
        if Thread.isMainThread {
            call()
        } else {
            DispatchQueue.main.sync(execute: call)
        }
    }

}

extension MPMediaItemArtwork {

    static let `default` = MPMediaItemArtwork(boundsSize: .zero) { _ in
        return #imageLiteral(resourceName: "defaultArtwork")
    }

}

extension Sequence where Iterator.Element: Hashable {
    var uniqueElements: [Iterator.Element] {
        return Array(Set(self))
    }
}

extension Results {

    /// Converts the results object to the AnyRealmCollection wrapper
    ///
    /// - Returns: An `AnyRealmCollection` wrapped around `self`
    func toAny() -> AnyRealmCollection<Element> {
        return AnyRealmCollection(self)
    }

}

extension DispatchQueue {
    class func mainSyncSafe(execute work: () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

    class func mainSyncSafe<T>(execute work: () throws -> T) rethrows -> T {
        if Thread.isMainThread {
            return try work()
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }
}
