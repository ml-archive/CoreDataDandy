//
//  Dictionary+Dandy.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 1/22/16.
//  Copyright © 2016 Fuzz Productions, LLC. All rights reserved.
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


public extension Dictionary {
	/// Convenience function for adding values from one dictionary to another, like
	/// `NSMutableDictionary`'s `-addEntriesFromDictionary`
	public mutating func addEntriesFrom(_ dictionary: Dictionary) {
		for (key, value) in dictionary {
			self[key] = value
		}
	}
}

/// Functions similarly to `NSDictionary's` valueForKeyPath.
///
/// - parameter keypath: The keypath of the value.
/// - parameter dictionary: The dictionary in which the value may exist.
///
/// - returns: The value at the given keypath is one exists. 
///	If no key exists at the specified keypath, nil is returned.
func _value<T>(at keypath: String,
               of dictionary: JSONObject) -> T? {
	let keys = keypath.components(separatedBy: ".")
	var copy = dictionary
	var possibleValue: Any?
	for key in keys {
		possibleValue = copy[key] ?? nil
		if let value = copy[key] as? JSONObject {
			copy = value
		}
	}

	return possibleValue as? T
}
