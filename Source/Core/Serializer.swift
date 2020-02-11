//
//  Serializer.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 7/15/15.
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
/**
	Serializes NSManagedObjects objects to json.
*/
public struct Serializer {
	/// Produces json representing an object and, potentially, members of its relationship tree.
	///
	/// Specify each relationship you wish to include in the serialization by including its name in the relationship 
	/// array. To serialize further into a relationship "tree", use keypaths.
	///
	/// As an example, imagine the following relationship tree:
	///
	/// dandy (relationships to)
	///							-> hats
	///							-> gossip	(relationship to)
	///														->	purveyor
	///
	/// - If no relationships are specified when serializing the dandy object, only its attributes will be serialized 
	/// into json.
	/// - If ["hats", "gossip"] is specified when serializing the dandy object, Dandy's attributes will be serialize
	/// along with its hats and gossipe relationships.
	/// - If ["gossip.purveyor"] is specified when serializing the dandy object, Dandy's attributes, gossip, and 
	/// gossip's purveyor will be serialized into json.
	///
	/// Note: attributes with nil values will not be included in the returned json. However, nil relationships that are 
	/// specified will be included as empty arrays or objects.
	///
	/// - parameter object: An object to serialize into json
	/// - parameter relationships: Relationships and keypaths to nested relationships targeted for serialization.
	///
	/// - returns: A json representation of this object and its relationships if one could be produced. Otherwise, nil.
	public static func serialize(object: NSManagedObject, including relationships: [String]? = nil) -> [String: AnyObject]? {
		guard let map = EntityMapper.map(entity: object.entity) else {
			debugPrint("Failed to serialize object \(object) including relationships \(String(describing: relationships))")
			return nil
		}
		var json = [String: Any]()
		for (property, description) in map {
			switch description.type {
			case .attribute:
				json[property] = object.value(forKey: description.name) as AnyObject?
			default:
				if let relationships = relationships,
					relationships.contains(where: { $0.range(of: description.name) != nil }) {
					if let nestedRelationships = nestedSerializationTargets(for: description.name, including: relationships) {
						serializeNestedRelationships(property, description, object, nestedRelationships, &json)
					} else {
						if let relationship = object.value(forKey: description.name) as? NSManagedObject {
							json[property] = serialize(object: relationship, including: nil) as AnyObject
						} else {
							json[property] = [:] // Assume nils to intend empty objects
						}
					}
				}
			}
		}

		if json.isEmpty {
			debugPrint("Failed to serialize object \(object) including relationships \(String(describing: relationships))")
			return nil
		}

		return json as [String : AnyObject]
	}
	
	static private func serializeNestedRelationships(_ property: String,
													 _ description: PropertyDescription,
													 _ object: NSManagedObject,
													 _ nestedRelationships: [String],
													 _ json: inout [String: Any]) {
		// Map relationships and recurse into nested relationships
		if description.toMany {
			let objects = object.value(forKey: description.name) as AnyObject
			let relatedObjectsUnwrapped = description.ordered ? objects.array: objects.allObjects
			guard let relatedObjects = relatedObjectsUnwrapped as? [NSManagedObject] else { json[property] = [[:]]; return }
			if !relatedObjects.isEmpty {
				json[property] = serialize(objects: relatedObjects, including: nestedRelationships)
			} else {
				json[property] = [[:]]
			}
		} else {
			guard let relationship = object.value(forKey: description.name) as? NSManagedObject else { json[property] = [:]; return }
			json[property] = serialize(object: relationship, including: nestedRelationships) as AnyObject
		}
	}
	
	public static func serialize_(object: NSManagedObject, including relationships: [String]? = nil) -> [String: AnyObject]? {
		var json = [String: Any]()
		let map = EntityMapper.map(entity: object.entity)
		if let map = map {
			for (property, description) in map {
				// Map attributes, ensuring mapping conversion
				if description.type == .attribute {
					json[property] = object.value(forKey: description.name) as AnyObject?
				}
				else if let relationships = relationships,
					let targets = nestedSerializationTargets(for: description.name, including: relationships), (relationships.contains(description.name) || targets.count > 0) {
					let nestedRelationships = nestedSerializationTargets(for: description.name, including: relationships)
					// Map relationships and recurse into nested relationships
					if description.toMany {
						let objects = (object.value(forKey: description.name) as AnyObject)
						let relatedObjects = description.ordered ? objects.array: objects.allObjects
						if let relatedObjects = relatedObjects as? [NSManagedObject] {
							if relatedObjects.count > 0 {
								json[property] = serialize(objects: relatedObjects, including: nestedRelationships)
							}
							else {
								json[property] = [[:]]
							}
						}
						// Assume nils to intend empty objects
						else {
							json[property] = [[:]]
						}
					}
					else {
						if let relationship = object.value(forKey: description.name) as? NSManagedObject {
							json[property] = serialize(object: relationship, including: nestedRelationships) as AnyObject
						}
						// Assume nils to intend empty objects
						else {
							json[property] = [:]
						}
					}
				}
			}
		}
		if json.count == 0 {
			debugPrint("Failed to serialize object \(object) including relationships \(relationships)")
			return nil
		}
		return json as [String : AnyObject]
	}
	/// Recursively invokes other class methods to produce a json array, including relationships.
	///
	/// - parameter objects: An array of `NSManagedObjects` to serialize
	/// - parameter relationships: The relationships targeted for serialization.
	///
	/// - returns: A json representation of the objects and their relationships if one could be produced. Otherwise, nil.
	public static func serialize(objects: [NSManagedObject], including relationships: [String]? = nil) -> [[String: AnyObject]]? {
		var json = [[String: AnyObject]]()
		for object in objects {
			if let relationshipJSON = serialize(object: object, including: relationships) {
				json.append(relationshipJSON)
			}
		}
		return json.count > 0 ? json: nil
	}
	
	/// Determines which relationships to a given relationship require serialization. Relationships to a relationship
	/// are referred to as "nested" relationships. Invoked at every "level" of serialization to recursively convert
	/// keypaths with the name of a top-level relationship into a string which no longer references that relationship.
	///
	/// - parameter relationship: The top-level relationship to query.
	/// - parameter relationships: All serialization targets for the top-level object.
	///
	/// - returns: An array of nested relationships targeted for serialization.
	static func nestedSerializationTargets(for relationship: String, including nestedRelationships: [String]?) -> [String]? {
		if let nestedRelationships = nestedRelationships {
			
			var keypaths: [String] = []
			if nestedRelationships.count > 1 {
				keypaths = nestedRelationships.filter({$0.range(of: relationship) != nil && $0.range(of: ".") != nil })
			} else {
				keypaths = nestedRelationships.filter({$0.range(of: relationship) != nil })
			}

			// Eliminate the relationship name and the period, recursing one level deeper.
			let nestedTargets = keypaths.map({$0.replacingOccurrences(of: relationship + ".", with: "")})
			return nestedTargets.count > 0 ? nestedTargets: nil
		}
		return nil
	}
}
