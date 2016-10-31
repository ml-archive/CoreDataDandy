//
//  CoreDataDandyTests.swift
//  CoreDataDandyTests
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

import XCTest
import CoreData

class CoreDataDandyTests: XCTestCase {

	override func setUp() {
		CoreDataDandy.wake("DandyModel")
		CoreDataValueConverter.dateFormatter.dateStyle = .long
		CoreDataValueConverter.dateFormatter.timeStyle = .short
		super.setUp()
	}
	override func tearDown() {
		Dandy.tearDown()
		super.tearDown()
	}
	// MARK: - Initialization and deinitialization -
	
	/// When the clean up completes, no data should remain.
	func testCleanUp() {
		Dandy.insert(Dandy_.self)
		Dandy.save()
		let initialResultsCount = try! Dandy.fetch(Dandy_.self)?.count
		Dandy.tearDown()
		let finalResultsCount = try! Dandy.fetch(Dandy_.self)?.count
		XCTAssert(initialResultsCount == 1 && finalResultsCount == 0, "Pass")
	}

	// MARK: - Saves -
	
	/// After a save, the size of the persistent store should increase
	func testSave() {
		let expectation = self.expectation(description: "save")
		do {
			let fileSizeKey = FileAttributeKey("NSFileSize")
			let unsavedData = try FileManager.default.attributesOfItem(atPath: PersistentStackCoordinator.persistentStoreURL.path)[fileSizeKey] as! Int
			for i in 0...100000 {
				let dandy = Dandy.insert(Dandy_.self)
				dandy?.setValue("\(i)", forKey: "dandyID")
			}
			Dandy.save({ (error) in
				do {
					let savedData = try FileManager.default.attributesOfItem(atPath: PersistentStackCoordinator.persistentStoreURL.path)[fileSizeKey] as! Int
					XCTAssert(savedData > unsavedData, "Pass")
					expectation.fulfill()
				} catch {
					XCTAssert(false, "Failure to retrieive file attributes.")
					expectation.fulfill()
				}
			})
		} catch {
			XCTAssert(false, "Failure to retrieive file attributes.")
			expectation.fulfill()
		}
		self.waitForExpectations(timeout: 20, handler: { (error) -> Void in })
	}

	// MARK: - Object insertions, deletions, and fetches -
	
	/// Objects should be insertable.
	func testObjectInsertion() {
		let dandy = Dandy.insert(Dandy_.self)
		XCTAssert(dandy != nil, "Pass")
		XCTAssert(try! Dandy.fetch(Dandy_.self)?.count == 1, "Pass")
	}
	
	/// Objects should be insertable in multiples.
	func testMultipleObjectInsertion() {
		for _ in 0...2 {
			Dandy.insert(Dandy_.self)
		}
		XCTAssert(try! Dandy.fetch(Dandy_.self)?.count == 3, "Pass")
	}
	
	/// Objects marked with the `@unique` primaryKey should not be inserted more than once.
	func testUniqueObjectInsertion() {
		Dandy.insert(Space.self)
		Dandy.insert(Space.self)
		XCTAssert(try! Dandy.fetch(Space.self)?.count == 1, "Pass")
	}
	
	/// Passing an invalid entity name should result in warning emission and a nil return
	func testInvalidObjectInsertion() {
		class ZZZ: NSManagedObject {}
		
		let object = Dandy.insert(ZZZ.self)
		XCTAssert(object == nil, "Pass")
	}
	
	/// After a value has been inserted with a primary key, the next fetch for it should return it and it alone.
	func testUniqueObjectMaintenance() {
		let dandy = Dandy.insertUnique(Dandy_.self, identifiedBy: "WILDE")
		dandy?.setValue("An author, let's say", forKey: "bio")
		let repeatedDandy = Dandy.insertUnique(Dandy_.self, identifiedBy: "WILDE")
		let dandies = try! Dandy.fetch(Dandy_.self)?.count
		XCTAssert(dandies == 1 && (repeatedDandy!.value(forKey: "bio") as! String == "An author, let's say"), "Pass")
	}
	
	/// Objects should be fetchable via typical NSPredicate configured NSFetchRequests.
	func testPredicateFetch() {
		let wilde = Dandy.insertUnique(Dandy_.self, identifiedBy: "WILDE")!
		wilde.setValue("An author, let's say", forKey: "bio")
		let byron = Dandy.insertUnique(Dandy_.self, identifiedBy: "BYRON")!
		byron.setValue("A poet, let's say", forKey: "bio")
		let dandies = try! Dandy.fetch(Dandy_.self)?.count
		let byrons = try! Dandy.fetch(Dandy_.self, filterBy: NSPredicate(format: "bio == %@", "A poet, let's say"))?.count
		XCTAssert(dandies == 2 && byrons == 1, "Pass")
	}
	
	/// After a fetch for an object with a primaryKey of the wrong type should undergo type conversion and
	/// resolve correctly..
	func testPrimaryKeyTypeConversion() {
		let dandy = Dandy.insertUnique(Dandy_.self, identifiedBy: 1)
		dandy?.setValue("A poet, let's say", forKey: "bio")
		let repeatedDandy = Dandy.insertUnique(Dandy_.self, identifiedBy: "1")
		let dandies = try! Dandy.fetch(Dandy_.self)?.count
		XCTAssert(dandies == 1 && (repeatedDandy!.value(forKey: "bio") as! String == "A poet, let's say"), "Pass")
	}
	
	/// Mistaken use of a primaryKey identifying function for singleton objects should not lead to unexpected
	/// behavior.
	func testSingletonsIgnorePrimaryKey() {
		let space = Dandy.insertUnique(Space.self, identifiedBy: "name")
		space?.setValue("The Gogol Empire, let's say", forKey: "name")
		let repeatedSpace = Dandy.insertUnique(Space.self, identifiedBy: "void")
		let spaces = try! Dandy.fetch(Space.self)?.count
		XCTAssert(spaces == 1 && (repeatedSpace!.value(forKey: "name") as! String == "The Gogol Empire, let's say"), "Pass")
	}
	
