//
//  CoreDataDandy+Internal.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 4/7/16.
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

/// `CoreDataDandy+Internal` attempts to conceal the inherent stringiness of Core Data. Eventually, this extension
/// should be phased out.
extension CoreDataDandy {
	
	// MARK: - Inserts -
	/// Inserts a new managed object from the specified entity name. In general, this function should not be invoked
	/// directly, as its incautious use is likely to lead to database use.
	///
	/// - parameter entityName: The name of the requested entity
	///
	/// - returns: A managed object if one could be inserted for the specified Entity.
	func _insert(entityName: String) -> NSManagedObject? {
		if let entityDescription = NSEntityDescription.forEntity(entityName) {
			// Ignore this insert if the entity is a singleton and a pre-existing insert exists.
			if entityDescription.primaryKey == SINGLETON {
				if let singleton = _singleton(entityName) {
					return singleton
				}
			}
			// Otherwise, insert a new managed object
			return NSManagedObject(entity: entityDescription, insertIntoManagedObjectContext: coordinator.mainContext)
		} else {
			log(format("NSEntityDescriptionNotFound for entity named " + entityName + ". No object will be returned"))
			return nil
		}
	}
	
	/// Attempts to fetch an `NSManagedObject` of the specified entity name matching the primary key provided.
	/// - If no property on the entity's `NSEntityDescription` is marked with the @primaryKey identifier or constraint,
	/// a warning is issued and no managed object is returned.
	/// - If an object matching the primaryKey is found, it is returned. Otherwise a new object is inserted and returned.
	/// - If more than one object is fetched for this primaryKey, a warning is issued and one is returned.
	///
	/// - parameter entityName: The name of the requested entity.
	/// - parameter primaryKeyValue: The value of the unique object's primary key
	func _insertUnique(entityName: String, identifiedBy primaryKeyValue: AnyObject) -> NSManagedObject? {
		// Return an object if one exists. Otherwise, attempt to insert one.
		if let object = _fetchUnique(entityName, identifiedBy: primaryKeyValue) {
			return object
		} else if let entityDescription = NSEntityDescription.forEntity(entityName),
			let primaryKey = entityDescription.primaryKey {
			let object = _insert(entityName)
			let convertedPrimaryKeyValue: AnyObject? = CoreDataValueConverter.convert(primaryKeyValue, for: entityDescription, property: primaryKey)
			object?.setValue(convertedPrimaryKeyValue, forKey: primaryKey)
			return object
		}
		return nil
	}
	
	// MARK: - Fetches -
	/// A simple wrapper around NSFetchRequest.
	///
	/// - parameter entityName: The name of the fetched entity
	/// - parameter predicate: The predicate used to filter results
	///
	/// - throws: If the ensuing NSManagedObjectContext's executeFetchRequest() throws, the exception will be passed.
	///
	/// - returns: If the fetch was successful, the fetched NSManagedObjects.
	func _fetch(entityName: String, filterBy predicate: NSPredicate? = nil) throws -> [NSManagedObject]? {
		let request = NSFetchRequest(entityName: entityName)
		request.predicate = predicate
		let results = try coordinator.mainContext.executeFetchRequest(request)
		return results as? [NSManagedObject]
	}
	
	/// An internal version of `fetchUnique(_:_:) used for toggling warnings that would be of no interest
	/// to the user. The warning accompanying an upsert request that begins by yielding a fetch of 0 results, for instance,
	/// is silenced.
	///
	/// - parameter entityName: The name of the fetched entity
	/// - parameter primaryKeyValue: The value of unique object's primary key.
	/// - parameter emitResultCountWarnings: When true, fetch results without exactly one object emit warnings.
	///
	/// - returns: If the fetch was successful, the fetched NSManagedObject.
	func _fetchUnique(entityName: String, identifiedBy primaryKeyValue: AnyObject, emitResultCountWarnings: Bool = false) -> NSManagedObject? {
		let entityDescription = NSEntityDescription.forEntity(entityName)
		if let entityDescription = entityDescription {
			if entityDescription.primaryKey == SINGLETON {
				if let singleton = _singleton(entityName) {
					return singleton
				}
			} else if let predicate = entityDescription.primaryKeyPredicate(for: primaryKeyValue) {
				var results: [NSManagedObject]? = nil
				do {
					results = try _fetch(entityName, filterBy: predicate)
				} catch {
					log(format("Your fetch for a unique entity named \(entityName) with identified by \(primaryKeyValue) raised an exception. This is a serious error that should be resolved immediately."))
				}
				if results?.count == 0 && emitResultCountWarnings {
					log(format("Your fetch for a unique entity named \(entityName) with identified by \(primaryKeyValue) returned no results."))
				}
				else if results?.count > 1 && emitResultCountWarnings {
					log(format("Your fetch for a unique entity named \(entityName) with identified by \(primaryKeyValue) returned multiple results. This is a serious error that should be resolved immediately."))
				}
				return results?.first
			} else {
				log(format("Failed to produce predicate for \(entityName) with identified by \(primaryKeyValue)."))
			}
		}
		log(format("A unique NSManaged for entity named \(entityName) could not be retrieved for primaryKey \(primaryKeyValue). No object will be returned"))
		return nil
	}
	
	// MARK: - Singletons -
	/// Attempts to return a singleton for a given entity.
	///
	/// - parameter entity: The name of the singleton entity
	///
	/// - returns: The singleton for this entity if one could be found.
	func _singleton(entityName: String) -> NSManagedObject? {
		// Validate the entity description to ensure fetch safety
		if let entityDescription = NSEntityDescription.entityForName(entityName, inManagedObjectContext: coordinator.mainContext) {
			do {
				if let results = try _fetch(entityName) {
					if results.count == 1 {
						return results.first
					} else if results.count == 0 {
						return NSManagedObject(entity: entityDescription, insertIntoManagedObjectContext: coordinator.mainContext)
					} else {
						log(format("Failed to fetch unique instance of entity named " + entityName + "."))
						return nil
						
					}
				}
			} catch {
				log(format("Your singleton fetch for entity named \(entityName) raised an exception. This is a serious error that should be resolved immediately."))
			}
		}
		log(format("Failed to fetch unique instance of entity named " + entityName + "."))
		return nil
	}
}
