//
//  ObjectFactory.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 7/4/15.
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

public struct ObjectFactory {
	/// Returns an object of a given entity type from json. This function is primarily accessed within Dandy to
	/// recursively produce objects when parsing nested json, and is thereby only accessed indirectly. Others, however,
	/// may find direct access to this convenience useful.
	/// 
	/// By default, this function will recursively parse through a json hierarchy.
	/// 	
	/// Note that this method enforces the specification of a primaryKey for the given entity.
	///
	/// Finally, as invocations of this function implicitly involve database fetches, it may bottleneck when used to
	/// process json with thousands of objects.
	/// 
	/// - parameter entity:	The entity that will be inserted or fetched then read to from the json.
	/// - parameter json: The json to map into the returned object.
	/// 
	/// - returns: An NSManagedObject if one could be inserted or fetched. The values that could be mapped from the json
	///		to the object will be found on the returned object.
	public static func objectFromEntity(entity: NSEntityDescription, json: [String: AnyObject]) -> NSManagedObject? {
		// Find primary key
		if	let name = entity.name,
			let primaryKeyValue = entity.primaryKeyValueFromJSON(json) {
			// Attempt to fetch or create unique object for primaryKey
			let object = Dandy.uniqueManagedObjectForEntity(name, primaryKeyValue: primaryKeyValue)
			if var object = object {
				object = buildObject(object, fromJSON: json)
				attemptFinalizationOfObject(object, fromJSON: json)
			} else {
				emitWarningWithMessage("A unique object could not be generated for entity \(entity.name) from json \n\(json).")
			}
			return object
		}
		emitWarningWithMessage("A unique object could not be generated for entity \(entity.name) from json \n\(json).")
		return nil
	}
	/// Transcribes attributes and relationships from json to a given object. Use this function to perform bulk upates
	/// on an object from json.
	///
	/// - parameter object: The `NSManagedObject` to configure.
	/// - parameter json: The json to map into the returned object.
	///
	/// - returns: The object passed in with newly mapped values where mapping was possible.
	public static func buildObject(object: NSManagedObject, fromJSON json: [String: AnyObject]) -> NSManagedObject {
		if let map = EntityMapper.mapForEntity(object.entity) {
			// Begin mapping values from json to object properties
			for (key, description) in map {
				if let value: AnyObject = _valueForKeyPath(key, dictionary: json) {
					// A valid mapping was found for an attribute of a known type
					if description.type == .Attribute,
						let type = description.attributeType {
							object.setValue(CoreDataValueConverter.convertValue(value, toType: type), forKey: description.name)
					}
						// A valid mapping was found for a relationship of a known type
					else if description.type == .Relationship {
						buildRelationship(description, fromJSON: value, forObject: object)
					}
				}
			}
		}
		return object
	}
	/// Builds a relationship to a passed in object from json.
	/// Note that the json type must match the relationship type. For instance, passing a json array to build a toOne
	/// relationship is invalid, just as passing a single json object to build a toMany relationship is invalid.
	///
	/// - parameter object:	The parent object or "owner" of the relationship. If relationship objects are built, they will
	/// 	be assigned to this object relationship.
	/// - parameter relationshipDescription: An object specifying the details of the relationship, including its name, whether it is
	/// 	toMany, and whether it is ordered.
	/// - parameter json: The json with which to build the related objects.
	///
	/// - returns: The object passed in with a newly mapped relationship if relationship objects were built.
	static func buildRelationship(relationship: PropertyDescription, fromJSON json: AnyObject, forObject object: NSManagedObject) -> NSManagedObject {
		if let relatedEntity = relationship.destinationEntity {
			// A dictionary was passed for a toOne relationship
			if let json = json as? [String: AnyObject] where !relationship.toMany  {
				if let relation = objectFromEntity(relatedEntity, json: json) {
					object.setValue(relation, forKey: relationship.name)
				} else {
					emitWarningWithMessage("A relationship named \(relationship.name) could not be established for object \(object) from json \n\(json).")
				}
				return object
			}
			// An array was passed for a toMany relationship
			else if let json = json as? [[String: AnyObject]] where relationship.toMany  {
				var relations = [NSManagedObject]()
				for child in json {
					if let relation = objectFromEntity(relatedEntity, json: child) {
						relations.append(relation)
					} else {
						emitWarningWithMessage("A relationship named \(relationship.name) could not be established for object \(object) from json \n\(child).")
					}
				}
				object.setValue(relationship.ordered ? NSOrderedSet(array: relations): NSSet(array: relations), forKey: relationship.name)
				return object
			}
		}
		emitWarningWithMessage("A relationship named \(relationship.name) could not be established for object \(object) from json \n\(json).")
		return object
	}
	/// Allows for adopters of `MappingFinalizer` to perform custom mapping after the ObjectFactory has completed its 
	/// work.
	///
	/// - parameter object:	The newly created object and the potential adopter of `MappingFinalizer`.
	/// - parameter fromJSON: The json that was used to create the object. Note that this json will include all nested 
	///		"child" relationships, but no "parent" relationships.
	private static func attemptFinalizationOfObject(object: NSManagedObject, fromJSON json: [String: AnyObject]) {
		if let object = object as? MappingFinalizer {
			object.finalizeMappingForJSON(json)
		}
	}
}