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
		return NSDecimalNumber(double: self.timeIntervalSince1970)
	}
	func convertToDouble() -> NSNumber? {
		return NSNumber(double: self.timeIntervalSince1970)
	}
	func convertToFloat() -> NSNumber? {
		return NSNumber(float: Float(self.timeIntervalSince1970))
	}
	func convertToInt() -> NSNumber? {
		return NSNumber(integer: Int(round(self.timeIntervalSince1970)))
	}
	func convertToString() -> NSString? {
		return CoreDataValueConverter.dateFormatter.stringFromDate(self)
	}
}
// MARK: - NSData -
extension NSData : DataConvertible, StringConvertible {
	func convertToData() -> NSData? {
		return self
	}
	func convertToString() -> NSString? {
		return NSString(data: self, encoding: NSUTF8StringEncoding)
	}
}
// MARK: - NSNumber -
extension NSNumber : ConvertibleType {
	func convertToBoolean() -> NSNumber? {
		if self.integerValue == 0 {
			return NSNumber(bool: false)
		} else if self.integerValue >= 1 {
			return NSNumber(bool: true)
		}
		return nil
	}
	func convertToDate() -> NSDate? {
		return NSDate(timeIntervalSince1970: self.doubleValue)
	}
	func convertToData() -> NSData? {
		return self.stringValue.dataUsingEncoding(NSUTF8StringEncoding)
	}
	func convertToDecimal() -> NSDecimalNumber? {
		return NSDecimalNumber(double: self.doubleValue)
	}
	func convertToDouble() -> NSNumber? {
		return NSNumber(double: self.doubleValue)
	}
	func convertToFloat() -> NSNumber? {
		return NSNumber(float: self.floatValue)
	}
	func convertToInt() -> NSNumber? {
		return NSNumber(integer: self.integerValue)
	}
	func convertToString() -> NSString? {
		return self.stringValue
	}
}
// MARK:  - NSString -
extension NSString : ConvertibleType {
	func convertToBoolean() -> NSNumber? {
		let lowercaseValue = self.lowercaseString
		if lowercaseValue == "yes" || lowercaseValue == "true" || lowercaseValue == "1" {
			return NSNumber(bool: true)
		} else if lowercaseValue == "no" || lowercaseValue == "false" || lowercaseValue == "0" {
			return NSNumber(bool: false)
		}
		return nil
	}
	func convertToDate() -> NSDate? {
		return CoreDataValueConverter.dateFormatter.dateFromString(self as String)
	}
	func convertToData() -> NSData? {
		return self.dataUsingEncoding(NSUTF8StringEncoding)
	}
	func convertToDecimal() -> NSDecimalNumber? {
		return NSDecimalNumber(double: self.doubleValue)
	}
	func convertToDouble() -> NSNumber? {
		return NSNumber(double: self.doubleValue)
	}
	func convertToFloat() -> NSNumber? {
		return NSNumber(float: self.floatValue)
	}
	func convertToInt() -> NSNumber? {
		return NSNumber(integer: self.integerValue)
	}
	func convertToString() -> NSString? {
		return self
	}
}
