
//
//  PersistentStackCoordinator.swift
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

/// The class responsible for maintaining the Core Data stack, including the `NSManagedObjectContexts`,
/// the `NSPersistentStore`, and the `NSPersistentStoreCoordinators`.
open class PersistentStackCoordinator {
	fileprivate var managedObjectModelName: String
	fileprivate var persistentStoreConnectionCompletion: (() -> Void)?

	public init(managedObjectModelName: String,
	            persistentStoreConnectionCompletion: (() -> Void)? = nil) {
		self.managedObjectModelName = managedObjectModelName
		self.persistentStoreConnectionCompletion = persistentStoreConnectionCompletion
	}

	// MARK: - Lazy stack initialization -
	/// The .xcdatamodel to read from.
	lazy var managedObjectModel: NSManagedObjectModel = {
		for bundle in Bundle.allBundles {
			if let url = bundle.url(forResource: self.managedObjectModelName, withExtension: "momd"),
				let mom = NSManagedObjectModel(contentsOf: url) {
				return mom
			}
		}
		preconditionFailure("Failed to find a managed object model named \(self.managedObjectModelName) in any bundle.")
	}()

	/// The persistent store coordinator, which manages disk operations.
	open lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		coordinator.resetPersistentStore()
		return coordinator
	}()

	/// The primary managed object context. Note the inclusion of the parent context, which takes disk operations off
	/// the main thread.
	open lazy var mainContext: NSManagedObjectContext = { [unowned self] in
		var mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		mainContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
		self.connectPrivateContextToPersistentStoreCoordinator()
		mainContext.parent = self.privateContext
		return mainContext
	}()

	/// Connects the private context with its PSC on the correct thread, waits for the connection to take place,
	/// then announces its completion via the initializationCompletion closure.
	func connectPrivateContextToPersistentStoreCoordinator() {
		self.privateContext.performAndWait({ [unowned self] in
			self.privateContext.persistentStoreCoordinator = self.persistentStoreCoordinator
			if let completion = self.persistentStoreConnectionCompletion {
				DispatchQueue.main.async(execute: {
					completion()
				})
			}
		})
	}

	/// A context that escorts disk operations off the main thread.
	lazy var privateContext: NSManagedObjectContext = { [unowned self] in
		var privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
		return privateContext
	}()

	// MARK: - Convenience accessors -
	/// - returns: The path to the sqlite file that stores the application's data.
	static var persistentStoreURL: URL = {
		return FileManager.documentDirectoryURL.appendingPathComponent("Model.sqlite")
	}()

	// MARK: - Stack clearing -
	/// Clear the managed object contexts.
	func resetManageObjectContext() {
		mainContext.performAndWait({[unowned self] in
			self.mainContext.reset()
			self.privateContext.performAndWait({
				self.privateContext.reset()
			})
		})
	}

	/// Attempt to remove existing persistent stores attach a new one.
	/// Note: this method should not be invoked in lazy instantiatiations of a persistentStoreCoordinator. Instead,
	/// directly call the corresponding function on the coordinator itself.
	open func resetPersistentStore() {
		persistentStoreCoordinator.resetPersistentStore()
	}
}

// MARK: - NSPersistentStoreCoordinator+Recovery -
extension NSPersistentStoreCoordinator {
	/// Attempt to remove existing persistent stores attach a new one.
	func resetPersistentStore() {
		for store in persistentStores {
			do {
				try remove(store)
			} catch {
				log(format("Failure to remove persistent store"))
			}
		}
		do {
			let document = FileManager.documentDirectoryURL
			if !FileManager.directoryExists(at: document) {
				// In the event a Document directory does not exist, create one.
				// Otherwise, the persistent store will not be added.
				try FileManager.createDirectory(at: document)
			}
			
			let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true as Bool), NSInferMappingModelAutomaticallyOption: NSNumber(value: true as Bool)]
			try addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil,
				at: PersistentStackCoordinator.persistentStoreURL,
				options: options)
			
		} catch {
			var dict = JSONObject()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
			dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data." as AnyObject?
			dict[NSUnderlyingErrorKey] = error as NSError
			let error = NSError(domain: DandyErrorDomain, code: 9999, userInfo: dict)
			log(format("Failure to add persistent store", with: error))
			do {
				try FileManager.default.removeItem(at: PersistentStackCoordinator.persistentStoreURL)
			} catch {
				log(format("Failure to remove cached sqlite file"))
			}
			EntityMapper.clearCache()
		}
	}
}