	/// The convenience function for fetching objects by primary key should return a unique object that has been inserted.
	func testUniqueObjectFetch() {
		let dandy = Dandy.insertUnique(Dandy_.self, identifiedBy: "WILDE")
		dandy?.setValue("An author, let's say", forKey: "bio")
		let fetchedDandy = Dandy.fetchUnique(Dandy_.self, identifiedBy: "WILDE")!
		XCTAssert((fetchedDandy.value(forKey: "bio") as! String == "An author, let's say"), "Pass")
	}
	
	/// If a primary key is not specified for an object, the fetch should fail and emit a warning.
	func testUnspecifiedPrimaryKeyValueUniqueObjectFetch() {
		let plebian = Dandy.insertUnique(Plebian.self, identifiedBy: "plebianID")
		XCTAssert(plebian == nil, "Pass")
	}
	
	/// A deleted object should not be represented in the database
	func testObjectDeletion() {
		let space = Dandy.insertUnique(Space.self, identifiedBy: "name")
		let previousSpaceCount = try! Dandy.fetch(Space.self)?.count
		let expectation = self.expectation(description: "Object deletion")
		Dandy.delete(space!) {
			let newSpaceCount = try! Dandy.fetch(Space.self)?.count
			XCTAssert(previousSpaceCount == 1 && newSpaceCount == 0, "Pass")
			expectation.fulfill()
		}
		self.waitForExpectations(timeout: 0.5, handler: { (error) -> Void in })
	}

	// MARK: - Persistent Stack -
	
