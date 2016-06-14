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
	
	/// Returns an object of a given type constructed from the provided json. This function is primarily accessed
	/// within Dandy to recursively produce objects when parsing nested json, and is thereby only accessed indirectly.
	/// Others, however, may find direct access to this convenience useful.
	///
	/// By default, this function will recursively parse through a json hierarchy.
	///
	/// Note that this method enforces the specification of a primaryKey for the given entity.
	///
	/// Finally, as invocations of this function implicitly involve database fetches, it may bottleneck when used to
	/// process json with thousands of objects.
	///
	/// - parameter type: The type of object to make.
	/// - parameter from: The json to map into the returned object.
	///
	/// - returns: A Model of the specified type if one could be inserted or fetched. The values that could be mapped
	/// from the json to the object will be found on the returned object.
	public static func make<Model: NSManagedObject>(type: Model.Type, from json: [String: AnyObject]) -> Model? {
		if let entityDescription = NSEntityDescription.forType(type) {
			return _make(entityDescription, from: json) as? Model
		}
		log(format("An entityDescription was not found for type \(type) from json \n\(json)."))
		return nil
	}
	
	/// An internal function that achieves `make(type:_, from:_)` and conceals Core Data's stringiness.
	///
	/// Ultimately, this method exists because there's no way of converting strings to fully qualified types. As
	/// relationships in Core Data are described with strings, this is my current workaround.
	///
	/// - parameter entity:	The entity that will be inserted or fetched then read to from the json.
	/// - parameter from: The json to map into the returned object.
	///
	/// - returns: An NSManagedObject if one could be inserted or fetched. The values that could be mapped from the json
	///		to the object will be found on the returned object.
	static func _make(entity: NSEntityDescription, from json: [String: AnyObject]) -> NSManagedObject? {
		guard let name = entity.name else {
			log(format("An object cannot be made from nameless entities."))
			return nil
		}
		
		var object: NSManagedObject? = nil
		
		if entity.isUnique {
			// Attempt to fetch or create unique object for primaryKey
			if let primaryKeyValue = entity.primaryKeyValueFromJSON(json) {
				object = Dandy._insertUnique(name, identifiedBy: primaryKeyValue)
			}
		} else {
			// The object is not unique. Simply insert it.
			object = Dandy._insert(name)
		}
		
		if let object = object {
			build(object, from: json)
			finalizeMapping(of: object, from: json)
			
			return object
		}
		
		log(format("An object could not be made for entity \(entity.name) from json \n\(json)."))
		return nil
	}
	
	/// Transcribes attributes and relationships from json to a given object. Use this function to perform bulk upates
	/// on an object from json.
	///
	/// - parameter object: The `NSManagedObject` to configure.
	/// - parameter json: The json to map into the returned object.
	///
	/// - returns: The object passed in with newly mapped values where mapping was possible.
	public static func build<Model: NSManagedObject>(object: Model, from json: [String: AnyObject]) -> Model {
		if let map = EntityMapper.map(object.entity) {
			// Begin mapping values from json to object properties
			for (key, description) in map {
				if let value: Any = valueAt(key, of: json) {
					if value is NSNull {
						// The key appeared in the json, but its value was nil. Assume the nil is meaningful.
						object.nilIfOptional(description)
					} else if description.type == .Attribute,
						let type = description.attributeType {
						// A valid mapping was found for an attribute of a known type
						(object as NSManagedObject).setValue(CoreDataValueConverter.convert(value, to: type), forKey: description.name)
					} else if description.type == .Relationship {
						// A valid mapping was found for a relationship of a known type
						make(description, to: object, from: value)
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
	/// - parameter relationship: An object specifying the details of the relationship, including its name, whether it is
	/// 	toMany, and whether it is ordered.
	/// - parameter object:	The parent object or "owner" of the relationship. If relationship objects are built, they will
	/// 	be assigned to this object relationship.
	/// - parameter json: The json with which to build the related objects.
	///
	/// - returns: The object passed in with a newly mapped relationship if relationship objects were built.
	static func make(relationship: PropertyDescription, to object: NSManagedObject, from json: Any) -> NSManagedObject {
		guard let relatedEntity = relationship.destinationEntity else {
			log(format("The entity named \(relationship.name) for entity \(object.entity.name) lacks an NSEntityDescription. No relationthip will be built."))
			return object
		}
		
		if let json = json as? [String: Any?] where !relationship.toMany {
			// A dictionary was passed for a toOne relationship
			if let relation = _make(relatedEntity, from: json) {
				object.setValue(relation, forKey: relationship.name)
			} else {
				// No relationship could be made from the json. Nil out the relationship.
				log(format("A relationship named \(relationship.name) could not be made for \(object) from json \n\(json).\n\(relationship.name) will be nilled out if it is an optional relationship."))
				
				object.nilIfOptional(relationship)
			}
			
			return object
		} else if let json = json as? [[String: Any?]] where relationship.toMany {
			// An array was passed for a toMany relationship
			var relations = [NSManagedObject]()
			for child in json {
				if let relation = _make(relatedEntity, from: child) {
					relations.append(relation)
				} else {
					log(format("A relationship named \(relationship.name) could not be established for object \(object) from json \n\(child)."))
				}
			}
			
			object.setValue(relationship.ordered ? NSOrderedSet(array: relations)
												 : NSSet(array: relations),
			                forKey: relationship.name)
			
			return object
		} else {
			// The value provided did not match the expected type. For instance, an array was passed where an object
			// was expected.
			log(format("A relationship named \(relationship.name) could not be established for object \n\(object) from json \n\(json)."
				+ {
					if relationship.toMany {
						return " An array is expected to create toMany relationships."
					} else {
						return " An object is expected to create toOne relationships."
					}
				}()
				+ "\n\(relationship.name) will be nilled out if it is an optional relationship."))
			
			object.nilIfOptional(relationship)
		}
		
		return object
	}
	
	/// Allows for adopters of `MappingFinalizer` to perform custom mapping after the ObjectFactory has completed its
	/// work.
	///
	/// - parameter object:	The newly created object and the potential adopter of `MappingFinalizer`.
	/// - parameter from: The json that was used to create the object. Note that this json will include all nested
	///		"child" relationships, but no "parent" relationships.
	private static func finalizeMapping(of object: NSManagedObject, from json: [String: Any?]) {
		if let object = object as? MappingFinalizer {
			object.finalizeMapping(of: json)
		}
	}
}

// MARK: - NSManagedObject+Nil -
private extension NSManagedObject {
	/// If a property is optional, set it to nil.
	///
	/// - parameter property: The relationship to nil if optional.
	private func nilIfOptional(property: PropertyDescription) {
		if property.optional {
			setValue(nil, forKey: property.name)
		}
	}
}