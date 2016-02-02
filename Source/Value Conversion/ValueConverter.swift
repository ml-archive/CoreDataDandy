//
//  TypeConverters.swift
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

/// Adopters of this protocol provide implementations of `convertValue(_:)` so that all type conversions may proceed
/// via a consistent interface.
protocol ValueConverter {
	/// Attempts to convert a value from one type to another. Note that the value must be castable to a specified type
	/// for the conversion to succeed.
	func convertValue(value: AnyObject) -> AnyObject?
	/// A convenience function for checking type conformance before attempting type conversion.
	func convertValue<T>(value: AnyObject, toType: T.Type, converter: (T) -> AnyObject?) -> AnyObject?
}
extension ValueConverter {
	func convertValue<T>(value: AnyObject, toType: T.Type, converter: (T) -> AnyObject?) -> AnyObject? {
		if let value = value as? T {
			return converter(value)
		}
		return nil
	}
}

struct BooleanConverter: ValueConverter {
	func convertValue(value: AnyObject) -> AnyObject? {
		return convertValue(value, toType: BooleanConvertible.self) { $0.convertToBoolean() }
	}
}
struct DateConverter: ValueConverter {
	func convertValue(value: AnyObject) -> AnyObject? {
		return convertValue(value, toType: DateConvertible.self) { $0.convertToDate() }
	}
}
struct DataConverter: ValueConverter {
	func convertValue(value: AnyObject) -> AnyObject? {
		return convertValue(value, toType: DataConvertible.self) { $0.convertToData() }
	}
}
struct DoubleConverter: ValueConverter {
	func convertValue(value: AnyObject) -> AnyObject? {
		return convertValue(value, toType: DoubleConvertible.self) { $0.convertToDouble() }
	}
}
struct DecimalConverter: ValueConverter {
	func convertValue(value: AnyObject) -> AnyObject? {
		return convertValue(value, toType: DecimalConvertible.self) { $0.convertToDecimal() }
	}
}
struct FloatConverter: ValueConverter {
	func convertValue(value: AnyObject) -> AnyObject? {
		return convertValue(value, toType: FloatConvertible.self) { $0.convertToFloat() }
	}
}
struct IntConverter: ValueConverter {
	func convertValue(value: AnyObject) -> AnyObject? {
		return convertValue(value, toType: IntConvertible.self) { $0.convertToInt() }
	}
}
struct StringConverter: ValueConverter {
	func convertValue(value: AnyObject) -> AnyObject? {
		return convertValue(value, toType: StringConvertible.self) { $0.convertToString() }
	}
}