	/// The managed object model associated with the stack coordinator should be consistent with DandyModel.xcdatamodel.
	func testPersistentStackManagerObjectModelConstruction() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		XCTAssert(persistentStackCoordinator.managedObjectModel.entities.count == 9, "Pass")
	}
	
	/// The parentContext of the mainContext should be the privateContext. Changes to the structure of
	/// Dandy's persistent stack will be revealed with this test.
	func testPersistentStackManagerObjectContextConstruction() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		XCTAssert(persistentStackCoordinator.mainContext.parent === persistentStackCoordinator.privateContext, "Pass")
	}
	
	/// The privateContext should share a reference to the `DandyStackCoordinator's` persistentStoreCoordinator.
	func testPersistentStoreCoordinatorConnection() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		persistentStackCoordinator.connectPrivateContextToPersistentStoreCoordinator()
		XCTAssert(persistentStackCoordinator.privateContext.persistentStoreCoordinator! === persistentStackCoordinator.persistentStoreCoordinator, "Pass")
	}
	/// Resetting `DandyStackCoordinator's` should remove pre-existing persistent stores and create a new one.
	func testPersistentStoreReset() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		let oldPersistentStore = persistentStackCoordinator.persistentStoreCoordinator.persistentStores.first!
		persistentStackCoordinator.resetPersistentStore()
		let newPersistentStore = persistentStackCoordinator.persistentStoreCoordinator.persistentStores.first!
		XCTAssert((newPersistentStore !== oldPersistentStore), "Pass")
	}
	
	/// When initialization completes, the completion closure should execute.
	func testPersistentStackManagerConnectionClosureExecution() {
		let expectation = self.expectation(description: "initialization")
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel", persistentStoreConnectionCompletion: {
			XCTAssert(true, "Pass.")
			expectation.fulfill()
		})
		persistentStackCoordinator.connectPrivateContextToPersistentStoreCoordinator()
		self.waitForExpectations(timeout: 5, handler: { (error) -> Void in })
	}

	// MARK: - Value conversions -
	
	/// Conversions to undefined types should not occur
	func testUndefinedTypeConversion() {
		let result: Any? = CoreDataValueConverter.convert("For us, life is five minutes of introspection", to: .undefinedAttributeType)
		XCTAssert(result == nil, "Pass")
	}
	
	/// Test non-conforming protocol type conversion
	func testNonConformingProtocolTypeConversion() {
		let result: Any? = CoreDataValueConverter.convert(["life", "is", "five", "minutes", "of", "introspection"], to: .stringAttributeType)
		XCTAssert(result == nil, "Pass")
	}
	
	/// A type converts to the same type should undergo no changes
	func testSameTypeConversion() {
		let string: Any? = CoreDataValueConverter.convert("For us, life is five minutes of introspection", to: .stringAttributeType)
		XCTAssert(string is String, "Pass")

		let integer: Any? = CoreDataValueConverter.convert(Int(1), to: .integer64AttributeType)
		XCTAssert(integer is Int, "Pass")
		
		let float: Any? = CoreDataValueConverter.convert(Float(1), to: .floatAttributeType)
		XCTAssert(float is Float, "Pass")
		
		let double: Any? = CoreDataValueConverter.convert(Double(1), to: .doubleAttributeType)
		XCTAssert(double is Double, "Pass")

		let date: Any? = CoreDataValueConverter.convert(Date(), to: .dateAttributeType)
		XCTAssert(date is Date, "Pass")

		let encodedString = "suave".data(using: String.Encoding.utf8, allowLossyConversion: true)
		let data: Any? = CoreDataValueConverter.convert(encodedString!, to: .binaryDataAttributeType)
		XCTAssert(data is Data, "Pass")
	}
	
	/// NSData objects should be convertible to Strings.
	func testDataToStringConversion() {
		let expectation: NSString = "testing string"
		let input: Data? = expectation.data(using: String.Encoding.utf8.rawValue)
		let result = CoreDataValueConverter.convert(input!, to: .stringAttributeType) as? NSString
		XCTAssert(result == expectation, "")
	}
	
	/// Numbers should be convertible to Strings.
	func testNumberToStringConversion() {
		let input = 123455
		let result = CoreDataValueConverter.convert(input, to: .stringAttributeType) as? String
		XCTAssert(result == "123455", "")
	}
	
	/// Numbers should be convertible to NSDecimalNumbers
	func testNumberToDecimalConversion() {
		let integer = Int(7)
		var result = CoreDataValueConverter.convert(integer, to: .decimalAttributeType) as? NSDecimalNumber
		XCTAssert(result == NSDecimalNumber(value: integer), "Pass")
		
		let float = Float(7.070000171661375488)
		result = CoreDataValueConverter.convert(float, to: .decimalAttributeType) as? NSDecimalNumber
		XCTAssert(result == NSDecimalNumber(value: float), "Pass")
		
		let double = Double(7.070000171661375488)
		result = CoreDataValueConverter.convert(double, to: .decimalAttributeType) as? NSDecimalNumber
		XCTAssert(result == NSDecimalNumber(value: double), "Pass")
	}
	
	/// Numbers should be convertible to Doubles
	func testNumberToDoubleConversion() {
		let integer = Int(7)
		var result = CoreDataValueConverter.convert(integer, to: .doubleAttributeType) as? Double
		XCTAssert(result == Double(integer), "Pass")
		
		let float = Float(7)
		result = CoreDataValueConverter.convert(float, to: .doubleAttributeType) as? Double
		XCTAssert(result == Double(float), "Pass")
	}
	
	/// Numbers should be convertible to Floats
	func testNumberToFloatConversion() {
		let integer = Int(7)
		var result = CoreDataValueConverter.convert(integer, to: .floatAttributeType) as? Float
		XCTAssert(result == Float(integer), "Pass")
		
		let double = Double(7.07)
		result = CoreDataValueConverter.convert(double, to: .floatAttributeType) as? Float
		XCTAssert(result == Float(double), "Pass")
	}
	
	/// Numbers should be convertible to NSData
	func testNumberToDataConversion() {
		let input = 7
		
		var integer = Int(input)
		var result = CoreDataValueConverter.convert(integer, to: .binaryDataAttributeType) as? Data
		XCTAssert(result == Data(bytes: &integer, count: MemoryLayout<Int>.size), "Pass")
		
		var float = Float(input)
		result = CoreDataValueConverter.convert(float, to: .binaryDataAttributeType) as? Data
		XCTAssert(result == Data(bytes: &float, count: MemoryLayout<Float>.size), "Pass")
		
		var double = Double(input)
		result = CoreDataValueConverter.convert(double, to: .binaryDataAttributeType) as? Data
		XCTAssert(result == Data(bytes: &double, count: MemoryLayout<Double>.size), "Pass")
		
	}
	
	/// Numbers should be convertible to NSDates.
	func testNumberToDateConversion() {
		let now = Date()
		let expectation = Double(now.timeIntervalSince1970)
		let result = CoreDataValueConverter.convert(expectation, to: .dateAttributeType) as? Date
		let resultAsDouble = Double(result!.timeIntervalSince1970)
		XCTAssert(resultAsDouble == expectation, "")
	}
	
	/// Numbers should be convertible to Booleans.
	func testNumberToBooleanConversion() {
		var input = -1
		var result = CoreDataValueConverter.convert(input, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == nil, "")

		input = 1
		result = CoreDataValueConverter.convert(input, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")

		input = 0
		result = CoreDataValueConverter.convert(input, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")

		input = 99
		result = CoreDataValueConverter.convert(input, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result == true, "Pass")
	}
	
	/// NSDates should be convertible to Strings.
	func testDateToStringConversion() {
		let now = Date()
		let expectation = CoreDataValueConverter.dateFormatter.string(from: now)
		let result = CoreDataValueConverter.convert(now, to: .stringAttributeType) as? String
		XCTAssert(result == expectation, "")
	}
	
	/// NSDates should be convertible to Decimals.
	func testDateToDecimalConversion() {
		let now = Date()
		let expectation = NSDecimalNumber(value: now.timeIntervalSince(Date(timeIntervalSince1970: 0)) as Double)
		let result = CoreDataValueConverter.convert(now, to: .decimalAttributeType) as! NSDecimalNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	
	/// NSDates should be convertible to Doubles.
	func testDateToDoubleConversion() {
		let now = Date()
		let expectation = NSNumber(value: now.timeIntervalSince(Date(timeIntervalSince1970: 0)) as Double)
		let result = CoreDataValueConverter.convert(now, to: .doubleAttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	
	/// NSDates should be convertible to Floats.
	func testDateToFloatConversion() {
		let now = Date()
		let expectation = NSNumber(value: Float(now.timeIntervalSince(Date(timeIntervalSince1970: 0))) as Float)
		let result = CoreDataValueConverter.convert(now, to: .floatAttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	
	/// NSDates should be convertible to Ints.
	func testDateToIntConversion() {
		let now = Date()
		let expectation = NSNumber(value: Int(now.timeIntervalSince(Date(timeIntervalSince1970: 0))) as Int)
		let result = CoreDataValueConverter.convert(now, to: .integer32AttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	
	/// A variety of strings should be convertible to Booleans.
	func testStringToBooleanConversion() {
		var testString = "Yes"
		var result: NSNumber?

		result = CoreDataValueConverter.convert(testString, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")

		testString = "trUe"
		result = CoreDataValueConverter.convert(testString, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")

		testString = "1"
		result = CoreDataValueConverter.convert(testString, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")

		testString = "NO"
		result = CoreDataValueConverter.convert(testString, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")

		testString = "false"
		result = CoreDataValueConverter.convert(testString, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")

		testString = "0"
		result = CoreDataValueConverter.convert(testString, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")


		testString = "undefined"
		result = CoreDataValueConverter.convert(testString, to: .booleanAttributeType) as? NSNumber
		XCTAssert(result == nil, "")
	}
	
	/// Strings should be convertible to Integers.
	func testStringToIntConversion() {
		var input = "123"
		var result = CoreDataValueConverter.convert(input, to: .integer64AttributeType) as? Int
		XCTAssert(result == 123, "")

		input = "not an int"
		result = CoreDataValueConverter.convert(input, to: .integer64AttributeType) as? Int
		XCTAssert(result == nil, "")
	}
	
	/// NSStrings should be convertible to NSDecimalNumbers
	func testStringToDecimalConversion() {
		let expectation = NSDecimalNumber(value: 7.070000171661375488 as Float)
		let result = CoreDataValueConverter.convert("7.070000171661375488", to: .decimalAttributeType) as? NSDecimalNumber
		XCTAssert(result == expectation, "Pass")
	}
	
	/// NSStrings should be convertible to Doubles
	func testStringToDoubleConversion() {
		let expectation = Double(7.07)
		let result = CoreDataValueConverter.convert("7.07", to: .doubleAttributeType) as? Double
		XCTAssert(result == expectation, "Pass")
	}
	
	/// NSStrings should be convertible to Floats
	func testStringToFloatConversion() {
		let expectation = Float(7.07)
		let result = CoreDataValueConverter.convert("7.07", to: .floatAttributeType) as? Float
		XCTAssert(result == expectation, "Pass")
	}
	
	/// Strings should be convertible to Data objects.
	func testStringToDataConversion() {
		let input = "Long long Time ago"
		let expectedResult = input.data(using: String.Encoding.utf8)!
		let result = CoreDataValueConverter.convert(input, to: .binaryDataAttributeType) as? Data
		XCTAssert((result! == expectedResult) == true, "")
	}
	
	/// Strings should be convertible to NSDates.
	func testStringToDateConversion() {
		let now = Date()
		let nowAsString = CoreDataValueConverter.dateFormatter.string(from: now)
		let result = CoreDataValueConverter.convert(nowAsString, to: .dateAttributeType) as? Date
		let resultAsString = CoreDataValueConverter.dateFormatter.string(from: result!)
		XCTAssert(resultAsString == nowAsString, "")
	}

	// MARK: - Mapping -
	
	/// NSEntityDescriptions should be retrievable by name.
	func testEntityDescriptionFromString() {
		let expected = NSEntityDescription.entity(forEntityName: "Dandy_", in: Dandy.coordinator.mainContext)
		let result = NSEntityDescription.forEntity("Dandy_")!
		XCTAssert(expected == result, "Pass")
	}
	
	/// NSEntityDescriptions should be retrievable their model's underlying type.
	func testEntityDescriptionFromType() {
		let expected = NSEntityDescription.entity(forEntityName: "Dandy_", in: Dandy.coordinator.mainContext)
		let result = NSEntityDescription.forType(Dandy_.self)!
		XCTAssert(expected == result, "Pass")
	}
	
	/// NSEntityDescriptions should correctly report whether they represent unique models or not.
	func testUniquenessIdentification() {
		let dandy = NSEntityDescription.forType(Dandy_.self)!
		let plebian = NSEntityDescription.forType(Plebian.self)!
		XCTAssert(dandy.isUnique == true && plebian.isUnique == false,
		          "Failed to correctly identify whether an NSEntityDescription describes a unique model.")
	}

	/// NSEntityDescriptions should correctly report the property that makes an object unique.
	func testPrimaryKeyIdentification() {
		let expected = "dandyID"
		let dandy = NSEntityDescription.forType(Dandy_.self)!
		let result = dandy.primaryKey!
		XCTAssert(expected == result, "Pass")
	}
	
	/// Primary keys should be inheritable. In this case, Flattery's primaryKey should be inherited from
	/// its parent, Gossip.
	func testPrimaryKeyInheritance() {
		let flattery = Dandy.insert(Flattery.self)!
		XCTAssert(flattery.entity.primaryKey == "secret", "Pass")
	}

	/// Children should override the primaryKey of their parents. In this case, Slander's uniqueConstraint should
	/// override its parent's, Gossip.
	func testPrimaryKeyOverride() {
		let slander = Dandy.insert(Slander.self)!
		XCTAssert(slander.entity.primaryKey == "statement", "Pass")
	}
	
	/// Children's userInfo should contain the userInfo of their parents. In this case, Slander's userInfo should
	/// contain a value from its parent, Gossip.
	func testUserInfoHierarchyCollection() {
		let slanderDescription = NSEntityDescription.forType(Slander.self)!
		let userInfo = slanderDescription.allUserInfo!
		XCTAssert((userInfo["testValue"] as! String) == "testKey", "Pass")
	}
	
	/// Children should override userInfo of their parents. In this case, Slander's mapping decoration should
	/// override its parent's, Gossip.
	func testUserInfoOverride() {
		let slanderDescription = NSEntityDescription.forType(Slander.self)!
		let userInfo = slanderDescription.allUserInfo!
		XCTAssert((userInfo[PRIMARY_KEY] as! String) == "statement", "Pass")
	}
	
	/// Entity descriptions with no specified mapping should read into mapping dictionaries with all "same name" mapping
	func testSameNameMap() {
		let entity = NSEntityDescription.forType(Material.self)!
		let expectedMap = [
			"name": PropertyDescription(description: entity.allAttributes!["name"]!),
			"origin": PropertyDescription(description: entity.allAttributes!["origin"]!),
			"hats": PropertyDescription(description: entity.allRelationships!["hats"]!)
		]
		let result = EntityMapper.map(entity)
		XCTAssert(result! == expectedMap, "Pass")
	}
	
	/// @mapping: @false should result in an exclusion from the map. Gossip's "secret" attribute has been specified
	/// as such.
	func testNOMappingKeywordResponse() {
		let entity = NSEntityDescription.forType(Gossip.self)!
		let expectedMap = [
			"details": PropertyDescription(description: entity.allAttributes!["details"]!),
			"topic": PropertyDescription(description: entity.allAttributes!["topic"]!),
			// "secret": "unmapped"
			"purveyor": PropertyDescription(description: entity.allRelationships!["purveyor"]!)
		]
		let result = EntityMapper.map(entity)!
		XCTAssert(result == expectedMap, "Pass")
	}
	
	/// If an alternate keypath is specified, that keypath should appear as a key in the map. Space's "spaceState" has been specified
	/// to map from "state."
	func testAlternateKeypathMappingResponse() {
		let entity = NSEntityDescription.forType(Space.self)!
		let expectedMap = [
			"name": PropertyDescription(description: entity.allAttributes!["name"]!),
			"state": PropertyDescription(description: entity.allAttributes!["spaceState"]!)
		]
		let result = EntityMapper.map(entity)!
		XCTAssert(result == expectedMap, "Pass")
	}

	// MARK: - Property description comparisons and caching -

	/// Comparisons of property descriptions should evaluate correctly.
	func testPropertyDescriptionComparison() {
		let entity = NSEntityDescription.forType(Space.self)!
		let name = PropertyDescription(description: entity.allAttributes!["name"]!)
		let secondName = PropertyDescription(description: entity.allAttributes!["name"]!)
		let state = PropertyDescription(description: entity.allAttributes!["spaceState"]!)
		XCTAssert(name == secondName, "Pass")
		XCTAssert(name != state, "Pass")
	}
	
	/// Simple initializations and initializations from NSCoding should yield valid objects.
	func testPropertyDescriptionInitialization() {
		let _ = PropertyDescription()

		let entity = NSEntityDescription.forType(Space.self)!
		let propertyDescription = PropertyDescription(description: entity.allAttributes!["name"]!)
		let pathArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentPath = pathArray.first!
		let archivePath = NSString(string: documentPath).appendingPathComponent("SPACE_NAME")
		NSKeyedArchiver.archiveRootObject(propertyDescription, toFile: archivePath)
		let unarchivedPropertyDescription = NSKeyedUnarchiver.unarchiveObject(withFile: archivePath) as! PropertyDescription
		XCTAssert(unarchivedPropertyDescription == propertyDescription, "Pass")
	}

	// MARK: - Map caching -
	
	/// The first access to an entity's map should result in that map's caching
	func testMapCaching() {
		if let entityDescription = NSEntityDescription.forType(Material.self) {
			EntityMapper.map(entityDescription)
			let entityCacheMap = EntityMapper.cachedEntityMap[String(describing: Material.self)]!
			XCTAssert(entityCacheMap.count > 0, "")
		}
	}
	
	/// When clean up is called, no cached maps should remain
	func testMapCacheCleanUp() {
		if let entityDescription = NSEntityDescription.forType(Material.self) {
			EntityMapper.map(entityDescription)
			let initialCacheCount = EntityMapper.cachedEntityMap.count
			EntityMapper.clearCache()
			let finalCacheCount = EntityMapper.cachedEntityMap.count
			XCTAssert(initialCacheCount == 1 && finalCacheCount == 0, "Pass")
		}
	}
	
	/// The creation of a new map should be performant
	func testPerformanceOfNewMapCreation() {
		self.measure {
			let entityDescription = NSEntityDescription.forType(Material.self)
			EntityMapper.map(entityDescription!)
		}
	}
	
	/// The fetching of a cached map should be performant, and more performant than the creation of a new map
	func testPerformanceOfCachedMapRetrieval() {
		let entityDescription = NSEntityDescription.forType(Material.self)!
		EntityMapper.map(entityDescription)
		self.measure {
			EntityMapper.map(entityDescription)
		}
	}
	// MARK: - Object building -
	
	/// Values should be mapped from json to an object's attributes.
	func testAttributeBuilding() {
		let space = Dandy.insert(Space.self)!
		let json: JSONObject = ["name": "nebulous", "state": "moderately cool"]
		ObjectFactory.build(space, from: json)
		XCTAssert(space.name == "nebulous"
			&& space.spaceState ==  "moderately cool",
			"Pass")
	}
	
	/// Values should be mapped from json an object's relationships.
	func testRelationshipBuilding() {
		let gossip = Dandy.insert(Gossip.self)!
		let json = [
			"details": "At Bo Peep, unusually cool towards Isabella Brown.",
			"topic": "John Keats",
			"purveyor": [
				"id": 1,
				"name": "Lord Byron",
			]
		] as JSONObject
		ObjectFactory.build(gossip, from: json)

		let byron = gossip.purveyor!
		XCTAssert(gossip.details == "At Bo Peep, unusually cool towards Isabella Brown."
			&& gossip.topic ==  "John Keats"
			&& byron.dandyID ==  "1"
			&& byron.name == "Lord Byron",
			"Pass")
	}
	
	/// Values should be recursively mapped from nested json objects.
	func testRecursiveObjectBuilding() {
		let gossip = Dandy.insert(Gossip.self)!
		let json = [
			"details": "At Bo Peep, unusually cool towards Isabella Brown.",
			"topic": "John Keats",
			"purveyor": [
				"id": "1",
				"name": "Lord Byron",
				"hats": [[
					"name": "bowler",
					"style": "billycock",
					"material": [
						"name": "felt",
						"origin": "Rome"
					]
				]]
			]
		] as JSONObject
		ObjectFactory.build(gossip, from: json)
		let byron = gossip.purveyor!
		let bowler = byron.hats!.anyObject() as! Hat
		let felt = bowler.primaryMaterial!
		XCTAssert(gossip.details == "At Bo Peep, unusually cool towards Isabella Brown."
			&& gossip.topic == "John Keats"
			&& byron.dandyID ==  "1"
			&& byron.name == "Lord Byron"
			&& bowler.name == "bowler"
			&& bowler.styleDescription == "billycock"
			&& felt.name == "felt"
			&& felt.origin == "Rome",
			"Pass")
	}
	
	/// @mapping values that contain a keypath should allow access to json values via a keypath
	func testKeyPathBuilding() {
		let dandy = Dandy.insert(Dandy_.self)!
		let json = [
			"id": "BAUD",
			"relatedDandies": [
				"predecessor": [
					"id": "BALZ",
					"name": "Honoré de Balzac"
				]
			]
		] as JSONObject
		ObjectFactory.build(dandy, from: json)
		let balzac = dandy.predecessor!
		XCTAssert(balzac.dandyID == "BALZ"
			&& balzac.name == "Honoré de Balzac"
			&& balzac.successor!.dandyID ==  dandy.dandyID,
			"Pass")
	}
	
	/// Property values on an object should not be overwritten if no new values are specified.
	func testIgnoreUnkeyedAttributesWhenBuilding() {
		let space = Dandy.insert(Space.self)!
		space.setValue("exceptionally relaxed", forKey: "spaceState")
		let json: JSONObject = ["name": "nebulous" as AnyObject]
		ObjectFactory.build(space, from: json)
		XCTAssert(space.value(forKey: "spaceState") as! String == "exceptionally relaxed", "Pass")
	}
	
	/// Property values on an object should be overwritten if new values are specified.
	func testOverwritesKeyedAttributesWhenBuilding() {
		let space = Dandy.insert(Space.self)!
		space.setValue("exceptionally relaxed", forKey: "spaceState")
		let json: JSONObject = ["state": "significant excitement"]
		ObjectFactory.build(space, from: json)
		XCTAssert(space.value(forKey: "spaceState") as! String == "significant excitement", "Pass")
	}
	
	/// If a single json object is passed when attempting to build a toMany relationship, it should be
	/// rejected.
	func testSingleObjectToManyRelationshipRejection() {
		let dandy = Dandy.insert(Dandy_.self)!
		let json = [
			"name": "bowler",
			"style": "billycock",
			"material": [
				"name": "felt",
				"origin": "Rome"
			]
		] as JSONObject
		ObjectFactory.make(PropertyDescription(description: dandy.entity.allRelationships!["hats"]!), to: dandy, from: json)
		XCTAssert((dandy.value(forKey: "hats") as! NSSet).count == 0, "Pass")
	}
	
	/// Uniqueness should play no role in whether an object can be made or not.
	func testNonUniqueObjectMaking() {
		let json: JSONObject = ["name": "Passerby" as AnyObject]
		let plebian = ObjectFactory.make(Plebian.self, from: json)
		XCTAssert(plebian != nil, "Test failed: a non-unique object could not be made.")
	}
	
	/// If a json array is passed when attempting to build a toOne relationship, it should be
	/// rejected.
	func testArrayOfObjectToOneRelationshipRejection() {
		let gossip = Dandy.insert(Gossip.self)!
		let json = [
			[
				"id": "1",
				"name": "Lord Byron"],
			[
				"id": "2",
				"name": "Oscar Wilde"],
			[
				"id": "3",
				"name": "Andre 3000"]
		]
		ObjectFactory.make(PropertyDescription(description: gossip.entity.allRelationships!["purveyor"]!), to: gossip, from: json)
		XCTAssert(gossip.value(forKey: "purveyor") == nil, "Pass")
	}
	
	/// NSOrderedSets should be created for ordered relationships. NSSets should be created for
	/// unordered relationships.
	func testOrderedRelationshipsBuilding() {
		let hat = Dandy.insert(Hat.self)!
		let json = [
			[
				"id": "1",
				"name": "Lord Byron"],
			[
				"id": "2",
				"name": "Oscar Wilde"],
			[
				"id": "3",
				"name": "Andre 3000"]
		]
		ObjectFactory.make(PropertyDescription(description: hat.entity.allRelationships!["dandies"]!), to: hat, from: json)
		XCTAssert(hat.value(forKey: "dandies") is NSOrderedSet && hat.dandies!.count == 3, "Pass")
	}
	
	/// Nil or inconvertible json values should lead to nilled out relationships.
	func testRelationshipNilling() {
		let dandy = Dandy.insert(Dandy_.self)!
		let json = [
			"id": 1,
			"name": "Lord Byron",
			"hats": [
				[
					"name": "bowler",
					"style": "billycock",
					"material": [
						"name": "felt",
						"origin": "Rome"
					]
				]
			]
		] as JSONObject
		
		let nullNilling = [
			"id": 1,
			"hats": "NULL"
		] as JSONObject
		
		ObjectFactory.build(dandy, from: json)
		XCTAssert(dandy.hats!.count == 1, "After building from \(json), Lord Byron should have a single hat.")
		ObjectFactory.build(dandy, from: nullNilling)
		XCTAssert(dandy.hats?.count == 0, "After building hats from NULL values, Lord Byron should have no hats.")
		
		let nsNullNilling = [
			"id": 1,
			"hats": NSNull()
		] as JSONObject
		
		ObjectFactory.build(dandy, from: json)
		XCTAssert(dandy.hats!.count == 1, "After building from \(json), Lord Byron should have a single hat.")
		ObjectFactory.build(dandy, from: nsNullNilling)
		XCTAssert(dandy.hats?.count == 0, "After building hats from NULL values, Lord Byron should have no hats.")
		
		XCTAssert((dandy.value(forKey: "hats") as! NSSet).count == 0, "Pass")
	}

	// MARK: -  Object factory via CoreDataDandy -
	
	/// json containing a valid primary key should result in unique, mapped objects.
	func testSimpleObjectConstructionFromJSON() {
		let json = ["name": "Passerby"]
		let plebian = Dandy.upsert(Plebian.self, from: json)!
		XCTAssert(plebian.value(forKey: "name") as! String == "Passerby")
	}
	
	/// json lacking a primary key should be rejected. A nil value should be returned and a warning
	/// emitted.
	func testUniqueObjectConstructionFromJSON() {
		let json = ["name": "Lord Byron"]
		let byron = Dandy.upsert(Dandy_.self, from: json)
		XCTAssert(byron == nil, "Pass")
	}

	/// json lacking a primary key should be rejected. A nil value should be returned and a warning
	/// emitted.
	func testRejectionOfJSONWithoutPrimaryKeyForUniqueObject() {
		let json = ["name": "Lord Byron"]
		let byron = Dandy.upsert(Dandy_.self, from: json)
		XCTAssert(byron == nil, "Pass")
	}

	/// An array of objects should be returned from a json array containing mappable objects.
	func testObjectArrayConstruction() {
		var json = [JSONObject]()
		for i in 0...9 {
			json.append(["id": String(i), "name": "Morty"])
		}
		let dandies = Dandy.batchUpsert(Dandy_.self, from: json)!
		let countIsCorrect = dandies.count == 10
		var dandiesAreCorrect = true
		for i in 0...9 {
			let matchingDandies = (dandies.filter {$0.value(forKey: "dandyID")! as! String == String(i)})
			if matchingDandies.count != 1 {
				dandiesAreCorrect = false
				break
			}
		}
		XCTAssert(countIsCorrect && dandiesAreCorrect, "Pass")
	}
	
	/// Objects that adopt `MappingFinalizer` should invoke `finalizeMappingForJSON(_:)` at the conclusion of its
	/// construction.
	///
	/// Gossip's map appends "_FINALIZE" to its content.
	func testMappingFinalization() {
		let input = "A decisively excellent affair, if a bit tawdry."
		let expected = "\(input)_FINALIZED"
		let json: JSONObject = [
			"id": "1" as AnyObject,
			"content": input as AnyObject
		]
		let conclusion = ObjectFactory.make(Conclusion.self, from: json)!
		XCTAssert(conclusion.content == expected, "Pass")
	}

	// MARK: - Serialization tests -
	
	/// An object's attributes should be serializable into json.
	func testAttributeSerialization() {
		let hat = Dandy.insert(Hat.self)!
		hat.setValue("bowler", forKey: "name")
		hat.setValue("billycock", forKey: "styleDescription")
		let expected = [
			"name": "bowler",
			"style": "billycock"
		]
		let result = Serializer.serialize(hat) as! [String: String]
		XCTAssert(result == expected, "Pass")
	}
	
	/// Test nil attribute exclusion from serialized json.
	func testNilAttributeSerializationExclusion() {
		let hat = Dandy.insert(Hat.self)!
		hat.setValue("bowler", forKey: "name")
		hat.setValue(nil, forKey: "styleDescription")
		let expected = ["name": "bowler"]
		let result = Serializer.serialize(hat) as! [String: String]
		XCTAssert(result == expected, "Pass")
	}
	
	/// Relationships targeted for serialization should not be mapped to a helper array unless thay are nested.
	func testNestedRelationshipSerializationExclusion() {
		let relationships = ["hats", "gossip", "predecessor"]
		let result = Serializer.nestedSerializationTargets(for: "hats", including: relationships)
		XCTAssert(result == nil, "\(result) should have been nil: no nested keypaths were included in \(relationships).")
	}
	
	/// Nested relationships targeted for serialization should be correctly mapped to a helper array.
	func testNestedRelationshipSerializationTargeting() {
		let relationships = ["purveyor.successor", "purveyor.hats.material", "anomaly"]
		let expected = ["successor", "hats.material"]
		let result = Serializer.nestedSerializationTargets(for: "purveyor", including: relationships)!
		XCTAssert(result == expected, "Pass")
	}
	
	/// Unspecified relationships should return no result.
	func testNoMatchingRelationshipsSerializationTargeting() {
		let relationships = ["purveyor.successor", "purveyor.hats.material"]
		let result = Serializer.nestedSerializationTargets(for: "anomaly", including: relationships)
		XCTAssert(result == nil, "Pass")
	}
	
	/// An object's attributes and to-one relationships should be serializaable into json.
	func testToOneRelationshipSerialization() {
		let hat = Dandy.insert(Hat.self)!
		hat.setValue("bowler", forKey: "name")
				hat.setValue("billycock", forKey: "styleDescription")
		let felt = Dandy.insert(Material.self)!
		felt.setValue("felt", forKey: "name")
		felt.setValue("Rome", forKey: "origin")
		hat.setValue(felt, forKey: "primaryMaterial")
		let expected = [
				"name": "bowler",
				"style": "billycock",
				"material": [
					"name": "felt",
					"origin": "Rome"
				]
		] as JSONObject
		let result = Serializer.serialize(hat, including:["primaryMaterial"])!
		XCTAssert(result == expected, "Pass")
	}
	
	/// An array of NSManagedObject should be serializable into json.
	func testObjectArraySerialization() {
		let byron = Dandy.insert(Dandy_.self)!
		byron.name = "Lord Byron"
		byron.dandyID = "1"
		let wilde = Dandy.insert(Dandy_.self)!
		wilde.name = "Oscar Wilde"
		wilde.dandyID = "2"
		let andre = Dandy.insert(Dandy_.self)!
		andre.name = "Andre 3000"
		andre.dandyID = "3"
		let expected: [JSONObject] = [[
				"id": "1",
				"name": "Lord Byron"
			], [
				"id": "2",
				"name": "Oscar Wilde"], [
				"id": "3",
				"name": "Andre 3000"
			]
		]
		let result = Serializer.serialize([byron, wilde, andre])!
		XCTAssert(result == expected, "Pass")
	}
	
	/// An object's attributes and to-many relationships should be serializaable into json.
	func testToManyRelationshipSerialization() {
		let byron = Dandy.insert(Dandy_.self)!
		byron.name = "Lord Byron"
		byron.dandyID = "1"
		let bowler = Dandy.insert(Hat.self)!
		bowler.name = "bowler"
		bowler.styleDescription = "billycock"
		let tyrolean = Dandy.insert(Hat.self)!
		tyrolean.name = "tyrolean"
		tyrolean.styleDescription = "alpine"
		byron.hats = Set([bowler, tyrolean]) as NSSet
		let expected = [
			"id": "1",
			"name": "Lord Byron",
			"hats": [
				[
					"name": "bowler",
					"style": "billycock"
				], [
					"name": "tyrolean",
					"style": "alpine"
				]
			]
		] as JSONObject
		var result = Serializer.serialize(byron, including:["hats"])!
		result["hats"] = (result["hats"] as! NSArray).sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)])
		XCTAssert(result == expected, "Pass")
	}
	
	/// An object's attributes and relationship tree should be serializaable into json.
	func testNestedRelationshipSerialization() {
		let gossip = Dandy.insert(Gossip.self)!
		gossip.details = "At Bo Peep, unusually cool towards Isabella Brown."
		gossip.topic = "John Keats"
		let byron = Dandy.insert(Dandy_.self)!
		byron.name = "Lord Byron"
		byron.dandyID = "1"
		let bowler = Dandy.insert(Hat.self)!
		bowler.name = "bowler"
		bowler.styleDescription = "billycock"
		byron.hats = Set([bowler]) as NSSet
		gossip.purveyor = byron
		let expected = [
			"details": "At Bo Peep, unusually cool towards Isabella Brown.",
			"topic": "John Keats",
			"purveyor": [
				"id": "1",
				"name": "Lord Byron",
				"hats": [
					[
						"name": "bowler",
						"style": "billycock",
					]
				]
			]
		] as JSONObject
		let result = Serializer.serialize(gossip, including: ["purveyor.hats"]) as! [String: NSObject]
		XCTAssert(result == expected, "Pass")
	}

	// MARK: - Extension tests -
	
	/// Entries from one dictionary should add correctly to another dictionary of the same type
	func testDictionaryEntryAddition() {
		var balzac = ["name": "Honoré de Balzac"]
		let profession = ["profession": "author"]
		balzac.addEntriesFrom(profession)
		XCTAssert(balzac["name"] == "Honoré de Balzac" && balzac["profession"] == "author", "Pass")
	}
	
	/// Values in a dictionary should be accessible via keypath
	func testValueForKeyPathExtraction() {
		let hats = [[
			"name": "bowler",
			"style": "billycock",
			"material": [
				"name": "felt",
				"origin": "Rome"
			]
		]]

		let gossip = [
			"details": "At Bo Peep, unusually cool towards Isabella Brown.",
			"topic": "John Keats",
			"purveyor": [
				"id": "1",
				"name": "Lord Byron",
				"hats": hats
			]
		] as JSONObject
		
		let value: [JSONObject]? = _value(at: "purveyor.hats", of: gossip)
		XCTAssert(value! == hats, "Pass")
	}
	
	/// Directories that exist should be reported as existing.
	func testDirectoryExistenceEvaluation() {
		let applications = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).last!
		var components = applications.pathComponents
		components.removeLast()
		let root = URL(string: NSString.path(withComponents: components))!
		XCTAssert(FileManager.directoryExists(at: root) == true, "Incorrectly evaluated existence of Application directory")
	}
	
	/// Directories that do not exists should be reported as non-existent.
	func testDirectoryInexistenceEvaluation() {
		let url = URL(string: "file://lord-byron/diary/screeds/creditors")!
		XCTAssert(FileManager.directoryExists(at: url) == false, "Incorrectly evaluated existence of nonsense directory")
	}
	
	/// One should be able to create directories.
	func testDirectoryCreation() {
		let applications = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).last!
		var components = applications.pathComponents
		components.removeLast()
		let root = URL(string: "file://" + NSString.path(withComponents: components))!
		
		let directory = root.appendingPathComponent("lord-byron", isDirectory: true)
		
		if FileManager.directoryExists(at: directory) {
			// Clean up previous executions of the test if trace of them remains.
			try! FileManager.default.removeItem(at: directory)
		}

		try! FileManager.createDirectory(at: directory)
		XCTAssert(FileManager.directoryExists(at: directory) == true, "Failed to create directory")
	}
	
	// MARK: - Warning emission tests -
	
	/// Dandy should format log messages consistently.
	func testMessageFormatting() {
		let warning = "Failed to serialize object Dandy including relationships hats"
		let log = format(warning)
		XCTAssert(log == "(CoreDataDandy) warning: " + warning, "Pass")
	}
	
	/// Dandy should format NSErrors into log messages consistently.
	func testWarningErrorEmission() {
		let error = NSError(domain: "DANDY_FETCH_ERROR", code: 1, userInfo: nil)
		let warning = "Failed to serialize object Dandy including relationships hats"
		let log = format(warning, with: error)
		XCTAssert(log == "(CoreDataDandy) warning: " + warning + " Error:\n" + error.description, "Pass")
	}
}

//
/// For testing purposes only, json comparators.
func ==(lhs: JSONObject, rhs: JSONObject) -> Bool {
	// Dictionaries of unequal counts are not equal
	if lhs.count != rhs.count { return false }
	// Dictionaries that are equal must share all keys and paired values
	for (key, lhValue) in lhs {
		if let rhValue = rhs[key] {
			switch (lhValue, rhValue) {
			case let (l, r) where l is String && r is String:
				return (l as! String) == (r as! String)
			case let (l, r) where l is Bool && r is Bool:
				return (l as! Bool) == (r as! Bool)
			case let (l, r) where l is Double && r is Double:
				return (l as! Double) == (r as! Double)
			case let (l, r) where l is JSONObject && r is JSONObject:
				return (l as! JSONObject) == (r as! JSONObject)
			case let (l, r) where l is NSObject && r is NSObject:
				return (l as! NSObject) == (r as! NSObject)
			default:
				return false
			}
		} else {
			return false
		}
	}
	return true
}

fileprivate func !=(lhs: JSONObject, rhs: JSONObject) -> Bool {
	return !(lhs == rhs)
}


fileprivate func ==(lhs: [JSONObject], rhs: [JSONObject]) -> Bool {
	if lhs.count != rhs.count {
		return false
	}
	
	let paired = zip(lhs, rhs)
	for (l, r) in paired {
		if l != r {
			return false
		}
	}
	
	return true
}
