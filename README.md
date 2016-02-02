![header](header.png)

## Introduction
Core Data Dandy is a feature-light wrapper around Core Data that simplifies common database operations.

## Feature summary

* Initializes and maintains a Core Data stack.
* Provides convenience methods for saves, inserts, fetches, and deletes.
* Maps json into NSManagedObjects via a lightweight API.
* Deserializes NSManagedObjects into json


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

CoreDataDandy supports four xcdatamodel decorations. All decorations are declared and documented in DandyConstants.

**@primaryKey**

Add this decoration to the entity's userInfo to specify which attribute on the entity functions as its primaryKey.

**@mapping**

Add this decoration to an attribute or relationship to specify an alternate mapping for this property. For instance, if a property is named "abbreviatedState," but the json value for this property is found at the key "state," add @mapping : state to the abbreviatedState's userInfo.

**@NO**

Use this decoration in conjunction with the @mapping keyword to disable mapping to the property. For instance, if your entity has an attribute named "secret" that you'd prefer to map yourself, add @mapping : @NO to secret's userInfo.

**@singleton**

Add this decoration to an entity's userInfo if there should never be more than one instance of this entity in your database. This attribute may be useful for objects like Tokens and CurrentUsers, though it's primarily included to suggest the kind of simple yet powerful decorations that may be added in the future.

## Warnings

To receive warnings, add the entry -D DEBUG in your project's build settings under Swift Compiler - Custom Flags.

## Current issues

You may review a list of issues currently reported against Dandy [here](https://jira.fuzzhq.com/issues/?filter=-1&jql=resolution%20%3D%20Unresolved%20AND%20project%20%3D%20%22iOS%20Module%20Library%22%20AND%20component%20%3D%20%22Core%20Data%20Dandy%22%20ORDER%20BY%20updatedDate%20DESC).

## Reporting issues

If you encounter an issue or would like to make a feature request, please alert noah@fuzzproductions.com by creating a ticket and assigning it to him. 

If you're reporting a bug, please provide enough information to reproduce the bug. A regression test will be written against your report before the ticket is resolved, and as such, it's essential that we understand the basic conditions of the test case.

**Required fields**

* Project: iOS Module Library (IML)
* Issue Type: specify the nature of the issue
* Summary: a brief description of the issue
* Components: Core Data Dandy

