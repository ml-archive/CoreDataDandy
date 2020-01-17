//
//  ConvertibleTypes.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 10/26/15.
//  Copyright © 2015 Fuzz Productions, LLC. All rights reserved.
//
//  This code is distributed under the terms and conditions of the MIT license.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

import Foundation

// MARK: - ConvertibleType -
protocol BooleanConvertible {
	func convertToBoolean() -> NSNumber?
}
protocol DateConvertible {
	func convertToDate() -> NSDate?
}
protocol DataConvertible {
	func convertToData() -> NSData?
}
protocol DoubleConvertible {
	func convertToDouble() -> NSNumber?
}
protocol DecimalConvertible {
	func convertToDecimal() -> NSDecimalNumber?
}
protocol FloatConvertible {
	func convertToFloat() -> NSNumber?
}
protocol IntConvertible {
	func convertToInt() -> NSNumber?
}
protocol StringConvertible {
	func convertToString() -> NSString?
}
protocol NumericConvertible: DoubleConvertible, DecimalConvertible, FloatConvertible, IntConvertible {}
protocol ConvertibleType: BooleanConvertible, DataConvertible, DateConvertible, NumericConvertible, StringConvertible {}

// MARK: - NSDate -
extension NSDate : DateConvertible, NumericConvertible, StringConvertible {
	func convertToDate() -> NSDate? {
		return self
	}
	func convertToDecimal() -> NSDecimalNumber? {
		return NSDecimalNumber(value: self.timeIntervalSince1970)
	}
	func convertToDouble() -> NSNumber? {
		return NSNumber(value: self.timeIntervalSince1970)
	}
	func convertToFloat() -> NSNumber? {
		return NSNumber(value: Float(self.timeIntervalSince1970))
	}
	func convertToInt() -> NSNumber? {
		return NSNumber(value: Int(round(self.timeIntervalSince1970)))
	}
	func convertToString() -> NSString? {
		return CoreDataValueConverter.dateFormatter.string(from: self as Date) as? NSString
	}
}
// MARK: - Data -
extension NSData : DataConvertible, StringConvertible {
	func convertToData() -> NSData? {
		return self
	}
	func convertToString() -> NSString? {
		return String(data: self as Data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) as NSString?
	}
}
// MARK: - NSNumber -
extension NSNumber: ConvertibleType {
	func convertToBoolean() -> NSNumber? {
		if self.intValue == 0 {
			return NSNumber(value: false)
		} else if self.intValue >= 1 {
			return NSNumber(value: true)
		}
		return nil
	}
	func convertToDate() -> NSDate? {
		return NSDate(timeIntervalSince1970: self.doubleValue)
	}
	func convertToData() -> NSData? {
		return self.stringValue.data(using: String.Encoding.utf8) as NSData?
	}
	func convertToDecimal() -> NSDecimalNumber? {
		return NSDecimalNumber(value: self.doubleValue)
	}
	func convertToDouble() -> NSNumber? {
		return NSNumber(value: self.doubleValue)
	}
	func convertToFloat() -> NSNumber? {
		return NSNumber(value: self.floatValue)
	}
	func convertToInt() -> NSNumber? {
		return NSNumber(value: self.intValue)
	}
	func convertToString() -> NSString? {
		return self.stringValue as NSString
	}
}
// MARK:  - NSString -
extension NSString : ConvertibleType {
	func convertToBoolean() -> NSNumber? {
		let lowercaseValue = self.lowercased
		if lowercaseValue == "yes" || lowercaseValue == "true" || lowercaseValue == "1" {
			return NSNumber(value: true)
		} else if lowercaseValue == "no" || lowercaseValue == "false" || lowercaseValue == "0" {
			return NSNumber(value: false)
		}
		return nil
	}
	func convertToDate() -> NSDate? {
		return CoreDataValueConverter.dateFormatter.date(from: self as String) as NSDate?
	}
	func convertToData() -> NSData? {
		return self.data(using: String.Encoding.utf8.rawValue) as NSData?
	}
	func convertToDecimal() -> NSDecimalNumber? {
		return NSDecimalNumber(value: self.doubleValue)
	}
	func convertToDouble() -> NSNumber? {
		return NSNumber(value: self.doubleValue)
	}
	func convertToFloat() -> NSNumber? {
		return NSNumber(value: self.floatValue)
	}
	func convertToInt() -> NSNumber? {
		return NSNumber(value: self.integerValue)
	}
	func convertToString() -> NSString? {
		return self
	}
}
