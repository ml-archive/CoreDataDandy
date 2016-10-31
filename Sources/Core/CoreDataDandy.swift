//
//  CoreDataDandy.swift
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

import CoreData

/// `CoreDataDandy` provides an interface to the majority of the module's features, which include Core Data
/// bootstrapping, main and background-threaded context management, convenient `NSFetchRequests`,
/// database inserts, database deletes, and `NSManagedObject` deserialization.
open class CoreDataDandy {
	// MARK: - Properties -
	/// A singleton encapsulating much of CoreDataDandy's base functionality.
	fileprivate static let defaultDandy = CoreDataDandy()

	/// The default implementation of Dandy. Subclasses looking to extend or alter Dandy's functionality
	/// should override this getter and provide a new instance.
	open class var sharedDandy: CoreDataDandy {
		return defaultDandy
	}

	/// A manager of the NSManagedObjectContext, NSPersistentStore, and NSPersistentStoreCoordinator.
	/// Accessing this property directly is generaly discouraged - it is intended for use within the module alone.
	open var coordinator: PersistentStackCoordinator!

	// MARK: - Initialization-
	/// Bootstraps the application's core data stack.
	///
	/// - parameter managedObjectModelName: The name of the .xcdatamodel file
	/// - parameter completion: A completion block executed on initialization completion
	@discardableResult open class func wake(_ managedObjectModelName: String,
											completion: (() -> Void)? = nil) -> CoreDataDandy {
		EntityMapper.clearCache()
		sharedDandy.coordinator = PersistentStackCoordinator(managedObjectModelName: managedObjectModelName,
												persistentStoreConnectionCompletion: completion)
		return sharedDandy
	}

	// MARK: -  Deinitialization -
	/// Removes all cached data from the application without endangering future database
	/// interactions.
	open func tearDown() {
		coordinator.resetManageObjectContext()

		do {
			try FileManager.default.removeItem(at: PersistentStackCoordinator.persistentStoreURL as URL)
		} catch {
			log(format("Failed to delete persistent store"))
		}

		coordinator.resetPersistentStore()
		EntityMapper.clearCache()
		save()
	}

	// MARK: - Inserts -
	/// Inserts a new Model from the specified entity type. In general, this function should not be invoked
	/// directly, as its incautious use is likely to lead to database leaks.
	///
	/// - parameter type: The type of Model to insert
	///
	/// - returns: A managed object if one could be inserted for the specified Entity.
	@discardableResult open func insert<Model: NSManagedObject>(_ type: Model.Type) -> Model? {
		if let entityDescription = type.entityDescription() {
			// Ignore this insert if the entity is a singleton and a pre-existing insert exists.
			if entityDescription.primaryKey == SINGLETON {
				if let singleton = singleton(type) {
					return singleton
				}
			}
			// Otherwise, insert a new managed object
			return type.inserted() as? Model
		} else {
			log(format("NSEntityDescriptionNotFound for entity named " + String(describing: type) + ". No object will be returned"))
			return nil
		}
	}

	/// MARK: - Upserts -
	/// This function performs upserts differently depending on whether the Model is marked as unique or not.
	///
	/// If the Model is marked as unique (either through an @primaryKey decoration or an xcdatamode constraint), the
	/// primaryKeyValue is extracted and an upsert is performed through
	/// `upsertUnique(_:, identifiedBy:) -> NSManagedObject?`.
	///
	/// Otherwise, an insert is performed and a Model is written to from the json provided.
	///
	/// - parameter type: The type of Model to insert
	/// - parameter json: A json object to map into the returned object's attributes and relationships
	///
	/// - returns: A managed object if one could be created.
	@discardableResult open func upsert<Model: NSManagedObject>(_ type: Model.Type,
	                                                            from json: JSONObject) -> Model? {
		guard let entity = NSEntityDescription.forType(type) else {
			log(format("Could not retrieve NSEntityDescription for type \(type)"))
			return nil
		}

		if entity.isUnique {
			if let primaryKeyValue = entity.primaryKeyValueFromJSON(json) {
				return upsertUnique(type, identifiedBy: primaryKeyValue, from: json)
			} else {
				log(format("Could not retrieve primary key from json \(json)."))
				return nil
			}
		}

		if let managedObject = insert(type) {
			return ObjectFactory.build(managedObject, from: json)
		}

		return nil
	}

