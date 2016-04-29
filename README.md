![header](header.png)

[![Build Status](https://travis-ci.org/fuzz-productions/CoreDataDandy.svg?branch=master)](https://travis-ci.org/fuzz-productions/CoreDataDandy)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/fuzz-productions/CoreDataDandy)
[![CocoaPods Compatible](https://img.shields.io/badge/pod-0.5.1-blue.svg)](https://cocoapods.org/pods/CoreDataDandy)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/fuzz-productions/CoreDataDandy/blob/master/LICENSE) 

## Introduction
Core Data Dandy is a feature-light wrapper around Core Data that simplifies common database operations.

## Feature summary

* Initializes and maintains a Core Data stack.
* Provides convenience methods for saves, inserts, fetches, and deletes.
* Maps json into NSManagedObjects via a lightweight API.
* Deserializes NSManagedObjects into json

## Installation

### SPM

```
dependencies: [
 .Package(url: "https://github.com/fuzz-productions/CoreDataDandy.git", 
 		  versions: Version(0,5,1)..<Version(0,5,2))
]
```

### Carthage

```
github "fuzz-productions/CoreDataDandy" ~> 0.5.1
```

### CocoaPods

```
pod 'CoreDataDandy', '0.5.1'
```

## Usage

All standard usage of Core Data Dandy should flow through CoreDataDandy's sharedDandy. More advanced users, however, may find its various components useful in isolation.

### Bootstrapping 
```swift
CoreDataDandy.wake("ModelName")
```

### Saving and deleting

Save with or without a closure.

```swift
Dandy.save()
Dandy.save { (error: NSError) in
	// Respond to save completion.
}
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
Dandy.fetch(Gossip.self)
```

Fetch an object corresponding to an entity and primaryKey value.

```swift
Dandy.fetchUnique(Hat.self, identifiedBy: "bowler")
```

Fetch an array of objects filtered by a predicate.

```swift
Dandy.fetch(Gossip.self, filterBy: NSPredicate(format: "topic == %@", "John Keats"))
```

### Insertions and updates

Insert object of a given type.

```swift
Dandy.insert(Gossip.self)
```

Insert or fetch a unique a object from a primary key.

```swift
Dandy.insertUnique(Slander.self, identifiedBy: "WILDE")
```

Upsert a unique object, or insert and update a non-unique object.

```swift
Dandy.upsert(Gossip.self, from: json)
```

Upsert an array of unique objects, or insert and update non-unique objects.

```swift
Dandy.batchUpsert(Gossip.self, from: json)
```

### Mapping finalization

Objects requiring custom mapping finalization should adopt the `MappingFinalizer` protocol. The protocol has a single function, `finalizeMapping(_:)`.

```swift
extension Conclusion: MappingFinalizer {
	func finalizeMapping(of json: [String : AnyObject]) {
		if var content = content {
			content += "_FINALIZED"
			self.content = content
		}
	}
}
```

### Serialization

Serialize a single object.

```swift
Serializer.serialize(gossip)
```

Serialize an array of objects.

```swift
Serializer.serialize([byron, wilde, andre3000])
```

Serialize an object and its relationships.

```swift
Serializer.serialize(gossip, including: ["purveyor"])
```

Serialize an object and its nested relationships.

```swift
Serializer.serialize(gossip, including: ["purveyor.hats.material, purveyor.predecessor"])
```

## xcdatamodel decorations

CoreDataDandy supports four xcdatamodel attributes. All decorations are declared and documented in DandyConstants.

**@primaryKey**

Add this decoration to the entity's userInfo to specify which property on the entity functions as its primaryKey. For iOS 9 and later, use uniqueConstraints instead.

**@mapping**

Add this decoration to a property to specify an alternate mapping for this property. For instance, if a property is named "abbreviatedState," but the json value for this property is found at the key "state," add @mapping : state to the abbreviatedState's userInfo.

**@NO**

Use this decoration in conjunction with the @mapping keyword to disable mapping to the property. For instance, if your entity has an attribute named "secret" that you'd prefer to map yourself, add @mapping : @NO to secret's userInfo.

**@singleton**

Add this decoration to an entity's userInfo if there should never be more than one instance of this entity in your database. This decoration may be useful for objects like Tokens and CurrentUsers, though it's primarily included to suggest the kind of decorations that may be added in the future.

## Warnings

To receive console warnings in Swift projects, add the entry -D DEBUG in your project's build settings under Swift Compiler - Custom Flags.

