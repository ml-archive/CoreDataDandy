//
//  Constants.swift
//  CoreDataDandy
//
//  Created by Noah Blake on 6/20/15.
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

// MARK: - Error constants -
let DandyErrorDomain = "CoreDataDandyDomain"

// MARK: -  xcdatamodel decorations - 
// Inserted into the userInfo of an entity to mark its primaryKey
let PRIMARY_KEY = "@primaryKey"
// A special primaryKey for identifying a unique entity in the database. Multiple instances of this entity will not be produced.
let SINGLETON = "@singleton"
// Marks the mapping value in a userInfo used to read json into a property. For instance, if the json value of interest is expected
// to be keyed as "id" for a property named "dandyID," specify "@mapping":"id" in dandyID's userInfo.
let MAPPING = "@mapping"
// An @mapping keyword used to turn off Dandy mapping for a given property.
let NO_MAPPING = "@NO"

let CACHED_MAPPING_LOCATION = "EntityMapper_EntityMapper"