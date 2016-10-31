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
	func convertToBoolean() -> Bool?
}

protocol DateConvertible {
	func convertToDate() -> Date?
}

protocol DataConvertible {
	func convertToData() -> Data?
}

protocol DoubleConvertible {
	func convertToDouble() -> Double?
}

protocol DecimalConvertible {
	func convertToDecimal() -> NSDecimalNumber?
}

protocol FloatConvertible {
	func convertToFloat() -> Float?
}

protocol IntConvertible {
	func convertToInt() -> Int?
}

protocol StringConvertible {
	func convertToString() -> String?
}

protocol NilConvertible {
	func convertToNil() -> Any?
}

protocol NumericConvertible: DoubleConvertible, DecimalConvertible, FloatConvertible, IntConvertible {}
protocol ConvertibleType: BooleanConvertible, DataConvertible, DateConvertible, NumericConvertible, StringConvertible {}

// MARK: - Date -
extension Date: DateConvertible, NumericConvertible, StringConvertible {
	func convertToDate() -> Date? {
		return self
	}
	
	func convertToDecimal() -> NSDecimalNumber? {
		return NSDecimalNumber(value: self.timeIntervalSince1970 as Double)
	}
	
	func convertToDouble() -> Double? {
		return timeIntervalSince1970
	}
	
	func convertToFloat() -> Float? {
		return Float(timeIntervalSince1970)
	}
	
	func convertToInt() -> Int? {
		return Int(round(self.timeIntervalSince1970))
	}
	
	func convertToString() -> String? {
		return CoreDataValueConverter.dateFormatter.string(from: self)
	}
}
// MARK: - Data -
extension Data : DataConvertible, StringConvertible {
	func convertToData() -> Data? {
		return self
	}
	
	func convertToString() -> String? {
		return String(data: self, encoding: String.Encoding.utf8)
	}
}
// MARK: - Numbers -
protocol NumericConvertibleType: SignedNumber, ConvertibleType { }
extension NumericConvertibleType {
	private func asDouble() -> Double? {
		switch self {
		case let i as Int: return Double(i)
		case let f as Float: return Double(f)
		case let d as Double: return d
		default: return nil
		}
	}
	
	func convertToBoolean() -> Bool? {
		if self == 0 {
			return false
		} else if self >= 1 {
			return true
		}
		return nil
	}
	
	func convertToDate() -> Date? {
		if let double = asDouble() {
			return Date(timeIntervalSince1970: TimeInterval(double))
		}
		return nil
	}
	
	func convertToData() -> Data? {
		var cpy = self
		return Data(bytes: &cpy, count: MemoryLayout<Self>.size)
	}
	
	func convertToDecimal() -> NSDecimalNumber? {
		if let double = asDouble() {
			return NSDecimalNumber(value: Double(double))
		}
		return nil
	}
	
	func convertToDouble() -> Double? {
		if let double = asDouble() {
			return double
		}
		return nil
	}
	
	func convertToFloat() -> Float? {
		if let double = asDouble() {
			return Float(double)
		}
		return nil
	}
	
	func convertToInt() -> Int? {
		if let double = asDouble() {
			return Int(double)
		}
		return nil
	}
	
	func convertToString() -> String? {
		return "\(self)"
	}
}
extension Int: NumericConvertibleType { }
extension Double: NumericConvertibleType { }
extension Float: NumericConvertibleType { }

extension NSNumber: ConvertibleType {
	func convertToBoolean() -> Bool? {
		return doubleValue.convertToBoolean()
	}
	
	func convertToDate() -> Date? {
		return doubleValue.convertToDate()
	}
	
	func convertToData() -> Data? {
		return doubleValue.convertToData()
	}
	
	func convertToDecimal() -> NSDecimalNumber? {
		return doubleValue.convertToDecimal()
	}
	
	func convertToDouble() -> Double? {
		return doubleValue.convertToDouble()
	}
	
	func convertToFloat() -> Float? {
		return doubleValue.convertToFloat()
	}
	
	func convertToInt() -> Int? {
		return doubleValue.convertToInt()
	}
	
	func convertToString() -> String? {
		return doubleValue.convertToString()
	}
}

// MARK:  - Strings -
extension String: ConvertibleType, NilConvertible {
	func convertToBoolean() -> Bool? {
		let lowercaseValue = lowercased()
		if lowercaseValue == "yes"
		|| lowercaseValue == "true"
		|| lowercaseValue == "1" {
			return true
		} else if lowercaseValue == "no"
		  || lowercaseValue == "false"
		  || lowercaseValue == "0" {
			return false
		}
		return nil
	}
	
	func convertToDate() -> Date? {
		return CoreDataValueConverter.dateFormatter.date(from: self as String)
	}
	
	func convertToData() -> Data? {
		return data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
	}
	
	func convertToDecimal() -> NSDecimalNumber? {
		if let num =  Double(self) {
			return NSDecimalNumber(value: num)
		}
		
		return nil
	}
	
	func convertToDouble() -> Double? {
		return Double(self)
	}
	
	func convertToFloat() -> Float? {
		return Float(self)
	}
	
	func convertToInt() -> Int? {
		return Int(self)
	}
	
	func convertToString() -> String? {
		if lowercased() == "null"
		|| lowercased() == "nil" {
			return nil
		}
	
		return self
	}
	
	func convertToNil() -> Any? {
		return convertToString()
	}
}

extension NSString: ConvertibleType, NilConvertible {
	func convertToBoolean() -> Bool? {
		return String(self).convertToBoolean()
	}
	
	func convertToDate() -> Date? {
		return String(self).convertToDate()
	}
	
	func convertToData() -> Data? {
		return String(self).convertToData()
	}
	
	func convertToDecimal() -> NSDecimalNumber? {
		return String(self).convertToDecimal()
	}
	
	func convertToDouble() -> Double? {
		return String(self).convertToDouble()
	}
	
	func convertToFloat() -> Float? {
		return String(self).convertToFloat()
	}
	
	func convertToInt() -> Int? {
		return String(self).convertToInt()
	}
	
	func convertToString() -> String? {
		return String(self).convertToString()
	}
	
	func convertToNil() -> Any? {
		return String(self).convertToNil()
	}
}

extension NSNull: NilConvertible {
	func convertToNil() -> Any? {
		return nil
	}
}
