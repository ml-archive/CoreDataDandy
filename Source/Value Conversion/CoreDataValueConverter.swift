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

import CoreData

/// The central type conversion class.
///
/// `CoreDataValueConverter` compares a given value to a given entity's property type, then attempts to convert the value
/// to the property type. This class ensures that values written to the NSManagedObject are always of the appropriate
/// tyope.
///
/// The actual conversion is conducted by an appropriate `ValueConverter`.
public struct CoreDataValueConverter {
	/// A shared dateFormatter for regularly converting strings of a known pattern
	/// to dates and vice-versa.
	public static let dateFormatter = NSDateFormatter()

	/// Maps `NSAttributeTypes` to their corresponding type converters.
	private static let typeConverters: [NSAttributeType: ValueConverter] = [
		.Integer16AttributeType: IntConverter(),
		.Integer32AttributeType: IntConverter(),
		.Integer64AttributeType: IntConverter(),
		.DecimalAttributeType: DecimalConverter(),
		.DoubleAttributeType: DoubleConverter(),
		.FloatAttributeType: FloatConverter(),
		.StringAttributeType: StringConverter(),
		.BooleanAttributeType: BooleanConverter(),
		.DateAttributeType: DateConverter(),
		.BinaryDataAttributeType: DataConverter()
	]
	/// Attempts to convert a given value to a type matching the specified entity property type. For instance,
	/// if "3" is passed but the specified entity's property is defined as an NSNumber, @3 will be returned.
	///
	/// For a list of supported `value` types, see `ConvertibleType`
	///
	/// - parameter value: The value to convert.
	/// - parameter forEntity: The entity this value is expected to map to.
	/// - parameter property: The property on the entity where this value will be written.
	///
	/// - returns: If the conversion was successful, the converted value. Otherwise, nil.
	public static func convert(value: AnyObject, forEntity entity: NSEntityDescription, property: String) -> AnyObject? {
		let attributeDescription = entity.propertiesByName[property] as? NSAttributeDescription
		if	let attributeDescription = attributeDescription {
			return convert(value, toType: attributeDescription.attributeType)
		}
		return nil
	}
	/// The class's central function. Attempts to convert values from one type to another.
	/// In general, this method is invoked indirectly via convertValue:forEntity:property
	///
	/// - parameter value: The value to convert.
	/// - parameter toType: The desired end type of the value.
	///
	/// - returns: If the conversion was successful, the converted value. Otherwise, nil.
	public static func convert(value: AnyObject, toType type: NSAttributeType) -> AnyObject? {
		if let converter = typeConverters[type] {
			return converter.convert(value)
		}
		return nil
	}
}
