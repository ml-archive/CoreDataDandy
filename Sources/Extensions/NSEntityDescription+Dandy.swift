//
//  NSEntity+Dandy.swift
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

import CoreData

// MARK: - NSEntityDescription+UserInfo -
extension NSEntityDescription {
	/// Recursively collects all userInfo values from potential superentities
	var allUserInfo: [NSObject: AnyObject]? {
		get {
			return collectedEntityValuesFromDictionaryClosure({return $0.userInfo as? JSONObject})
		}
	}

	/// Recursively collects all attribute values from potential superentities
	var allAttributes: [String: NSAttributeDescription]? {
		get {
			return collectedEntityValuesFromDictionaryClosure({return $0.attributesByName}) as? [String: NSAttributeDescription]
		}
	}

	/// Recursively collects all relationship values from potential superentities
	var allRelationships: [String: NSRelationshipDescription]? {
		get {
			return collectedEntityValuesFromDictionaryClosure({return $0.relationshipsByName}) as? [String: NSRelationshipDescription]
		}
	}

	/// Recursively collects arbitrary values from potential superentities. This function contains the boilerplate
	/// required for collecting userInfo, attributesByName, and relationshipsByName.
	///
	/// - parameter dictionaryClosure: A closure returning userInfo, attributesByName, or relationshipsByName.
	///
	/// - returns: The values collected from the entity's hierarchy.
	private func collectedEntityValuesFromDictionaryClosure(dictionaryClosure: (NSEntityDescription) -> JSONObject?) -> JSONObject? {
		var values = JSONObject()
		// Collect values down the entity hierarchy, stopping on the current entity.
		// This approach ensures children override parent values.
		for entity in entityHierarchy {
			if let newValues = dictionaryClosure(entity) {
				values.addEntriesFrom(newValues)
			}
		}
		return values
	}

	/// - returns: The entity's hierarchy, sorted by "superiority". The most super entity will be the first element
	/// in the array, the current entity will be the last.
	private var entityHierarchy: [NSEntityDescription] {
		get {
			var entities = [NSEntityDescription]()
			var entity: NSEntityDescription? = self
			while let currentEntity = entity {
				entities.insert(currentEntity, atIndex: 0)
				entity = entity?.superentity
			}
			return entities
		}
	}
}


// MARK: - NSEntityDescription+Construction -
extension NSEntityDescription {
	class func forEntity(name: String) -> NSEntityDescription? {
		return NSEntityDescription.entityForName(name, inManagedObjectContext: Dandy.coordinator.mainContext)
	}
	
	class func forType<T>(type: T.Type) -> NSEntityDescription? {
		return forEntity(String(type))
	}
}

// MARK: - NSEntityDescription+UniqueConstraint -
@available(iOS 9.0, *) extension NSEntityDescription {
	/// Returns a single unique constraint. Core Data Dandy does not support the use of multiple unique constraints.
	/// The constraint returned is prioritized over any marked by the @primaryKey decorator.
	var uniqueConstraint: String? {
		get {
			if let attribute = uniquenessConstraints.first?.first as? NSAttributeDescription {
				return attribute.name
			} else if let superEntity = superentity {
				return superEntity.uniqueConstraint
			}
			return nil
		}
	}

}

// MARK: - NSEntityDescription+PrimaryKey -
extension NSEntityDescription {
	/// Returns the primary key of of the `NSEntityDescription`, a value used to ensure a unique record
	///	for this entity.
	///
	/// - returns: The property on the entity marked as a unique constraint or as its primaryKey if either is found.
	///	Otherwise, nil.
	var primaryKey: String? {
		get {
			if #available(iOS 9.0, *) {
				if let uniqueConstraint = uniqueConstraint {
					return uniqueConstraint
				}
			}
			if let userInfo = allUserInfo {
				return userInfo[PRIMARY_KEY] as? String
			}
			return nil
		}
	}
	
	/// Returns whether the entity is unique or not.
	///
	/// - returns: If the entity has either one unique constraint or an identified primaryKey attribute, true.
	///	Otherwise, false.
	var isUnique: Bool {
		get {
			return primaryKey != nil
		}
	}

	/// Extracts the value of a primary key from the passed in json if one can be extracted. Takes alternate mappings
	/// for the primaryKey into account.
	///
	/// - parameter json: JSON form which a primaryKey will be extracted
	func primaryKeyValueFromJSON(json: JSONObject) -> AnyObject? {
		if	let primaryKey = primaryKey,
			let entityMap = EntityMapper.map(self) {
				let filteredMap = entityMap.filter({ $1.name == primaryKey }).map({ $0.0 })
				// If the primary key has an alternate mapping, return the value from the alternate mapping.
				// Otherwise, return the json value matching the name of the primary key.
				if let mappedKey = filteredMap.first {
					return json[mappedKey] ?? nil
				}
			
				return json[primaryKey] ?? nil
		}
		return nil
	}

	/// Generates a predicate to fetch for the entity with a given primary key value
	///
	/// - parameter primaryKeyValue: The value of the entity's primary key
	/// - returns: A predicate that may be used to fetch unique objects
	func primaryKeyPredicate(for primaryKeyValue: AnyObject) -> NSPredicate? {
		if	let primaryKey = primaryKey,
			let value: AnyObject = CoreDataValueConverter.convert(primaryKeyValue, for: self, property: primaryKey) {
				return NSPredicate(format: "%K = %@", argumentArray: [primaryKey, value])
		}
		return nil
	}
}
