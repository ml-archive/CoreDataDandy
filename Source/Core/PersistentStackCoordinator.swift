
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
public class PersistentStackCoordinator {
	private var managedObjectModelName: String
	private var persistentStoreConnectionCompletion: (() -> Void)?
	
	public init(managedObjectModelName: String, persistentStoreConnectionCompletion: (() -> Void)? = nil) {
		self.managedObjectModelName = managedObjectModelName
		self.persistentStoreConnectionCompletion = persistentStoreConnectionCompletion
	}
	
	// MARK: - Lazy stack initialization -
	/// The .xcdatamodel to read from.
	lazy var managedObjectModel: NSManagedObjectModel = {
		let modelURL = Bundle(for: type(of: self)).url(forResource: self.managedObjectModelName, withExtension: "momd")!
		return NSManagedObjectModel(contentsOf: modelURL)!
	}()
	
	/// The persistent store coordinator, which manages disk operations.
	public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		var coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		coordinator.resetPersistentStore()
		return coordinator
	}()
	
	/// The primary managed object context. Note the inclusion of the parent context, which takes disk operations off
	/// the main thread.
	public lazy var mainContext: NSManagedObjectContext = { [unowned self] in
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
				DispatchQueue.main.async {
					completion()
				}
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
	/// - returns: The path to the Documents directory of a given device. This is where the sqlite file will be saved, and is a
	/// useful value for debugging purposes.
	static var applicationDocumentsDirectory: URL = {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls[urls.count - 1]
		}()
	
	/// - returns: The path to the sqlite file that stores the application's data.
	static var persistentStoreURL: URL = {
		return applicationDocumentsDirectory.appendingPathComponent("Model.sqlite")
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
	public func resetPersistentStore() {
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
				debugPrint("Failure to remove persistent store")
			}
		}
		do {
			let options = [NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true), NSInferMappingModelAutomaticallyOption: NSNumber(value: true)]
			try addPersistentStore(
				ofType: NSSQLiteStoreType,
				configurationName: nil,
				at: PersistentStackCoordinator.persistentStoreURL as URL,
				options: options)
		} catch {
			var dict = [String: Any]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
			dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
			dict[NSUnderlyingErrorKey] = error as NSError
			let error = NSError(domain: DandyErrorDomain, code: 9999, userInfo: dict)
			debugPrint("Failure to add persistent store  ‼️ ERROR: \(error.description)")
			do {
				try FileManager.default.removeItem(at: PersistentStackCoordinator.persistentStoreURL)
			} catch {
				debugPrint("Failure to remove cached sqlite file")
			}
			EntityMapper.clearCache()
			#if !TEST
				abort()
			#endif
		}
	}
}