	/// Attempts to build an array Models from a json array. Through recursion, behaves identically to
	/// upsert(_:, _:) -> Model?.
	///
	/// - parameter type: The type of Model to insert
	/// - parameter json: An array to map into the returned objects' attributes and relationships
	///
	/// - returns: An array of managed objects if one could be created.
	@discardableResult open func batchUpsert<Model: NSManagedObject>(_ type: Model.Type,
	                                                                 from json: [JSONObject]) -> [Model]? {
		var models = [Model]()
		for object in json {
			if let model = upsert(type, from: object) {
				models.append(model)
			}
		}
		return models.isEmpty ? nil : models
	}

	// MARK: - Unique objects -
	/// Attempts to fetch a Model of the specified type matching the primary key provided.
	/// - If no property on the type's `NSEntityDescription` is marked with the @primaryKey identifier or constraint,
	/// a warning is issued and no managed object is returned.
	/// - If an object matching the primaryKey is found, it is returned. Otherwise a new object is inserted and returned.
	/// - If more than one object is fetched for this primaryKey, a warning is issued and one is returned.
	///
	/// - parameter type: The type of Model to insert.
	/// - parameter primaryKeyValue: The value of the unique object's primary key
	@discardableResult open func insertUnique<Model: NSManagedObject>(_ type: Model.Type,
	                                                                  identifiedBy primaryKeyValue: Any) -> Model? {
		// Return an object if one exists. Otherwise, attempt to insert one.
		if let object = fetchUnique(type, identifiedBy: primaryKeyValue) {
			return object
		} else if let entityDescription = type.entityDescription(),
		  let primaryKey = entityDescription.primaryKey {
			let object = insert(type)
			let convertedPrimaryKeyValue = CoreDataValueConverter.convert(primaryKeyValue, for: entityDescription, property: primaryKey)
			object?.setValue(convertedPrimaryKeyValue, forKey: primaryKey)
			
			return object
		}
		return nil
	}

	/// Invokes `upsertUnique(_:, identifiedBy:) -> Model?`, then attempts to write values from
	/// the provided JSON into the returned object.
	///
	/// - parameter type: The type of the requested entity
	/// - parameter primaryKeyValue: The value of the unique object's primary key
	/// - parameter json: A json object to map into the returned object's attributes and relationships
	///
	/// - returns: A managed object if one could be created.
	private func upsertUnique<Model: NSManagedObject>(_ type: Model.Type,
													  identifiedBy primaryKeyValue: Any,
													  from json: JSONObject) -> Model? {
		if let object = insertUnique(type, identifiedBy: primaryKeyValue) {
			ObjectFactory.build(object, from: json)
			return object
		} else {
			log(format("Could not upsert managed object of type \(type), identified by \(primaryKeyValue), json \(json)."))
			return nil
		}
	}

	// MARK: - Fetches -
	/// A wrapper around NSFetchRequest.
	///
	/// - parameter type: The type of the fetched entity
	/// - parameter predicate: The predicate used to filter results
	///
	/// - throws: If the ensuing NSManagedObjectContext's executeFetchRequest() throws, the exception will be passed.
	///
	/// - returns: If the fetch was successful, the fetched Model.
	open func fetch<Model: NSManagedObject>(_ type: Model.Type,
	                                        filterBy predicate: NSPredicate? = nil) throws -> [Model]? {
		let fetchRequest: NSFetchRequest<Model> = NSFetchRequest(entityName: String(describing: type))
		fetchRequest.predicate = predicate
		return try coordinator.mainContext.fetch(fetchRequest)
	}
	
