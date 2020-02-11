//
//  EntityMapper.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 6/21/15.
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

struct EntityMapper {
	// MARK: - Entity Mapping -
	/// The primary function of this class. Creates, caches, and returns mappings that are subsequently
	/// used to read json into an instance of an entity.
	///
	/// - parameter entity: The `NSEntityDescription` to map
	///
	/// - returns: A mapping used to read json into the specified entity.
	static func map(entity: NSEntityDescription) -> [String: PropertyDescription]? {
		// Search for a cached entity map
		if let entityName = entity.name {
			// A mapping has already been created for this entity. Return it.
			if let map = cachedEntityMap[entityName] {
				return map
			} else {
				// A mapping has not been created for this entity. Create it, cache it, and return it.
				var map = [String: PropertyDescription]()
				
				// Map attributes
				if let attributes = entity.allAttributes {
					add(dictionary: attributes, to: &map)
				}
				
				// Map relationships
				if let relationships = entity.allRelationships {
					add(dictionary: relationships, to: &map)
				}
				archive(map: map, forEntity:entityName)
				return map
			}
		} else {
			debugPrint("Entity Name is nil for Entity " + entity.description + ". No mapping will be returned")
		}
		return nil
	}
	
	/// A convenience function for producing mapped values of an entity's attributes relationships.
	///
	/// - parameter dictionary: A dictionary containing either NSAttributeDescriptions or NSRelationshipDescriptions
	/// - parameter map: The map for reading json into an entity
	private static func add(dictionary: [String: AnyObject], to map: inout [String: PropertyDescription]) {
		for (name, description) in dictionary {
			// TODO: Check this
			let userInfo = description.userInfo as [NSObject : AnyObject]?
			if let newMapping = mappingForUserInfo(userInfo: userInfo) {
				// Do not add values specified as non-mapping to the mapping dictionary
				if newMapping != NO_MAPPING {
					map[newMapping] = PropertyDescription(description: description)
				}
			}
			else {
				map[name] = PropertyDescription(description: description)
			}
		}
	}
	
	/// Returns any mapping values found in a userInfo dictionary.
	///
	/// - parameter userInfo: The userInfo of an `NSEntityDescription`, `NSAttributeDescription`, or `NSRelationshipDescription`
	///
	/// - returns: A mapping value if one was found. Otherwise, nil.
	static func mappingForUserInfo(userInfo: [NSObject: AnyObject]?) -> String? {
		if	let userInfo = userInfo as? [String: String],
			let mapping = userInfo[MAPPING] {
			return mapping
		}
		return nil
	}
}

// MARK: - EntityMapper+Caching -
extension EntityMapper {
	/// A lazy, nillable reference to a cached map.
	private static var _cachedEntityMap: [String: [String: PropertyDescription]]?
	/// A dictionary containing mappings in the following structure: ['entityName': 'map'].
	static var cachedEntityMap: [String: [String: PropertyDescription]] {
		get {
			if _cachedEntityMap == nil {
				if let archivedMap = NSKeyedUnarchiver.unarchiveObject(withFile: self.entityMapFilePath) as? [String: [String: PropertyDescription]] {
					_cachedEntityMap = archivedMap
				} else {
					_cachedEntityMap = [String: [String: PropertyDescription]]()
				}
			}
			return _cachedEntityMap!
		}
		
		set {
			_cachedEntityMap = newValue
		}
	}
	
	/// - returns: The file path where the entityMap is archived.
	private static var entityMapFilePath: String = {
		let path = NSString(string:PersistentStackCoordinator.applicationDocumentsDirectory.relativePath)
		return path.appendingPathComponent(CACHED_MAPPING_LOCATION)
	}()
	
	/// Archives an entity's mapping. Note, this mapping, will be saved to the `cachedEntityMap` at the key
	/// of the forEntity parameter.
	///
	/// - parameter map: A mapping for reading json into an entity.
	/// - parameter forEntity: The name of the entity `map` corresponds to.
	private static func archive(map: [String: PropertyDescription], forEntity entity: String) {
		cachedEntityMap[entity] = map;
		NSKeyedArchiver.archiveRootObject(cachedEntityMap, toFile: entityMapFilePath)
	}
	
	/// Clears cached mappings.
	///
	/// This method should be invoked when the database is undergoing a migration or any other time
	/// where the cached entity mappings may be invalidated..
	static func clearCache() {
		_cachedEntityMap = nil
		if FileManager.default.fileExists(atPath: entityMapFilePath) {
			do {
				try FileManager.default.removeItem(atPath: entityMapFilePath)
			} catch {
				debugPrint("Failure to remove entity map from cache")
			}
		}
	}
}
