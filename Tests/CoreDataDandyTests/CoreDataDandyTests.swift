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
		CoreDataDandy.wake(with: "DandyModel")
		CoreDataValueConverter.dateFormatter.dateStyle = .long
		CoreDataValueConverter.dateFormatter.timeStyle = .short
		super.setUp()
	}
	override func tearDown() {
		Dandy.tearDown()
		super.tearDown()
	}
	// MARK: - Initialization and deinitialization -
	/**
		When the clean up completes, no data should remain.
	*/
	func testCleanUp() {
		Dandy.insert("Dandy") // "Failed to initialize the application's saved data"
		Dandy.save()
		let initialResultsCount = try! Dandy.fetch("Dandy")?.count
		Dandy.tearDown()
		let finalResultsCount = try! Dandy.fetch("Dandy")?.count
		XCTAssert(initialResultsCount == 1 && finalResultsCount == 0, "Pass")
	}
	
	// MARK: - Saves -
	/**
		After a save, the size of the persistent store should increase
	*/
	func testSave() {
		let expectation = self.expectation(description: "save")
		do {
			let unsavedData = try FileManager.default.attributesOfItem(atPath: PersistentStackCoordinator.persistentStoreURL.path)[("NSFileSize" as AnyObject) as! FileAttributeKey] as! Int
			for i in 0...100000 {
				let dandy = Dandy.insert("Dandy")
				dandy?.setValue("\(i)", forKey: "dandyID")
			}
			Dandy.save(completion: { (error) in
				do {
					let savedData = try FileManager.default.attributesOfItem(atPath: PersistentStackCoordinator.persistentStoreURL.path)[("NSFileSize" as AnyObject) as! FileAttributeKey] as! Int
					XCTAssert(savedData > unsavedData, "Pass")
					expectation.fulfill()
				} catch {
					XCTAssert(false, "Failure to retrieive file attributes.")
					expectation.fulfill()
				}
			});
		} catch {
			XCTAssert(false, "Failure to retrieive file attributes.")
			expectation.fulfill()
		}
		self.waitForExpectations(timeout: 20, handler: { (error) -> Void in })
	}
	
	// MARK: - Object insertions, deletions, and fetches -
	/**
		Objects should be insertable.
	*/
	func testObjectInsertion() {
		let dandy = Dandy.insert("Dandy")
		XCTAssert(dandy != nil, "Pass")
		XCTAssert(try! Dandy.fetch("Dandy")?.count == 1, "Pass")
	}
	/**
		Objects should be insertable in multiples.
	*/
	func testMultipleObjectInsertion() {
		for _ in 0...2 {
			Dandy.insert("Dandy")
		}
		XCTAssert(try! Dandy.fetch("Dandy")?.count == 3, "Pass")
	}
	/**
		Objects marked with the `@unique` primaryKey should not be inserted more than once.
	*/
	func testUniqueObjectInsertion() {
		Dandy.insert("Space")
		Dandy.insert("Space")
		XCTAssert(try! Dandy.fetch("Space")?.count == 1, "Pass")
	}
	/**
		Passing an invalid entity name should result in warning emission and a nil return
	*/
	func testInvalidObjectInsertion() {
		let object = Dandy.insert("ZZZ")
		XCTAssert(object == nil, "Pass")
	}
	/**
		After a value has been inserted with a primary key, the next fetch for it should return it and 
		it alone.
	*/
	func testUniqueObjectMaintenance() {
		let dandy = Dandy.insertUnique("Dandy", primaryKeyValue: "WILDE" as AnyObject)
		dandy?.setValue("An author, let's say", forKey: "bio")
		let repeatedDandy = Dandy.insertUnique("Dandy", primaryKeyValue: "WILDE" as AnyObject)
		let dandies = try! Dandy.fetch("Dandy")?.count
		XCTAssert(dandies == 1 && (repeatedDandy!.value(forKey: "bio") as! String == "An author, let's say"), "Pass")
	}
	/**
		Objects should be fetchable via typical NSPredicate configured NSFetchRequests.
	*/
	func testPredicateFetch() {
		let wilde = Dandy.insertUnique("Dandy", primaryKeyValue: "WILDE" as AnyObject)
		wilde?.setValue("An author, let's say" as String, forKey: "bio")
		guard let byron = Dandy.insertUnique("Dandy", primaryKeyValue: "BYRON" as AnyObject) else { return }
		byron.setValue("A poet, let's say", forKey: "bio")
		let dandies = try! Dandy.fetch("Dandy")?.count
		let byrons = try! Dandy.fetch("Dandy", filterBy: NSPredicate(format: "bio == %@", "A poet, let's say"))?.count
		XCTAssert(dandies == 2 && byrons == 1, "Pass")
	}
	/**
		After a fetch for an object with a primaryKey of the wrong type should undergo type conversion and 
		resolve correctly..
	*/
	func testPrimaryKeyTypeConversion() {
		let dandy = Dandy.insertUnique("Dandy", primaryKeyValue: 1 as AnyObject)
		dandy?.setValue("A poet, let's say", forKey: "bio")
		let repeatedDandy = Dandy.insertUnique("Dandy", primaryKeyValue: "1" as AnyObject)
		let dandies = try! Dandy.fetch("Dandy")?.count
		XCTAssert(dandies == 1 && (repeatedDandy!.value(forKey: "bio") as! String == "A poet, let's say"), "Pass")
	}
	/**
		Mistaken use of a primaryKey identifying function for singleton objects should not lead to unexpected
		behavior.
	*/
	func testSingletonsIgnorePrimaryKey() {
		let space = Dandy.insertUnique("Space", primaryKeyValue: "name" as AnyObject)
		space?.setValue("The Gogol Empire, let's say", forKey: "name")
		let repeatedSpace = Dandy.insertUnique("Space", primaryKeyValue: "void" as AnyObject)
		let spaces = try! Dandy.fetch("Space")?.count
		XCTAssert(spaces == 1 && (repeatedSpace!.value(forKey: "name") as! String == "The Gogol Empire, let's say"), "Pass")
	}
	/**
		The convenience function for fetching objects by primary key should return a unique object that has been inserted.
	*/
	func testUniqueObjectFetch() {
		let dandy = Dandy.insertUnique("Dandy", primaryKeyValue: "WILDE" as AnyObject)
		dandy?.setValue("An author, let's say", forKey: "bio")
		let fetchedDandy = Dandy.fetchUnique("Dandy", primaryKeyValue: "WILDE" as AnyObject)!
		XCTAssert((fetchedDandy.value(forKey: "bio") as! String == "An author, let's say"), "Pass")
	}
	/**
		If a primary key is not specified for an object, the fetch should fail and emit a warning.
	*/
	func testUnspecifiedPrimaryKeyValueUniqueObjectFetch() {
		let plebian = Dandy.insertUnique("Plebian", primaryKeyValue: "plebianID" as AnyObject)
		XCTAssert(plebian == nil, "Pass")
	}
	/**
		A deleted object should not be represented in the database
	*/
	func testObjectDeletion() {
		let space = Dandy.insertUnique("Space", primaryKeyValue: "name" as AnyObject)
		let previousSpaceCount = try! Dandy.fetch("Space")?.count
		let expectation = self.expectation(description: "Object deletion")
		Dandy.delete(space!) {
			let newSpaceCount = try! Dandy.fetch("Space")?.count
			XCTAssert(previousSpaceCount == 1 && newSpaceCount == 0, "Pass")
			expectation.fulfill()
		}
		self.waitForExpectations(timeout: 0.5, handler: { ( error) -> Void in })
	}
	
	// MARK: - Persistent Stack -
	/**
		The managed object model associated with the stack coordinator should be consistent with DandyModel.xcdatamodel.
	*/
	func testPersistentStackManagerObjectModelConstruction() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		XCTAssert(persistentStackCoordinator.managedObjectModel.entities.count == 9, "Pass")
	}
	/**
		The parentContext of the mainContext should be the privateContext. Changes to the structure of
		Dandy's persistent stack will be revealed with this test.
	*/
	func testPersistentStackManagerObjectContextConstruction() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		XCTAssert(persistentStackCoordinator.mainContext.parent === persistentStackCoordinator.privateContext, "Pass")
	}
	/**
		The privateContext should share a reference to the `DandyStackCoordinator's` persistentStoreCoordinator.
	*/
	func testPersistentStoreCoordinatorConnection() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		persistentStackCoordinator.connectPrivateContextToPersistentStoreCoordinator()
		XCTAssert(persistentStackCoordinator.privateContext.persistentStoreCoordinator! === persistentStackCoordinator.persistentStoreCoordinator, "Pass")
	}
	/**
		Resetting `DandyStackCoordinator's` should remove pre-existing persistent stores and create a new one.
	*/
	func testPersistentStoreReset() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		let oldPersistentStore = persistentStackCoordinator.persistentStoreCoordinator.persistentStores.first!
		persistentStackCoordinator.resetPersistentStore()
		let newPersistentStore = persistentStackCoordinator.persistentStoreCoordinator.persistentStores.first!
		XCTAssert((newPersistentStore !== oldPersistentStore), "Pass")
	}
	/**
		When initialization completes, the completion closure should execute.
	*/
	func testPersistentStackManagerConnectionClosureExectution() {
		let expectation = self.expectation(description: "initialization")
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel", persistentStoreConnectionCompletion: {
			XCTAssert(true, "Pass.")
			expectation.fulfill()
		})
		persistentStackCoordinator.connectPrivateContextToPersistentStoreCoordinator()
		self.waitForExpectations(timeout: 5, handler: { ( error) -> Void in })
	}
	
	// MARK: - Value conversions -
	/**
		Conversions to undefined types should not occur
	*/
	func testUndefinedTypeConversion() {
		let result: AnyObject? = CoreDataValueConverter.convert(value: "For us, life is five minutes of introspection" as AnyObject, toType: .undefinedAttributeType)
		XCTAssert(result == nil, "Pass")
	}
	/**
		Test non-conforming protocol type conversion
	*/
	func testNonConformingProtocolTypeConversion() {
		let value = ["life", "is", "five", "minutes", "of", "introspection"] as AnyObject
		let result: AnyObject? = CoreDataValueConverter.convert(value: value , toType: .stringAttributeType)
		XCTAssert(result == nil, "Pass")
	}
	/**
		A type convertes to the same type should undergo no changes
	*/
	func testSameTypeConversion() {
		let string: AnyObject? = CoreDataValueConverter.convert(value: "For us, life is five minutes of introspection" as AnyObject, toType: .stringAttributeType)
		XCTAssert(string is String, "Pass")
		
		let number: AnyObject? = CoreDataValueConverter.convert(value: 1 as AnyObject, toType: .integer64AttributeType)
		XCTAssert(number is NSNumber, "Pass")
		
		let decimal: AnyObject? = CoreDataValueConverter.convert(value: NSDecimalNumber(value: 1), toType: .decimalAttributeType)
		XCTAssert(decimal is NSDecimalNumber, "Pass")
		
		let date: AnyObject? = CoreDataValueConverter.convert(value:NSDate(), toType: .dateAttributeType)
		XCTAssert(date is NSDate, "Pass")
		
		let encodedString = "suave".data(using: String.Encoding.utf8, allowLossyConversion: true)
		let data: AnyObject? = CoreDataValueConverter.convert(value: encodedString! as AnyObject, toType: .binaryDataAttributeType)
		XCTAssert(data is NSData, "Pass")
	}
	/**
		NSData objects should be convertible to Strings.
	*/
	func testDataToStringConversion() {
		let expectation: String = "testing string"
		let input: Data? = expectation.data(using: String.Encoding.utf8)
		let result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .stringAttributeType) as? String
		XCTAssert(result == expectation, "")
	}
	/**
		Numbers should be convertible to Strings.
	*/
	func testNumberToStringConversion() {
		let input = 123455 as AnyObject
		let result = CoreDataValueConverter.convert(value: input, toType: .stringAttributeType) as? String
		XCTAssert(result == "123455", "")
	}
	/**
		Numbers should be convertible to NSDecimalNumbers
	*/
	func testNumberToDecimalConversion() {
		let expectation = Double(7.070000171661375488)
		let result = CoreDataValueConverter.convert(value: NSNumber(value: expectation), toType: .decimalAttributeType) as? NSDecimalNumber
		XCTAssert(result == NSDecimalNumber(value: expectation), "Pass")
	}
	/**
		Numbers should be convertible to Doubles
	*/
	func testNumberToDoubleConversion() {
		let expectation = Double(7.07)
		let result = CoreDataValueConverter.convert(value: NSNumber(value: expectation), toType: .doubleAttributeType) as? Double
		XCTAssert(result == expectation, "Pass")
	}
	/**
		Numbers should be convertible to Floats
	*/
	func testNumberToFloatConversion() {
		let expectation = Float(7.07)
		let result = CoreDataValueConverter.convert(value: NSNumber(value: expectation), toType: .floatAttributeType) as? Float
		XCTAssert(result == expectation, "Pass")
	}
	/**
		Numbers should be convertible to NSData
	*/
	func testNumberToDataConversion() {
		let input = NSNumber(value: 7.07)
		let expectation = NSNumber(value: 7.07).stringValue.data(using: String.Encoding.utf8)
		let result = CoreDataValueConverter.convert(value: input, toType: .binaryDataAttributeType) as? Data
		XCTAssert(result == expectation, "Pass")
	}
	/**
		Numbers should be convertible to NSDates.
	*/
	func testNumberToDateConversion() {
		let now = Date()
		let expectation = Double(now.timeIntervalSince1970)
		let result = CoreDataValueConverter.convert(value: expectation as AnyObject, toType: .dateAttributeType) as? Date
		let resultAsDouble = Double(result!.timeIntervalSince1970)
		XCTAssert(resultAsDouble == expectation, "")
	}
	/**
		Numbers should be convertible to Booleans.
	*/
	func testNumberToBooleanConversion() {
		var input = -1
		var result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == nil, "")
		
		input = 1
		result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")
		
		input = 0
		result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")
		
		input = 99
		result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result == true, "Pass")
	}
	/**
		NSDates should be convertible to Strings.
	*/
		func testDateToStringConversion() {
		let now = Date()
		let expectation = CoreDataValueConverter.dateFormatter.string(from: now)
		let result = CoreDataValueConverter.convert(value: now as AnyObject, toType: .stringAttributeType) as? String
		XCTAssert(result == expectation, "")
	}
	/**
		NSDates should be convertible to Decimals.
	*/
	func testDateToDecimalConversion() {
		let now = Date()
		let timeIntervalSinceDouble = Double(now.timeIntervalSince(Date(timeIntervalSince1970: 0)))
		let expectation = NSDecimalNumber(value: timeIntervalSinceDouble)
		let result = CoreDataValueConverter.convert(value: now as AnyObject, toType: .decimalAttributeType) as! NSDecimalNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	/**
		NSDates should be convertible to Doubles.
	*/
	func testDateToDoubleConversion() {
		let now = Date()
		let expectation = NSNumber(value: now.timeIntervalSince(Date(timeIntervalSince1970: 0)))
		let result = CoreDataValueConverter.convert(value: now as AnyObject, toType: .doubleAttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	/**
		NSDates should be convertible to Floats.
	*/
	func testDateToFloatConversion() {
		let now = Date()
		let timeIntervalFloat = Float(now.timeIntervalSince(Date(timeIntervalSince1970: 0)))
		let expectation = NSNumber(value: timeIntervalFloat)
		let result = CoreDataValueConverter.convert(value: now as AnyObject, toType: .floatAttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	/**
		NSDates should be convertible to Ints.
	*/
	func testDateToIntConversion() {
		let now = Date()
		let timeIntervalInteger = Int(now.timeIntervalSince(Date(timeIntervalSince1970: 0)))
		let expectation = NSNumber(value: timeIntervalInteger)
		let result = CoreDataValueConverter.convert(value: now as AnyObject, toType: .integer32AttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	/**
		A variety of strings should be convertible to Booleans.
	*/
	func testStringToBooleanConversion() {
		var testString = "Yes"
		var result: NSNumber?
		
		result = CoreDataValueConverter.convert(value: testString as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")
		
		testString = "trUe"
		result = CoreDataValueConverter.convert(value: testString as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")
		
		testString = "1"
		result = CoreDataValueConverter.convert(value: testString as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")
		
		testString = "NO"
		result = CoreDataValueConverter.convert(value: testString as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")
		
		testString = "false"
		result = CoreDataValueConverter.convert(value: testString as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")
		
		testString = "0"
		result = CoreDataValueConverter.convert(value: testString as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")
		
		
		testString = "undefined"
		result = CoreDataValueConverter.convert(value: testString as AnyObject, toType: .booleanAttributeType) as? NSNumber
		XCTAssert(result == nil, "")
	}
	/**
		Strings should be convertible to Booleans.
	*/
	func testStringToIntConversion() {
		var input = "123"
		var result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .integer64AttributeType)
		XCTAssert(result?.integerValue == 123, "")
		
		input = "456wordsdontmatter123"
		result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .integer64AttributeType) as? NSNumber
		XCTAssert(result?.integerValue == 456, "")
		
		input = "nothingHereMatters"
		result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .integer64AttributeType) as? NSNumber
		XCTAssert(result?.integerValue == 0, "")
	}
	/**
		NSStrings should be convertible to NSDecimalNumbers
	*/
	func testStringToDecimalConversion() {
		let expectation = NSDecimalNumber(floatLiteral: 7.070000171661375488)
		let result = CoreDataValueConverter.convert(value:"7.070000171661375488" as AnyObject, toType: .decimalAttributeType) as? NSDecimalNumber
		XCTAssert(result == expectation, "Pass")
	}
	/**
		NSStrings should be convertible to Doubles
	*/
	func testStringToDoubleConversion() {
		let expectation = Double(7.07)
		let result = CoreDataValueConverter.convert(value: "7.07" as AnyObject, toType: .doubleAttributeType) as? Double
		XCTAssert(result == expectation, "Pass")
	}
	/**
		NSStrings should be convertible to Floats
	*/
	func testStringToFloatConversion() {
		let expectation = Float(7.07)
		let result = CoreDataValueConverter.convert(value:"7.07" as AnyObject, toType: .floatAttributeType) as? Float
		XCTAssert(result == expectation, "Pass")
	}
	/**
		Strings should be convertible to Data objects.
	*/
	func testStringToDataConversion() {
		let input = "Long long Time ago"
		let expectedResult = input.data(using: String.Encoding.utf8)
		let result = CoreDataValueConverter.convert(value: input as AnyObject, toType: .binaryDataAttributeType)
		if let result = result {
			XCTAssert(result.isEqual(expectedResult!) == true, "")
		}
	}
	/**
		Strings should be convertible to NSDates.
	*/
	func testStringToDateConversion() {
		let now = Date()
		let nowAsString = CoreDataValueConverter.dateFormatter.string(from: now)
		let result: Date = CoreDataValueConverter.convert(value: nowAsString as AnyObject, toType: .dateAttributeType) as! Date
		let resultAsString = CoreDataValueConverter.dateFormatter.string(from: result)
		XCTAssert(resultAsString == nowAsString, "")
	}
	
	// MARK: - Mapping -
	func testEntityDescriptionFromString() {
		let expected = NSEntityDescription.entity(forEntityName: "Dandy", in: Dandy.coordinator.mainContext)
		let result = NSEntityDescription.forEntity(name: "Dandy")!
		XCTAssert(expected == result, "Pass")
	}
	func testPrimaryKeyIdentification() {
		let expected = "dandyID"
		let dandy = NSEntityDescription.forEntity(name: "Dandy")!
		let result = dandy.primaryKey!
		XCTAssert(expected == result, "Pass")
	}
	/**
		The primary key should return the uniquenessConstraint of the entity if one is present.
	*/
	func testUniqueConstraintRetrieval() {
		let conclusion = Dandy.insert("Conclusion")!
		XCTAssert(conclusion.entity.primaryKey == "id", "Pass")
	}
	/**
		The primary key should return the uniquenessConstraint over of the primaryKey decoration if both are present.
	*/
	func testUniqueConstraintPriority() {
		let gossip = Dandy.insert("Gossip")!
		XCTAssert(gossip.entity.primaryKey == "details", "Pass")
	}
	/**
		Primary keys should be inheritable. In this case, Flattery's uniqueConstraint should be inherited from
		its parent, Gossip.
	*/
	func testPrimaryKeyInheritance() {
		let flattery = Dandy.insert("Flattery")!
		XCTAssert(flattery.entity.primaryKey == "details", "Pass")
	}
	/**
		Children should override the primaryKey of their parents. In this case, Slander's uniqueConstraint should
		override its parent's, Gossip.
	*/
	func testPrimaryKeyOverride() {
		let slander = Dandy.insert("Slander")!
		XCTAssert(slander.entity.primaryKey == "statement", "Pass")
	}
	/**
		Children's userInfo should contain the userInfo of their parents. In this case, Slander's userInfo should 
		contain a value from its parent, Gossip.
	*/
	func testUserInfoHierarchyCollection() {
		let slanderDescription = NSEntityDescription.forEntity(name: "Slander")!
		let userInfo = slanderDescription.allUserInfo!
		XCTAssert((userInfo["testValue"] as! String) == "testKey", "Pass")
	}
	/**
		Children should override userInfo of their parents. In this case, Slander's mapping decoration should
		override its parent's, Gossip.
	*/
	func testUserInfoOverride() {
		let slanderDescription = NSEntityDescription.forEntity(name: "Slander")!
		let userInfo = slanderDescription.allUserInfo!
		XCTAssert((userInfo[PRIMARY_KEY] as! String) == "statement", "Pass")
	}
	/**
		Entity descriptions with no specified mapping should read into mapping dictionaries with all "same name" mapping
	*/
	func testSameNameMap() {
		let entity = NSEntityDescription.forEntity(name: "Material")!
		let expectedMap = [
			"name": PropertyDescription(description: entity.allAttributes!["name"]!),
			"origin": PropertyDescription(description: entity.allAttributes!["origin"]!),
			"hats": PropertyDescription(description: entity.allRelationships!["hats"]!)
		]
		let result = EntityMapper.map(entity: entity)
		XCTAssert(result! == expectedMap, "Pass")
	}
	/**
		@mapping: @NO should result in an exclusion from the map. Gossip's "secret" attribute has been specified
		as such.
	*/
	func testNOMappingKeywordResponse() {
		let entity = NSEntityDescription.forEntity(name: "Gossip")!
		let expectedMap = [
			"details": PropertyDescription(description: entity.allAttributes!["details"]!),
			"topic": PropertyDescription(description: entity.allAttributes!["topic"]!),
			// "secret": "unmapped"
			"purveyor": PropertyDescription(description: entity.allRelationships!["purveyor"]!)
		]
		let result = EntityMapper.map(entity: entity)!
		XCTAssert(result == expectedMap, "Pass")
	}
	/**
		If an alternate keypath is specified, that keypath should appear as a key in the map. Space's "spaceState" has been specified
		to map from "state."
	*/
	func testAlternateKeypathMappingResponse() {
		let entity = NSEntityDescription.forEntity(name: "Space")!
		let expectedMap = [
			"name": PropertyDescription(description: entity.allAttributes!["name"]!),
			"state": PropertyDescription(description: entity.allAttributes!["spaceState"]!)
		]
		let result = EntityMapper.map(entity: entity)!
		XCTAssert(result == expectedMap, "Pass")
	}
	
	// MARK: - Property description comparisons and caching -
	/**
		Comparisons of property descriptions should evaluate correctly.
	*/
	func testPropertyDescriptionComparison() {
		let entity = NSEntityDescription.forEntity(name: "Space")!
		let name = PropertyDescription(description: entity.allAttributes!["name"]!).name
		let secondName = PropertyDescription(description: entity.allAttributes!["name"]!).name
		let state = PropertyDescription(description: entity.allAttributes!["spaceState"]!).name
		XCTAssert(name == secondName, "Pass")
		XCTAssert(name != state, "Pass")
		XCTAssert(name != "STRING", "Pass")
	}
	/**
		Simple initializations and initializations from NSCoding should yield valid objects.
	*/
	func testPropertyDescriptionInitialization() {
		let _ = PropertyDescription()
		
		let path = PersistentStackCoordinator.applicationDocumentsDirectory.relativePath
		let entity = NSEntityDescription.forEntity(name: "Space")!
		let propertyDescription = PropertyDescription(description: entity.allAttributes!["name"]!)
		let archivePath = path + "/SPACE_NAME"

		let data = NSKeyedArchiver.archivedData(withRootObject: propertyDescription)
		let didCreateFile = FileManager.default.createFile(atPath: archivePath, contents: data, attributes: [:])
		
		if let data = FileManager.default.contents(atPath: archivePath) {
			if let unarchivedPropertyDescription = NSKeyedUnarchiver.unarchiveObject(with: data) as? PropertyDescription {
				print(unarchivedPropertyDescription)
				XCTAssert(unarchivedPropertyDescription == propertyDescription, "Pass")
			}
		}
	}
	
	// MARK: - Map caching -
	/**
		The first access to an entity's map should result in that map's caching
	*/
	func testMapCaching() {
		let entityName = "Material"
		if let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: Dandy.coordinator.mainContext) {
			EntityMapper.map(entity: entityDescription)
			let entityCacheMap = EntityMapper.cachedEntityMap[entityName]!
			XCTAssert(entityCacheMap.count > 0, "")
		}
	}
	/**
		When clean up is called, no cached maps should remain
	*/
	func testMapCacheCleanUp() {
		let entityName = "Material"
		if let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: Dandy.coordinator.mainContext) {
			EntityMapper.map(entity: entityDescription)
			let initialCacheCount = EntityMapper.cachedEntityMap.count
			EntityMapper.clearCache()
			let finalCacheCount = EntityMapper.cachedEntityMap.count
			XCTAssert(initialCacheCount == 1 && finalCacheCount == 0, "Pass")
		}
	}
	/**
		The creation of a new map should be performant
	*/
	func testPerformanceOfNewMapCreation() {
		self.measure {
			let entityDescription = NSEntityDescription.entity(forEntityName: "Material", in: Dandy.coordinator.mainContext)
			EntityMapper.map(entity: entityDescription!)
		}
	}
	/**
		The fetching of a cached map should be performant, and more performant than the creation of a new map
	*/
	func testPerformanceOfCachedMapRetrieval() {
		let entityDescription = NSEntityDescription.entity(forEntityName: "Material", in: Dandy.coordinator.mainContext)!
		EntityMapper.map(entity: entityDescription)
		self.measure {
			EntityMapper.map(entity: entityDescription)
		}
	}
	
	// MARK: - Object building -
	/**
		Values should be mapped from json to an object's attributes.
	*/
	func testAttributeBuilding() {
		let space = Dandy.insert("Space")!
		let json = ["name": "nebulous", "state": "moderately cool"]
		ObjectFactory.build(object: space, from: json as [String : AnyObject])
		XCTAssert(space.value(forKey: "name") as! String == "nebulous" &&
			space.value(forKey: "spaceState") as! String ==  "moderately cool",
			"Pass")
	}
	/**
		Values should be mapped from json an object's relationships.
	*/
	func testRelationshipBuilding() {
		let gossip = Dandy.insert("Gossip")!
		let json = [
			"details": "At Bo Peep, unusually cool towards Isabella Brown.",
			"topic": "John Keats",
			"purveyor": [
				"id": 1,
				"name": "Lord Byron",
			]
			] as [String : Any]
		ObjectFactory.build(object: gossip, from: json as [String : AnyObject])
		let byron = gossip.value(forKey: "purveyor") as! NSManagedObject
		XCTAssert(gossip.value(forKey: "details") as! String == "At Bo Peep, unusually cool towards Isabella Brown." &&
			gossip.value(forKey: "topic") as! String ==  "John Keats" &&
			byron.value(forKey: "dandyID") as! String ==  "1" &&
			byron.value(forKey: "name") as! String ==  "Lord Byron",
			"Pass")
	}
	/**
		Values should be recursively mapped from nested json objects.
	*/
	func testRecursiveObjectBuilding() {
		let gossip = Dandy.insert("Gossip")!
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
			] as [String : Any]
		ObjectFactory.build(object: gossip, from: json as [String : AnyObject])
		let byron = gossip.value(forKey: "purveyor") as! NSManagedObject
		let bowler = (byron.value(forKey: "hats")! as AnyObject).anyObject() as! NSManagedObject
		let felt = bowler.value(forKey: "primaryMaterial") as! NSManagedObject
		XCTAssert(gossip.value(forKey: "details") as! String == "At Bo Peep, unusually cool towards Isabella Brown." &&
			gossip.value(forKey: "topic") as! String ==  "John Keats" &&
			byron.value(forKey: "dandyID") as! String ==  "1" &&
			byron.value(forKey: "name") as! String ==  "Lord Byron" &&
			bowler.value(forKey: "name") as! String ==  "bowler" &&
			bowler.value(forKey: "styleDescription") as! String ==  "billycock" &&
			felt.value(forKey: "name") as! String ==  "felt" &&
			felt.value(forKey: "origin") as! String ==  "Rome",
			"Pass")
	}
	/**
		@mapping values that contain a keypath should allow access to json values via a keypath
	*/
	func testKeyPathBuilding() {
		let dandy = Dandy.insert("Dandy")!
		let json = [
			"id": "BAUD",
			"relatedDandies": [
				"predecessor": [
					"id": "BALZ",
					"name": "Honoré de Balzac"
				]
			]
		] as [String: AnyObject]
		ObjectFactory.build(object: dandy, from: json)
		let balzac = dandy.value(forKey: "predecessor") as! NSManagedObject
		XCTAssert(balzac.value(forKey: "dandyID") as! String == "BALZ" &&
			balzac.value(forKey: "name") as! String ==  "Honoré de Balzac" &&
			(balzac.value(forKey: "successor") as! NSManagedObject).value(forKey: "dandyID") as! String == dandy.value(forKey: "dandyID") as! String,
			"Pass")
	}
	/**
		Property values on an object should not be overwritten if no new values are specified.
	*/
	func testIgnoreUnkeyedAttributesWhenBuilding() {
		let space = Dandy.insert("Space")!
		space.setValue("exceptionally relaxed", forKey: "spaceState")
		let json = ["name": "nebulous"] as [String : AnyObject]
		ObjectFactory.build(object: space, from: json)
		XCTAssert(space.value(forKey: "spaceState") as! String == "exceptionally relaxed", "Pass")
	}
	/**
		Property values on an object should be overwritten if new values are specified.
	*/
	func testOverwritesKeyedAttributesWhenBuilding() {
		let space = Dandy.insert("Space")!
		space.setValue("exceptionally relaxed", forKey: "spaceState")
		let json = ["state": "significant excitement"]
		ObjectFactory.build(object: space, from: json as [String : AnyObject])
		XCTAssert(space.value(forKey: "spaceState") as! String == "significant excitement", "Pass")
	}
	/**
		If a single json object is passed when attempting to build a toMany relationship, it should be
		rejected.
	*/
	func testSingleObjectToManyRelationshipRejection() {
		let dandy = Dandy.insert("Dandy")!
		let json = [
			"name": "bowler",
			"style": "billycock",
			"material": [
				"name": "felt",
				"origin": "Rome"
			]
			] as [String: AnyObject]
		ObjectFactory.make(relationship: PropertyDescription(description: dandy.entity.allRelationships!["hats"]! as AnyObject), to: dandy, from: json as AnyObject)
		XCTAssert((dandy.value(forKey: "hats") as! NSSet).count == 0, "Pass")
	}
	/**
		If a json array is passed when attempting to build a toOne relationship, it should be
		rejected.
	*/
	func testArrayOfObjectToOneRelationshipRejection() {
		let gossip = Dandy.insert("Gossip")!
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
		ObjectFactory.make(relationship: PropertyDescription(description: gossip.entity.allRelationships!["purveyor"]!), to: gossip, from: json as AnyObject)
		XCTAssert(gossip.value(forKey: "purveyor") == nil, "Pass")
	}
	/**
		NSOrderedSets should be created for ordered relationships. NSSets should be created for 
		unordered relationships.
	*/
	func testOrderedRelationshipsBuilding() {
		let hat = Dandy.insert("Hat")!
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
		let relationship = PropertyDescription(description: hat.entity.allRelationships!["dandies"]!)
		ObjectFactory.make(relationship: relationship, to: hat, from: json as AnyObject)
		XCTAssert(hat.value(forKey: "dandies") is NSOrderedSet && (hat.value(forKey: "dandies") as! NSOrderedSet).count == 3, "Pass")
	}
	
	// MARK: -  Object factory via CoreDataDandy -
	/**
		json containing a valid primary key should result in unique, mapped objects.
	*/
	func testSimpleObjectConstructionFromJSON() {
		let json = ["name": "Passerby"]
		let plebian = Dandy.upsert("Plebian", from: json as [String : AnyObject])!
		XCTAssert(plebian.value(forKey: "name") as! String == "Passerby")
	}
	/**
		json lacking a primary key should be rejected. A nil value should be returned and a warning
		emitted.
	*/
	func testUniqueObjectConstructionFromJSON() {
		let json = ["name": "Lord Byron"]
		let byron = Dandy.upsert("Dandy", from: json as [String : AnyObject])
		XCTAssert(byron == nil, "Pass")
	}
	
	/**
		json lacking a primary key should be rejected. A nil value should be returned and a warning
		emitted.
	*/
	func testRejectionOfJSONWithoutPrimaryKeyForUniqueObject() {
		let json: [String: String] = ["name": "Lord Byron"]
		let byron = Dandy.upsert("Dandy", from: json as [String : AnyObject])
		XCTAssert(byron == nil, "Pass")
	}
	
	/**
		An array of objects should be returned from a json array containing mappable objects.
	*/
	func testObjectArrayConstruction() {
		var json = [[String: AnyObject]]()
		for i in 0...9 {
			// TODO: Stavro - check this
			json.append(["id": String(i) as AnyObject, "name": "Morty" as AnyObject])
		}
		let dandies = Dandy.batchUpsert("Dandy", from: json)!
		let countIsCorrect = dandies.count == 10
		var dandiesAreCorrect = true
		for i in 0...9 {
			let matchingDandies = (dandies.filter{$0.value(forKey: "dandyID")! as! String == String(i)})
			if matchingDandies.count != 1 {
				dandiesAreCorrect = false
				break
			}
		}
		XCTAssert(countIsCorrect && dandiesAreCorrect, "Pass")
	}
	/**
		Objects that adopt `MappingFinalizer` should invoke `finalizeMappingForJSON(_:)` at the conclusion of its
		construction. 
		
		Gossip's map appends "_FINALIZE" to its content.
	*/
	func testMappingFinalization() {
		let input = "A decisively excellent affair, if a bit tawdry."
		let expected = "\(input)_FINALIZED"
		let json = [
			"id": "1",
			"content": input
		]
		let conclusion: Conclusion = ObjectFactory.make(entity: NSEntityDescription.forEntity(name: "Conclusion")!, from: json as [String : AnyObject]) as! Conclusion
		XCTAssert(conclusion.content == expected, "Pass")
	}
	
	// MARK: - Serialization tests -
	/**
		An object's attributes should be serializable into json.
	*/
	func testAttributeSerialization() {
		let hat = Dandy.insert("Hat")!
		hat.setValue("bowler", forKey: "name")
		hat.setValue("billycock", forKey: "styleDescription")
		let expected = [
			"name": "bowler",
			"style": "billycock"
		]
		let result = Serializer.serialize(object: hat) as! [String: String]
		XCTAssert(result == expected, "Pass")
	}
	/**
		Test nil attribute exclusion from serialized json.
	*/
	func testNilAttributeSerializationExclusion() {
		let hat = Dandy.insert("Hat")!
		hat.setValue("bowler", forKey: "name")
		hat.setValue(nil, forKey: "styleDescription")
		let expected = ["name": "bowler"]
		let result = Serializer.serialize(object: hat) as! [String: String]
		XCTAssert(result == expected, "Pass")
	}
	/**
		Relationships targeted for serialization should not be mapped to a helper array unless thay are nested.
	*/
	func testNestedRelationshipSerializationExclusion() {
		let relationships = ["hats", "gossip", "predecessor"]
		let result = Serializer.nestedSerializationTargets(for: "hats", including: relationships)
		XCTAssert(result == nil, "Pass")
	}
	/**
		Nested relationships targeted for serialization should be correctly mapped to a helper array.
	*/
	func testNestedRelationshipSerializationTargeting() {
		let relationships = ["purveyor.successor", "purveyor.hats.material", "anomaly"]
		let expected = ["successor", "hats.material"]
		let result = Serializer.nestedSerializationTargets(for: "purveyor", including: relationships)!
		XCTAssert(result == expected, "Pass")
	}
	/**
		Unspecified relationships should return no result.
	*/
		func testNoMatchingRelationshipsSerializationTargeting() {
			let relationships = ["purveyor.successor", "purveyor.hats.material"]
			let result = Serializer.nestedSerializationTargets(for: "anomaly", including: relationships)
			XCTAssert(result == nil, "Pass")
		}
	/**
		An object's attributes and to-one relationships should be serializaable into json.
	*/
	func testToOneRelationshipSerialization() {
		let hat = Dandy.insert("Hat")!
		hat.setValue("bowler", forKey: "name")
		hat.setValue("billycock", forKey: "styleDescription")
		
		let felt = Dandy.insert("Material")!
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
		] as [String: Any]
		let result = Serializer.serialize(object: hat, including:["primaryMaterial"])!
		
		XCTAssert(json(lhs: result, isEqualJSON: expected), "Pass")
	}
	/**
		An array of NSManagedObject should be serializable into json.
	*/
	func testObjectArraySerialization() {
		let byron = Dandy.insert("Dandy")!
		byron.setValue("Lord Byron", forKey: "name")
		byron.setValue("1", forKey: "dandyID")
		
		let wilde = Dandy.insert("Dandy")!
		wilde.setValue("Oscar Wilde", forKey: "name")
		wilde.setValue("2", forKey: "dandyID")
		
		let andre = Dandy.insert("Dandy")!
		andre.setValue("Andre 3000", forKey: "name")
		andre.setValue("3", forKey: "dandyID")
		
		let expected = [
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
		let result = Serializer.serialize(objects: [byron, wilde, andre])! as? [[String: String]]
		XCTAssert(result == expected, "Pass")
	}
	/**
		An object's attributes and to-many relationships should be serializaable into json.
	*/
	func testToManyRelationshipSerialization() {
		let byron = Dandy.insert("Dandy")!
		byron.setValue("Lord Byron", forKey: "name")
		byron.setValue("1", forKey: "dandyID")
		
		let bowler = Dandy.insert("Hat")!
		bowler.setValue("bowler", forKey: "name")
		bowler.setValue("billycock", forKey: "styleDescription")
		
		let tyrolean = Dandy.insert("Hat")!
		tyrolean.setValue("tyrolean", forKey: "name")
		tyrolean.setValue("alpine", forKey: "styleDescription")
		
		byron.setValue(NSSet(objects: bowler, tyrolean), forKey: "hats")
		
		let expected = [
				"id": "1",
				"name": "Lord Byron",
				"hats": [
					["name": "bowler",
					"style": "billycock"],
					["name": "tyrolean",
					"style": "alpine"]
				]
		] as [String: AnyObject]
		var result = Serializer.serialize(object: byron, including:["hats"])!
		let descriptors = [NSSortDescriptor(key: "name", ascending: true)]
		result["hats"] = (result["hats"] as? NSArray)?.sortedArray(using: descriptors) as AnyObject
		XCTAssert(json(lhs: result, isEqualJSON:expected), "Pass")
	}
	/**
		An object's attributes and relationship tree should be serializaable into json.
	*/
	func testNestedRelationshipSerialization() {
		let gossip = Dandy.insert("Gossip")!
		gossip.setValue("At Bo Peep, unusually cool towards Isabella Brown.", forKey: "details")
		gossip.setValue("John Keats", forKey: "topic")
		
		let byron = Dandy.insert("Dandy")!
		byron.setValue("Lord Byron", forKey: "name")
		byron.setValue("1", forKey: "dandyID")
		
		let bowler = Dandy.insert("Hat")!
		bowler.setValue("bowler", forKey: "name")
			bowler.setValue("billycock", forKey: "styleDescription")
		byron.setValue(NSSet(object: bowler), forKey: "hats")
		gossip.setValue(byron, forKey: "purveyor")
		
		let expected = [
				"details": "At Bo Peep, unusually cool towards Isabella Brown.",
				"topic": "John Keats",
				"purveyor": [
					"id": "1",
					"name": "Lord Byron",
					"hats": [[
						"name": "bowler",
						"style": "billycock",
					]]
				]
		] as [String: AnyObject]
		let result = Serializer.serialize(object: gossip, including: ["purveyor.hats"]) as! [String: AnyObject]

		XCTAssert(result == expected, "Pass")
	}
	
	
	// MARK: - Extension tests -
	/**
		Entries from one dictionary should add correctly to another dictionary of the same type
	*/
	func testDictionaryEntryAddition() {
		var balzac = ["name": "Honoré de Balzac"]
		let profession = ["profession": "author"]
		balzac.addEntriesFrom(dictionary: profession)
		XCTAssert(balzac["name"] == "Honoré de Balzac" && balzac["profession"] == "author", "Pass")
	}
	/**
		Values in a dictionary should be accessible via keypath
	*/
	func testValueForKeyPathExtraction() {
		let hats = [
			"name": "bowler",
			"style": "billycock",
			"material": [
				"name": "felt",
				"origin": "Rome"
			]
			] as [String: AnyObject]

		let gossip = [
			"details": "At Bo Peep, unusually cool towards Isabella Brown.",
			"topic": "John Keats",
			"purveyor": [
				"id": "1",
				"name": "Lord Byron",
				"hats": hats
			]
		] as [String: AnyObject]
		let value = valueAt(keypath: "purveyor.hats", of: gossip) as! [String: AnyObject]
		XCTAssert(value == hats, "Pass")
	}
	
	// MARK: - Warning emission tests -
	func testWarningEmission() {
		let warning = "Failed to serialize object Dandy including relationships hats"
		let log = message(warning)
		XCTAssert(log == "(CoreDataDandy) warning: " + warning, "Pass")
	}
	func testWarningErrorEmission() {
		let error = NSError(domain: "DANDY_FETCH_ERROR", code: 1, userInfo: nil)
		let warning = "Failed to serialize object Dandy including relationships hats"
		let log = message(warning, with: error)
		XCTAssert(log == "(CoreDataDandy) warning: " + warning + " Error:\n" + error.description, "Pass")
	}
	
	func json(lhs: [String: Any], isEqualJSON rhs: [String: Any]) -> Bool {
		// Dictionaries of unequal counts are not equal
		if lhs.count != rhs.count { return false }
		// Dictionaries that are equal must share all keys and paired values
		for (key, lhValue) in lhs {
			if let rhValue = rhs[key] {
				switch (lhValue, rhValue) {
				case let (l, r) where lhValue is String && rhValue is String:
					if (l as! String) != (r as! String) { return false }
				case let (l, r) where lhValue is [String: String] && rhValue is [String: String]:
					if (l as! [String: String]) != (r as! [String: String]) { return false }
				case let (l, r) where lhValue is [[String: String]] && rhValue is [[String: String]]:
					if (l as! [[String: String]]) != (r as! [[String: String]]) { return false }
				default:
					return false
				}
			} else {
				return false
			}
		}
		return true
	}
}
