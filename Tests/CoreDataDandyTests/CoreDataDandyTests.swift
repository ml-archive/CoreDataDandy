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
		CoreDataDandy.wakeWithMangedObjectModel("DandyModel")
		CoreDataValueConverter.dateFormatter.dateStyle = .LongStyle
		CoreDataValueConverter.dateFormatter.timeStyle = .ShortStyle
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
		Dandy.insertManagedObjectForEntity("Dandy")
		Dandy.save()
		let initialResultsCount = try! Dandy.fetchObjectsForEntity("Dandy")?.count
		Dandy.tearDown()
		let finalResultsCount = try! Dandy.fetchObjectsForEntity("Dandy")?.count
		XCTAssert(initialResultsCount == 1 && finalResultsCount == 0, "Pass")
	}
	
	// MARK: - Saves -
	/**
		After a save, the size of the persistent store should increase
	*/
	func testSave() {
		let expectation = self.expectationWithDescription("save")
		do {
			let unsavedData = try NSFileManager.defaultManager().attributesOfItemAtPath(PersistentStackCoordinator.persistentStoreURL.path!)["NSFileSize"] as! Int
			for i in 0...100000 {
				let dandy = Dandy.insertManagedObjectForEntity("Dandy")
				dandy?.setValue("\(i)", forKey: "dandyID")
			}
			Dandy.save({ (error) in
				do {
					let savedData = try NSFileManager.defaultManager().attributesOfItemAtPath(PersistentStackCoordinator.persistentStoreURL.path!)["NSFileSize"] as! Int
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
		self.waitForExpectationsWithTimeout(20, handler: { (let error) -> Void in })
	}
	
	// MARK: - Object insertions, deletions, and fetches -
	/**
		Objects should be insertable.
	*/
	func testObjectInsertion() {
		let dandy = Dandy.insertManagedObjectForEntity("Dandy")
		XCTAssert(dandy != nil, "Pass")
		XCTAssert(try! Dandy.fetchObjectsForEntity("Dandy")?.count == 1, "Pass")
	}
	/**
		Objects should be insertable in multiples.
	*/
	func testMultipleObjectInsertion() {
		for _ in 0...2 {
			Dandy.insertManagedObjectForEntity("Dandy")
		}
		XCTAssert(try! Dandy.fetchObjectsForEntity("Dandy")?.count == 3, "Pass")
	}
	/**
		Objects marked with the `@unique` primaryKey should not be inserted more than once.
	*/
	func testUniqueObjectInsertion() {
		Dandy.insertManagedObjectForEntity("Space")
		Dandy.insertManagedObjectForEntity("Space")
		XCTAssert(try! Dandy.fetchObjectsForEntity("Space")?.count == 1, "Pass")
	}
	/**
		Passing an invalid entity name should result in warning emission and a nil return
	*/
	func testInvalidObjectInsertion() {
		let object = Dandy.insertManagedObjectForEntity("ZZZ")
		XCTAssert(object == nil, "Pass")
	}
	/**
		After a value has been inserted with a primary key, the next fetch for it should return it and 
		it alone.
	*/
	func testUniqueObjectMaintenance() {
		let dandy = Dandy.uniqueManagedObjectForEntity("Dandy", primaryKeyValue: "WILDE")
		dandy?.setValue("An author, let's say", forKey: "bio")
		let repeatedDandy = Dandy.uniqueManagedObjectForEntity("Dandy", primaryKeyValue: "WILDE")
		let dandies = try! Dandy.fetchObjectsForEntity("Dandy")?.count
		XCTAssert(dandies == 1 && (repeatedDandy!.valueForKey("bio") as! String == "An author, let's say"), "Pass")
	}
	/**
		Objects should be fetchable via typical NSPredicate configured NSFetchRequests.
	*/
	func testPredicateFetch() {
		let wilde = Dandy.uniqueManagedObjectForEntity("Dandy", primaryKeyValue: "WILDE")!
		wilde.setValue("An author, let's say", forKey: "bio")
		let byron = Dandy.uniqueManagedObjectForEntity("Dandy", primaryKeyValue: "BYRON")!
		byron.setValue("A poet, let's say", forKey: "bio")
		let dandies = try! Dandy.fetchObjectsForEntity("Dandy")?.count
		let byrons = try! Dandy.fetchObjectsForEntity("Dandy", predicate: NSPredicate(format: "bio == %@", "A poet, let's say"))?.count
		XCTAssert(dandies == 2 && byrons == 1, "Pass")
	}
	/**
		After a fetch for an object with a primaryKey of the wrong type should undergo type conversion and 
		resolve correctly..
	*/
	func testPrimaryKeyTypeConversion() {
		let dandy = Dandy.uniqueManagedObjectForEntity("Dandy", primaryKeyValue: 1)
		dandy?.setValue("A poet, let's say", forKey: "bio")
		let repeatedDandy = Dandy.uniqueManagedObjectForEntity("Dandy", primaryKeyValue: "1")
		let dandies = try! Dandy.fetchObjectsForEntity("Dandy")?.count
		XCTAssert(dandies == 1 && (repeatedDandy!.valueForKey("bio") as! String == "A poet, let's say"), "Pass")
	}
	/**
		Mistaken use of a primaryKey identifying function for singleton objects should not lead to unexpected
		behavior.
	*/
	func testSingletonsIgnorePrimaryKey() {
		let space = Dandy.uniqueManagedObjectForEntity("Space", primaryKeyValue: "name")
		space?.setValue("The Gogol Empire, let's say", forKey: "name")
		let repeatedSpace = Dandy.uniqueManagedObjectForEntity("Space", primaryKeyValue: "void")
		let spaces = try! Dandy.fetchObjectsForEntity("Space")?.count
		XCTAssert(spaces == 1 && (repeatedSpace!.valueForKey("name") as! String == "The Gogol Empire, let's say"), "Pass")
	}
	/**
		The convenience function for fetching objects by primary key should return a unique object that has been inserted.
	*/
	func testUniqueObjectFetch() {
		let dandy = Dandy.uniqueManagedObjectForEntity("Dandy", primaryKeyValue: "WILDE")
		dandy?.setValue("An author, let's say", forKey: "bio")
		let fetchedDandy = Dandy.fetchUniqueObjectForEntity("Dandy", primaryKeyValue: "WILDE")!
		XCTAssert((fetchedDandy.valueForKey("bio") as! String == "An author, let's say"), "Pass")
	}
	/**
		If a primary key is not specified for an object, the fetch should fail and emit a warning.
	*/
	func testUnspecifiedPrimaryKeyValueUniqueObjectFetch() {
		let plebian = Dandy.uniqueManagedObjectForEntity("Plebian", primaryKeyValue: "plebianID")
		XCTAssert(plebian == nil, "Pass")
	}
	/**
		A deleted object should not be represented in the database
	*/
	func testObjectDeletion() {
		let space = Dandy.uniqueManagedObjectForEntity("Space", primaryKeyValue: "name")
		let previousSpaceCount = try! Dandy.fetchObjectsForEntity("Space")?.count
		let expectation = self.expectationWithDescription("Object deletion")
		Dandy.deleteManagedObject(space!) {
			let newSpaceCount = try! Dandy.fetchObjectsForEntity("Space")?.count
			XCTAssert(previousSpaceCount == 1 && newSpaceCount == 0, "Pass")
			expectation.fulfill()
		}
		self.waitForExpectationsWithTimeout(0.5, handler: { (let error) -> Void in })
	}
	
	// MARK: - Persistent Stack -
	/**
		The managed object model associated with the stack coordinator should be consistent with DandyModel.xcdatamodel.
	*/
	func testPersistentStackManagerObjectModelConstruction() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		XCTAssert(persistentStackCoordinator.managedObjectModel.entities.count == 7, "Pass")
	}
	/**
		The parentContext of the mainContext should be the privateContext. Changes to the structure of
		Dandy's persistent stack will be revealed with this test.
	*/
	func testPersistentStackManagerObjectContextConstruction() {
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel")
		XCTAssert(persistentStackCoordinator.mainContext.parentContext === persistentStackCoordinator.privateContext, "Pass")
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
		let expectation = self.expectationWithDescription("initialization")
		let persistentStackCoordinator = PersistentStackCoordinator(managedObjectModelName: "DandyModel", persistentStoreConnectionCompletion: {
			XCTAssert(true, "Pass.")
			expectation.fulfill()
		})
		persistentStackCoordinator.connectPrivateContextToPersistentStoreCoordinator()
		self.waitForExpectationsWithTimeout(5, handler: { (let error) -> Void in })
	}
	
	// MARK: - Value conversions -
	/**
		Conversions to undefined types should not occur
	*/
	func testUndefinedTypeConversion() {
		let result: AnyObject? = CoreDataValueConverter.convertValue("For us, life is five minutes of introspection", toType: .UndefinedAttributeType)
		XCTAssert(result == nil, "Pass")
	}
	/**
		Test non-conforming protocol type conversion
	*/
	func testNonConformingProtocolTypeConversion() {
		let result: AnyObject? = CoreDataValueConverter.convertValue(["life", "is", "five", "minutes", "of", "introspection"], toType: .StringAttributeType)
		XCTAssert(result == nil, "Pass")
	}
	/**
		A type convertes to the same type should undergo no changes
	*/
	func testSameTypeConversion() {
		let string: AnyObject? = CoreDataValueConverter.convertValue("For us, life is five minutes of introspection", toType: .StringAttributeType)
		XCTAssert(string is String, "Pass")
		
		let number: AnyObject? = CoreDataValueConverter.convertValue(1, toType: .Integer64AttributeType)
		XCTAssert(number is NSNumber, "Pass")
		
		let decimal: AnyObject? = CoreDataValueConverter.convertValue(NSDecimalNumber(integer: 1), toType: .DecimalAttributeType)
		XCTAssert(decimal is NSDecimalNumber, "Pass")
		
		let date: AnyObject? = CoreDataValueConverter.convertValue(NSDate(), toType: .DateAttributeType)
		XCTAssert(date is NSDate, "Pass")
		
		let encodedString = "suave".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
		let data: AnyObject? = CoreDataValueConverter.convertValue(encodedString!, toType: .BinaryDataAttributeType)
		XCTAssert(data is NSData, "Pass")
	}
	/**
		NSData objects should be convertible to Strings.
	*/
	func testDataToStringConversion() {
		let expectation: NSString = "testing string"
		let input: NSData? = expectation.dataUsingEncoding(NSUTF8StringEncoding)
		let result = CoreDataValueConverter.convertValue(input!, toType: .StringAttributeType) as? NSString
		XCTAssert(result == expectation, "")
	}
	/**
		Numbers should be convertible to Strings.
	*/
	func testNumberToStringConversion() {
		let input = 123455
		let result = CoreDataValueConverter.convertValue(input, toType: .StringAttributeType) as? String
		XCTAssert(result == "123455", "")
	}
	/**
		Numbers should be convertible to NSDecimalNumbers
	*/
	func testNumberToDecimalConversion() {
		let expectation = Double(7.070000171661375488)
		let result = CoreDataValueConverter.convertValue(NSNumber(double: expectation), toType: .DecimalAttributeType) as? NSDecimalNumber
		XCTAssert(result == NSDecimalNumber(double: expectation), "Pass")
	}
	/**
		Numbers should be convertible to Doubles
	*/
	func testNumberToDoubleConversion() {
		let expectation = Double(7.07)
		let result = CoreDataValueConverter.convertValue(NSNumber(double: expectation), toType: .DoubleAttributeType) as? Double
		XCTAssert(result == expectation, "Pass")
	}
	/**
		Numbers should be convertible to Floats
	*/
	func testNumberToFloatConversion() {
		let expectation = Float(7.07)
		let result = CoreDataValueConverter.convertValue(NSNumber(float: expectation), toType: .FloatAttributeType) as? Float
		XCTAssert(result == expectation, "Pass")
	}
	/**
		Numbers should be convertible to NSData
	*/
	func testNumberToDataConversion() {
		let input = NSNumber(float: 7.07)
		let expectation = NSNumber(float: 7.07).stringValue.dataUsingEncoding(NSUTF8StringEncoding)
		let result = CoreDataValueConverter.convertValue(input, toType: .BinaryDataAttributeType) as? NSData
		XCTAssert(result == expectation, "Pass")
	}
	/**
		Numbers should be convertible to NSDates.
	*/
	func testNumberToDateConversion() {
		let now = NSDate()
		let expectation = Double(now.timeIntervalSince1970)
		let result = CoreDataValueConverter.convertValue(expectation, toType: .DateAttributeType) as? NSDate
		let resultAsDouble = Double(result!.timeIntervalSince1970)
		XCTAssert(resultAsDouble == expectation, "")
	}
	/**
		Numbers should be convertible to Booleans.
	*/
	func testNumberToBooleanConversion() {
		var input = -1
		var result = CoreDataValueConverter.convertValue(input, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == nil, "")
		
		input = 1
		result = CoreDataValueConverter.convertValue(input, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")
		
		input = 0
		result = CoreDataValueConverter.convertValue(input, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")
		
		input = 99
		result = CoreDataValueConverter.convertValue(input, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result == true, "Pass")
	}
	/**
		NSDates should be convertible to Strings.
	*/
		func testDateToStringConversion() {
		let now = NSDate()
		let expectation = CoreDataValueConverter.dateFormatter.stringFromDate(now)
		let result = CoreDataValueConverter.convertValue(now, toType: .StringAttributeType) as? String
		XCTAssert(result == expectation, "")
	}
	/**
		NSDates should be convertible to Decimals.
	*/
	func testDateToDecimalConversion() {
		let now = NSDate()
		let expectation = NSDecimalNumber(double: now.timeIntervalSinceDate(NSDate(timeIntervalSince1970: 0)))
		let result = CoreDataValueConverter.convertValue(now, toType: .DecimalAttributeType) as! NSDecimalNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	/**
		NSDates should be convertible to Doubles.
	*/
	func testDateToDoubleConversion() {
		let now = NSDate()
		let expectation = NSNumber(double: now.timeIntervalSinceDate(NSDate(timeIntervalSince1970: 0)))
		let result = CoreDataValueConverter.convertValue(now, toType: .DoubleAttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	/**
		NSDates should be convertible to Floats.
	*/
	func testDateToFloatConversion() {
		let now = NSDate()
		let expectation = NSNumber(float: Float(now.timeIntervalSinceDate(NSDate(timeIntervalSince1970: 0))))
		let result = CoreDataValueConverter.convertValue(now, toType: .FloatAttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	/**
		NSDates should be convertible to Ints.
	*/
	func testDateToIntConversion() {
		let now = NSDate()
		let expectation = NSNumber(integer: Int(now.timeIntervalSinceDate(NSDate(timeIntervalSince1970: 0))))
		let result = CoreDataValueConverter.convertValue(now, toType: .Integer32AttributeType) as! NSNumber
		XCTAssert(result.floatValue - expectation.floatValue < 5, "")
	}
	/**
		A variety of strings should be convertible to Booleans.
	*/
	func testStringToBooleanConversion() {
		var testString = "Yes"
		var result: NSNumber?
		
		result = CoreDataValueConverter.convertValue(testString, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")
		
		testString = "trUe"
		result = CoreDataValueConverter.convertValue(testString, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")
		
		testString = "1"
		result = CoreDataValueConverter.convertValue(testString, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == true, "")
		
		testString = "NO"
		result = CoreDataValueConverter.convertValue(testString, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")
		
		testString = "false"
		result = CoreDataValueConverter.convertValue(testString, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")
		
		testString = "0"
		result = CoreDataValueConverter.convertValue(testString, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result?.boolValue == false, "")
		
		
		testString = "undefined"
		result = CoreDataValueConverter.convertValue(testString, toType: .BooleanAttributeType) as? NSNumber
		XCTAssert(result == nil, "")
	}
	/**
		Strings should be convertible to Booleans.
	*/
	func testStringToIntConversion() {
		var input = "123"
		var result = CoreDataValueConverter.convertValue(input, toType: .Integer64AttributeType) as? NSNumber
		XCTAssert(result?.integerValue == 123, "")
		
		input = "456wordsdontmatter123"
		result = CoreDataValueConverter.convertValue(input, toType: .Integer64AttributeType) as? NSNumber
		XCTAssert(result?.integerValue == 456, "")
		
		input = "nothingHereMatters"
		result = CoreDataValueConverter.convertValue(input, toType: .Integer64AttributeType) as? NSNumber
		XCTAssert(result?.integerValue == 0, "")
	}
	/**
		NSStrings should be convertible to NSDecimalNumbers
	*/
	func testStringToDecimalConversion() {
		let expectation = NSDecimalNumber(float: 7.070000171661375488)
		let result = CoreDataValueConverter.convertValue("7.070000171661375488", toType: .DecimalAttributeType) as? NSDecimalNumber
		XCTAssert(result == expectation, "Pass")
	}
	/**
		NSStrings should be convertible to Doubles
	*/
	func testStringToDoubleConversion() {
		let expectation = Double(7.07)
		let result = CoreDataValueConverter.convertValue("7.07", toType: .DoubleAttributeType) as? Double
		XCTAssert(result == expectation, "Pass")
	}
	/**
		NSStrings should be convertible to Floats
	*/
	func testStringToFloatConversion() {
		let expectation = Float(7.07)
		let result = CoreDataValueConverter.convertValue("7.07", toType: .FloatAttributeType) as? Float
		XCTAssert(result == expectation, "Pass")
	}
	/**
		Strings should be convertible to Data objects.
	*/
	func testStringToDataConversion() {
		let input = "Long long Time ago"
		let expectedResult = input.dataUsingEncoding(NSUTF8StringEncoding)!
		let result = CoreDataValueConverter.convertValue(input, toType: .BinaryDataAttributeType) as? NSData
		XCTAssert(result!.isEqualToData(expectedResult) == true, "")
	}
	/**
		Strings should be convertible to NSDates.
	*/
	func testStringToDateConversion() {
		let now = NSDate()
		let nowAsString = CoreDataValueConverter.dateFormatter.stringFromDate(now)
		let result = CoreDataValueConverter.convertValue(nowAsString, toType: .DateAttributeType) as? NSDate
		let resultAsString = CoreDataValueConverter.dateFormatter.stringFromDate(result!)
		XCTAssert(resultAsString == nowAsString, "")
	}
	
	// MARK: - Mapping -
	func testEntityDescriptionFromString() {
		let expected = NSEntityDescription.entityForName("Dandy", inManagedObjectContext: Dandy.coordinator.mainContext)
		let result = NSEntityDescription.forEntity("Dandy")!
		XCTAssert(expected == result, "Pass")
	}
	func testPrimaryKeyIdentification() {
		let expected = "dandyID"
		let dandy = NSEntityDescription.forEntity("Dandy")!
		let result = dandy.primaryKey!
		XCTAssert(expected == result, "Pass")
	}
	
	/**
		Entity descriptions with no specified mapping should read into mapping dictionaries with all "same name" mapping
	*/
	func testSameNameMap() {
		let entity = NSEntityDescription.forEntity("Material")!
		let expectedMap = [
			"name": PropertyDescription(description: entity.allAttributes!["name"]!),
			"origin": PropertyDescription(description: entity.allAttributes!["origin"]!),
			"hats": PropertyDescription(description: entity.allRelationships!["hats"]!)
		]
		let result = EntityMapper.mapForEntity(entity)
		XCTAssert(result! == expectedMap, "Pass")
	}
	/**
		@mapping: @NO should result in an exclusion from the map. Gossip's "secret" attribute has been specified
		as such.
	*/
	func testNOMappingKeywordResponse() {
		let entity = NSEntityDescription.forEntity("Gossip")!
		let expectedMap = [
			"details": PropertyDescription(description: entity.allAttributes!["details"]!),
			"topic": PropertyDescription(description: entity.allAttributes!["topic"]!),
			// "secret": "unmapped"
			"purveyor": PropertyDescription(description: entity.allRelationships!["purveyor"]!)
		]
		let result = EntityMapper.mapForEntity(entity)!
		XCTAssert(result == expectedMap, "Pass")
	}
	/**
		If an alternate keypath is specified, that keypath should appear as a key in the map. Space's "spaceState" has been specified
		to map from "state."
	*/
	func testAlternateKeypathMappingResponse() {
		let entity = NSEntityDescription.forEntity("Space")!
		let expectedMap = [
			"name": PropertyDescription(description: entity.allAttributes!["name"]!),
			"state": PropertyDescription(description: entity.allAttributes!["spaceState"]!)
		]
		let result = EntityMapper.mapForEntity(entity)!
		XCTAssert(result == expectedMap, "Pass")
	}
	
	// MARK: - Property description comparisons and caching -
	/**
		Comparisons of property descriptions should evaluate correctly.
	*/
	func testPropertyDescriptionComparison() {
		let entity = NSEntityDescription.forEntity("Space")!
		let name = PropertyDescription(description: entity.allAttributes!["name"]!)
		let secondName = PropertyDescription(description: entity.allAttributes!["name"]!)
		let state = PropertyDescription(description: entity.allAttributes!["spaceState"]!)
		XCTAssert(name == secondName, "Pass")
		XCTAssert(name != state, "Pass")
		XCTAssert(name != "STRING", "Pass")
	}
	/**
		Simple initializations and initializations from NSCoding should yield valid objects.
	*/
	func testPropertyDescriptionInitialization() {
		let _ = PropertyDescription()
		
		let entity = NSEntityDescription.forEntity("Space")!
		let propertyDescription = PropertyDescription(description: entity.allAttributes!["name"]!)
		let pathArray = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
		let documentPath = pathArray.first!
		let archivePath = NSString(string: documentPath).stringByAppendingPathComponent("SPACE_NAME")
		NSKeyedArchiver.archiveRootObject(propertyDescription, toFile: archivePath)
		let unarchivedPropertyDescription = NSKeyedUnarchiver.unarchiveObjectWithFile(archivePath) as! PropertyDescription
		XCTAssert(unarchivedPropertyDescription == propertyDescription, "Pass")
	}
	
	// - MARK: Map caching -
	/**
		The first access to an entity's map should result in that map's caching
	*/
	func testMapCaching() {
		let entityName = "Material"
		if let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: Dandy.coordinator.mainContext) {
			EntityMapper.mapForEntity(entityDescription)
			let entityCacheMap = EntityMapper.cachedEntityMap[entityName]!
			XCTAssert(entityCacheMap.count > 0, "")
		}
	}
	/**
		When clean up is called, no cached maps should remain
	*/
	func testMapCacheCleanUp() {
		let entityName = "Material"
		if let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: Dandy.coordinator.mainContext) {
			EntityMapper.mapForEntity(entityDescription)
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
		self.measureBlock {
			let entityDescription = NSEntityDescription.entityForName("Material", inManagedObjectContext: Dandy.coordinator.mainContext)
			EntityMapper.mapForEntity(entityDescription!)
		}
	}
	/**
		The fetching of a cached map should be performant, and more performant than the creation of a new map
	*/
	func testPerformanceOfCachedMapRetrieval() {
		let entityDescription = NSEntityDescription.entityForName("Material", inManagedObjectContext: Dandy.coordinator.mainContext)!
		EntityMapper.mapForEntity(entityDescription)
		self.measureBlock {
			EntityMapper.mapForEntity(entityDescription)
		}
	}
	
	// - MARK: Object building -
	/**
		Values should be mapped from json to an object's attributes.
	*/
	func testAttributeBuilding() {
		let space = Dandy.insertManagedObjectForEntity("Space")!
		let json = ["name": "nebulous", "state": "moderately cool"]
		ObjectFactory.buildObject(space, fromJSON: json)
		XCTAssert(space.valueForKey("name") as! String == "nebulous" &&
			space.valueForKey("spaceState") as! String ==  "moderately cool",
			"Pass")
	}
	/**
		Values should be mapped from json an object's relationships.
	*/
	func testRelationshipBuilding() {
		let gossip = Dandy.insertManagedObjectForEntity("Gossip")!
		let json = [
			"details": "At Bo Peep, unusually cool towards Isabella Brown.",
			"topic": "John Keats",
			"purveyor": [
				"id": 1,
				"name": "Lord Byron",
			]
		]
		ObjectFactory.buildObject(gossip, fromJSON: json)
		let byron = gossip.valueForKey("purveyor") as! NSManagedObject
		XCTAssert(gossip.valueForKey("details") as! String == "At Bo Peep, unusually cool towards Isabella Brown." &&
			gossip.valueForKey("topic") as! String ==  "John Keats" &&
			byron.valueForKey("dandyID") as! String ==  "1" &&
			byron.valueForKey("name") as! String ==  "Lord Byron",
			"Pass")
	}
	/**
		Values should be recursively mapped from nested json objects.
	*/
	func testRecursiveObjectBuilding() {
		let gossip = Dandy.insertManagedObjectForEntity("Gossip")!
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
		]
		ObjectFactory.buildObject(gossip, fromJSON: json)
		let byron = gossip.valueForKey("purveyor") as! NSManagedObject
		let bowler = byron.valueForKey("hats")!.anyObject() as! NSManagedObject
		let felt = bowler.valueForKey("primaryMaterial") as! NSManagedObject
		XCTAssert(gossip.valueForKey("details") as! String == "At Bo Peep, unusually cool towards Isabella Brown." &&
			gossip.valueForKey("topic") as! String ==  "John Keats" &&
			byron.valueForKey("dandyID") as! String ==  "1" &&
			byron.valueForKey("name") as! String ==  "Lord Byron" &&
			bowler.valueForKey("name") as! String ==  "bowler" &&
			bowler.valueForKey("styleDescription") as! String ==  "billycock" &&
			felt.valueForKey("name") as! String ==  "felt" &&
			felt.valueForKey("origin") as! String ==  "Rome",
			"Pass")
	}
	/**
		@mapping values that contain a keypath should allow access to json values via a keypath
	*/
	func testKeyPathBuilding() {
		let dandy = Dandy.insertManagedObjectForEntity("Dandy")!
		let json = [
			"id": "BAUD",
			"relatedDandies": [
				"predecessor": [
					"id": "BALZ",
					"name": "Honoré de Balzac"
				]
			]
		] as [String: AnyObject]
		ObjectFactory.buildObject(dandy, fromJSON: json)
		let balzac = dandy.valueForKey("predecessor") as! NSManagedObject
		XCTAssert(balzac.valueForKey("dandyID") as! String == "BALZ" &&
			balzac.valueForKey("name") as! String ==  "Honoré de Balzac" &&
			(balzac.valueForKey("successor") as! NSManagedObject).valueForKey("dandyID") as! String ==  dandy.valueForKey("dandyID") as! String,
			"Pass")
	}
	/**
		Property values on an object should not be overwritten if no new values are specified.
	*/
	func testIgnoreUnkeyedAttributesWhenBuilding() {
		let space = Dandy.insertManagedObjectForEntity("Space")!
		space.setValue("exceptionally relaxed", forKey: "spaceState")
		let json = ["name": "nebulous"]
		ObjectFactory.buildObject(space, fromJSON: json)
		XCTAssert(space.valueForKey("spaceState") as! String == "exceptionally relaxed", "Pass")
	}
	/**
		Property values on an object should be overwritten if new values are specified.
	*/
	func testOverwritesKeyedAttributesWhenBuilding() {
		let space = Dandy.insertManagedObjectForEntity("Space")!
		space.setValue("exceptionally relaxed", forKey: "spaceState")
		let json = ["state": "significant excitement"]
		ObjectFactory.buildObject(space, fromJSON: json)
		XCTAssert(space.valueForKey("spaceState") as! String == "significant excitement", "Pass")
	}
	/**
		If a single json object is passed when attempting to build a toMany relationship, it should be
		rejected.
	*/
	func testSingleObjectToManyRelationshipRejection() {
		let dandy = Dandy.insertManagedObjectForEntity("Dandy")!
		let json = [
			"name": "bowler",
			"style": "billycock",
			"material": [
				"name": "felt",
				"origin": "Rome"
			]
		]
		ObjectFactory.buildRelationship(PropertyDescription(description: dandy.entity.allRelationships!["hats"]!), fromJSON: json, forObject: dandy)
		XCTAssert((dandy.valueForKey("hats") as! NSSet).count == 0, "Pass")
	}
	/**
		If a json array is passed when attempting to build a toOne relationship, it should be
		rejected.
	*/
	func testArrayOfObjectToOneRelationshipRejection() {
		let gossip = Dandy.insertManagedObjectForEntity("Gossip")!
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
		ObjectFactory.buildRelationship(PropertyDescription(description: gossip.entity.allRelationships!["purveyor"]!), fromJSON: json, forObject: gossip)
		XCTAssert(gossip.valueForKey("purveyor") == nil, "Pass")
	}
	/**
		NSOrderedSets should be created for ordered relationships. NSSets should be created for 
		unordered relationships.
	*/
	func testOrderedRelationshipsBuilding() {
		let hat = Dandy.insertManagedObjectForEntity("Hat")!
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
		ObjectFactory.buildRelationship(PropertyDescription(description: hat.entity.allRelationships!["dandies"]!), fromJSON: json, forObject: hat)
		XCTAssert(hat.valueForKey("dandies") is NSOrderedSet && (hat.valueForKey("dandies") as! NSOrderedSet).count == 3, "Pass")
	}
	
	// MARK: -  Object factory via CoreDataDandy -
	/**
		json containing a valid primary key should result in unique, mapped objects.
	*/
	func testSimpleObjectConstructionFromJSON() {
		let json = ["name": "Passerby"]
		let plebian = Dandy.managedObjectForEntity("Plebian", fromJSON: json)!
		XCTAssert(plebian.valueForKey("name") as! String == "Passerby")
	}
	/**
		json lacking a primary key should be rejected. A nil value should be returned and a warning
		emitted.
	*/
	func testUniqueObjectConstructionFromJSON() {
		let json = ["name": "Lord Byron"]
		let byron = Dandy.managedObjectForEntity("Dandy", fromJSON: json)
		XCTAssert(byron == nil, "Pass")
	}
	
	/**
		json lacking a primary key should be rejected. A nil value should be returned and a warning
		emitted.
	*/
	func testRejectionOfJSONWithoutPrimaryKeyForUniqueObject() {
		let json = ["name": "Lord Byron"]
		let byron = Dandy.managedObjectForEntity("Dandy", fromJSON: json)
		XCTAssert(byron == nil, "Pass")
	}
	
	/**
		An array of objects should be returned from a json array containing mappable objects.
	*/
	func testObjectArrayConstruction() {
		var json = [[String: AnyObject]]()
		for i in 0...9 {
			json.append(["id": String(i), "name": "Morty"])
		}
		let dandies = Dandy.managedObjectsForEntity("Dandy", fromJSON: json)!
		let countIsCorrect = dandies.count == 10
		var dandiesAreCorrect = true
		for i in 0...9 {
			let matchingDandies = (dandies.filter{$0.valueForKey("dandyID")! as! String == String(i)})
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
		let conclusion = ObjectFactory.objectFromEntity(NSEntityDescription.forEntity("Conclusion")!, json: json) as! Conclusion
		XCTAssert(conclusion.content == expected, "Pass")
	}
	
	// MARK: - Serialization tests -
	/**
		An object's attributes should be serializable into json.
	*/
	func testAttributeSerialization() {
		let hat = Dandy.insertManagedObjectForEntity("Hat")!
		hat.setValue("bowler", forKey: "name")
		hat.setValue("billycock", forKey: "styleDescription")
		let expected = [
			"name": "bowler",
			"style": "billycock"
		]
		let result = Serializer.serializeObject(hat) as! [String: String]
		XCTAssert(result == expected, "Pass")
	}
	/**
		Test nil attribute exclusion from serialized json.
	*/
	func testNilAttributeSerializationExclusion() {
		let hat = Dandy.insertManagedObjectForEntity("Hat")!
		hat.setValue("bowler", forKey: "name")
		hat.setValue(nil, forKey: "styleDescription")
		let expected = ["name": "bowler"]
		let result = Serializer.serializeObject(hat) as! [String: String]
		XCTAssert(result == expected, "Pass")
	}
	/**
		Relationships targeted for serialization should not be mapped to a helper array unless thay are nested.
	*/
	func testNestedRelationshipSerializationExclusion() {
		let relationships = ["hats", "gossip", "predecessor"]
		let result = Serializer.nestedSerializationTargetsForRelationship("hats", includeRelationships: relationships)
		XCTAssert(result == nil, "Pass")
	}
	/**
		Nested relationships targeted for serialization should be correctly mapped to a helper array.
	*/
	func testNestedRelationshipSerializationTargeting() {
		let relationships = ["purveyor.successor", "purveyor.hats.material", "anomaly"]
		let expected = ["successor", "hats.material"]
		let result = Serializer.nestedSerializationTargetsForRelationship("purveyor", includeRelationships: relationships)!
		XCTAssert(result == expected, "Pass")
	}
	/**
		Unspecified relationships should return no result.
	*/
		func testNoMatchingRelationshipsSerializationTargeting() {
			let relationships = ["purveyor.successor", "purveyor.hats.material"]
			let result = Serializer.nestedSerializationTargetsForRelationship("anomaly", includeRelationships: relationships)
			XCTAssert(result == nil, "Pass")
		}
	/**
		An object's attributes and to-one relationships should be serializaable into json.
	*/
	func testToOneRelationshipSerialization() {
		let hat = Dandy.insertManagedObjectForEntity("Hat")!
		hat.setValue("bowler", forKey: "name")
				hat.setValue("billycock", forKey: "styleDescription")
		let felt = Dandy.insertManagedObjectForEntity("Material")!
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
		]
		let result = Serializer.serializeObject(hat, includeRelationships:["primaryMaterial"])!
		XCTAssert(json(result, isEqualJSON: expected), "Pass")
	}
	/**
		An array of NSManagedObject should be serializable into json.
	*/
	func testObjectArraySerialization() {
		let byron = Dandy.insertManagedObjectForEntity("Dandy")!
		byron.setValue("Lord Byron", forKey: "name")
		byron.setValue("1", forKey: "dandyID")
		let wilde = Dandy.insertManagedObjectForEntity("Dandy")!
		wilde.setValue("Oscar Wilde", forKey: "name")
		wilde.setValue("2", forKey: "dandyID")
		let andre = Dandy.insertManagedObjectForEntity("Dandy")!
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
		let result = Serializer.serializeObjects([byron, wilde, andre])!
		XCTAssert(result == expected, "Pass")
	}
	/**
		An object's attributes and to-many relationships should be serializaable into json.
	*/
	func testToManyRelationshipSerialization() {
		let byron = Dandy.insertManagedObjectForEntity("Dandy")!
		byron.setValue("Lord Byron", forKey: "name")
		byron.setValue("1", forKey: "dandyID")
		let bowler = Dandy.insertManagedObjectForEntity("Hat")!
		bowler.setValue("bowler", forKey: "name")
		bowler.setValue("billycock", forKey: "styleDescription")
		let tyrolean = Dandy.insertManagedObjectForEntity("Hat")!
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
		]
		var result = Serializer.serializeObject(byron, includeRelationships:["hats"])!
		result["hats"] = (result["hats"] as! NSArray).sortedArrayUsingDescriptors([NSSortDescriptor(key: "name", ascending: true)])
		XCTAssert(json(result, isEqualJSON:expected), "Pass")
	}
	/**
		An object's attributes and relationship tree should be serializaable into json.
	*/
	func testNestedRelationshipSerialization() {
		let gossip = Dandy.insertManagedObjectForEntity("Gossip")!
		gossip.setValue("At Bo Peep, unusually cool towards Isabella Brown.", forKey: "details")
		gossip.setValue("John Keats", forKey: "topic")
		let byron = Dandy.insertManagedObjectForEntity("Dandy")!
		byron.setValue("Lord Byron", forKey: "name")
		byron.setValue("1", forKey: "dandyID")
		let bowler = Dandy.insertManagedObjectForEntity("Hat")!
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
		]
		let result = Serializer.serializeObject(gossip, includeRelationships: ["purveyor.hats"]) as! [String: NSObject]
		XCTAssert(result == expected, "Pass")
	}
	
	// - MARK: Extension tests -
	/**
		Entries from one dictionary should add correctly to another dictionary of the same type
	*/
	func testDictionaryEntryAddition() {
		var balzac = ["name": "Honoré de Balzac"]
		let profession = ["profession": "author"]
		balzac.addEntriesFromDictionary(profession)
		XCTAssert(balzac["name"] == "Honoré de Balzac" && balzac["profession"] == "author", "Pass")
	}
	/**
		Values in a dictionary should be accessible via keypath
	*/
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
		]
		let value = _valueForKeyPath("purveyor.hats", dictionary: gossip) as! [[String: AnyObject]]
		XCTAssert(value == hats, "Pass")
	}
	
	// MARK: - Warning emission tests - 
	func testWarningEmission() {
		let warning = "Failed to serialize object Dandy including relationships hats"
		let message = emitWarningWithMessage(warning)
		XCTAssert(message == "(CoreDataDandy) warning: " + warning, "Pass")
	}
	func testWarningErrorEmission() {
		let error = NSError(domain: "DANDY_FETCH_ERROR", code: 1, userInfo: nil)
		let warning = "Failed to serialize object Dandy including relationships hats"
		let message = emitWarningWithMessage(warning, error: error)
		XCTAssert(message == "(CoreDataDandy) warning: " + warning + " Error:\n" + error.description, "Pass")
	}
	
	func json(lhs: [String: AnyObject], isEqualJSON rhs: [String: AnyObject]) -> Bool {
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
	
	/**
		The primary key should return the uniquenessConstraint of the entity if one is present.
		The Gossip entity has a uniquenessConstraint called 'details' in the model, with no @primaryKey
	*/
	func testUniqueConstraint() {
		let gossip = Dandy.insertManagedObjectForEntity("Gossip")!
		
		XCTAssert(gossip.entity.primaryKey == "details", "Pass")
	}
	
	/**
		The primary key should return the uniquenessConstraint instead of the primaryKey if both a primaryKey and a uniquenessConstraint is present.
		The Conclusion entity has a uniquenessConstraint called 'id' in the model, with a @primaryKey called 'content'
	*/
	func testUniqueConstraintPriority() {
		let testConclusion = Dandy.insertManagedObjectForEntity("Conclusion")!
		
		XCTAssert(testConclusion.entity.primaryKey == "id", "Pass")
	}
}