	/// Attempts to fetch a unique Model with a primary key value matching the passed in parameter.
	///
	/// - parameter type: The type of the fetched entity
	/// - parameter primaryKeyValue: The value of unique object's primary key
	///
	/// - returns: If the fetch was successful, the fetched Model.
	open func fetchUnique<Model: NSManagedObject>(_ type: Model.Type,
	                                              identifiedBy primaryKeyValue: Any,
	                                              emitResultCountWarnings: Bool = false) -> Model? {
		if let entityDescription = type.entityDescription() {
			if entityDescription.primaryKey == SINGLETON {
				if let singleton = singleton(type) {
					return singleton
				}
			} else if let predicate = entityDescription.primaryKeyPredicate(for: primaryKeyValue) {
				var results: [NSManagedObject]? = nil
				var resultCount = 0
				do {
					results = try fetch(type, filterBy: predicate)
					resultCount = results?.count ?? 0
				} catch {
					log(format("Your fetch for a unique entity named \(String(describing: type)) with identified by \(primaryKeyValue) raised an exception. This is a serious error that should be resolved immediately."))
				}
				if resultCount == 0 && emitResultCountWarnings {
					log(format("Your fetch for a unique entity named \(String(describing: type)) with identified by \(primaryKeyValue) returned no results."))
				} else if resultCount > 1 && emitResultCountWarnings {
					log(format("Your fetch for a unique entity named \(String(describing: type)) with identified by \(primaryKeyValue) returned multiple results. This is a serious error that should be resolved immediately."))
				}
				return results?.first as? Model
			} else {
				log(format("Failed to produce predicate for \(String(describing: type)) with identified by \(primaryKeyValue)."))
			}
		}
		
		log(format("A unique NSManaged for entity named \(String(describing: type)) could not be retrieved for primaryKey \(primaryKeyValue). No object will be returned"))
		
		return nil
	}

	// MARK: - Saves and Deletes -
	/// Save the current state of the `NSManagedObjectContext` to disk and optionally receive notice of the save
	/// operation's completion.
	///
	/// - parameter completion: An optional closure that is invoked when the save operation complete. If the save operation
	/// 	resulted in an error, the error is returned.
	open func save(_ completion:((_ error: Error?) -> Void)? = nil) {
		/**
		Note: http://www.openradar.me/21745663. Currently, there is no way to throw out of performBlock. If one arises,
		this code should be refactored to throw.
		*/
		if !coordinator.mainContext.hasChanges && !coordinator.privateContext.hasChanges {
			completion?(nil)
			return
		}
		coordinator.mainContext.performAndWait({[unowned self] in
			do {
				try self.coordinator.mainContext.save()
			} catch {
				log(format( "Failed to save main context."))
				completion?(error)
				return
			}

			self.coordinator.privateContext.perform({ [unowned self] in
				do {
					try self.coordinator.privateContext.save()
					completion?(nil)
				} catch {
					log(format( "Failed to save private context."))
					completion?(error)
				}
			})
		})
	}

	/// Delete a managed object.
	///
	/// - parameter object: The object to be deleted.
	/// - parameter completion: An optional closure that is invoked when the deletion is complete.
	open func delete(_ object: NSManagedObject, completion: (() -> Void)? = nil) {
		if let context = object.managedObjectContext {
			context.perform({
				context.delete(object)
				completion?()
			})
		}
	}
	
	// MARK: - Singletons -
	/// Attempts to singleton of a given type.
	///
	/// - parameter type: The type of the singleton
	///
	/// - returns: The singleton for this type if one could be found.
	fileprivate func singleton<Model: NSManagedObject>(_ type: Model.Type) -> Model? {
		do {
			if let results = try fetch(type) {
				if results.count == 1 {
					return results.first
				} else if results.count == 0 {
					return type.inserted() as? Model
				} else {
					log(format("Failed to fetch unique instance of entity named " + String(describing: type) + "."))
					return nil
					
				}
			}
		} catch {
			log(format("Your singleton fetch for entity named \(String(describing: type)) raised an exception. This is a serious error that should be resolved immediately."))
		}
	
		log(format("Failed to fetch unique instance of entity named " + String(describing: type) + "."))
		return nil
	}
}

// MARK: - Convenience accessors -
/// A lazy global for more succinct access to CoreDataDandy's sharedDandy.
public let Dandy: CoreDataDandy = CoreDataDandy.sharedDandy
