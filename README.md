![header](header.png)

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/fuzz-productions/CoreDataDandy)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/fuzz-productions/CoreDataDandy/blob/master/LICENSE) 

## Introduction
Core Data Dandy is a feature-light wrapper around Core Data that simplifies common database operations.

## Feature summary

* Initializes and maintains a Core Data stack.
* Provides convenience methods for saves, inserts, fetches, and deletes.
* Maps json into NSManagedObjects via a lightweight API.
* Deserializes NSManagedObjects into json

## Installation

### Carthage


```ogdl
github "fuzz-productions/CoreDataDandy" ~> 0.2
```

## Usage

All standard usage of Core Data Dandy should flow through CoreDataDandy's sharedDandy. More advanced users, however, may find its various components useful in isolation.

### Bootstrapping 
```swift
CoreDataDandy.wakeWithMangedObjectModel("ModelName")
```

### Saving and deleting

Save with or without a closure.

```swift
Dandy.save()
Dandy.save({
	// Respond to save completion.
})
```

Delete with or without a closure.

```swift
Dandy.delete(object)
Dandy.delete(object) {
	// Respond to deletion completion.
}
```

Destroy the contents of the database. Called, for example, to recover from a failure to perform a migration.

```swift
Dandy.tearDown()
```

### Fetching

Fetch all objects of a given type.

```swift
Dandy.fetchObjectsForEntity("Dandy")
```

Fetch an object corresponding to an entity and primaryKey value.

```swift
Dandy.fetchUniqueObjectForEntity("Dandy", primaryKeyValue: "BALZAC")
```

Fetch an array of objects filtered by a predicate.

```swift
Dandy.fetchObjectsForEntity("Dandy", predicate: NSPredicate(format: "bio == %@", "A poet, let's say"))
```

### Insertions and updates

Insert object of a given type.

```swift
Dandy.insertManagedObjectForEntity("Gossip")
```

Insert or fetch a unique a object from a primary key.

```swift
CoreDataDandy.sharedDandy.uniqueManagedObjectForEntity("Dandy", primaryKeyValue: "WILDE")
```

Upsert a unique object, or insert and update a non-unique object.

```swift
CoreDataDandy.sharedDandy.managedObjectForEntity("Dandy", json: json)
```

Upsert an array of unique objects, or insert and update non-unique objects.

```swift
CoreDataDandy.sharedDandy.managedObjectsForEntity("Dandy", json: json)
```

### Mapping finalization

Objects requiring custom mapping finalization should adopt the `MappingFinalizer` protocol. The protocol has a single function, `finalizeMappingForJSON(_:)`.

```swift
extension Conclusion: MappingFinalizer {
	func finalizeMappingForJSON(json: [String : AnyObject]) {
		content += "_FINALIZED"
	}
}
```

### Deserialization

Deserialize a single object.

```swift
DandyDeserializer.deserializeObject(gossip)
```

Deserialize an array of objects.

```swift
DandyDeserializer.deserializeObjects([byron, wilde, andre3000])
```

Deserialize an object and its relationships.

```swift
DandyDeserializer.deserializeObject(gossip, includeRelationships: ["purveyor"])
```

Deserialize an object and its nested relationships.

```swift
DandyDeserializer.deserializeObject(gossip, includeRelationships: ["purveyor.hats.material, purveyor.predecessor"])
```

## xcdatamodel decorations

CoreDataDandy supports four xcdatamodel attributes. All decorations are declared and documented in DandyConstants.

**@primaryKey**

Add this decoration to the entity's userInfo to specify which property on the entity functions as its primaryKey.

**@mapping**

Add this decoration to a property to specify an alternate mapping for this property. For instance, if a property is named "abbreviatedState," but the json value for this property is found at the key "state," add @mapping : state to the abbreviatedState's userInfo.

**@NO**

Use this decoration in conjunction with the @mapping keyword to disable mapping to the property. For instance, if your entity has an attribute named "secret" that you'd prefer to map yourself, add @mapping : @NO to secret's userInfo.

**@singleton**

Add this decoration to an entity's userInfo if there should never be more than one instance of this entity in your database. This decoration may be useful for objects like Tokens and CurrentUsers, though it's primarily included to suggest the kind of decorations that may be added in the future.

## Warnings

To receive console warnings in Swift projects, add the entry -D DEBUG in your project's build settings under Swift Compiler - Custom Flags.

