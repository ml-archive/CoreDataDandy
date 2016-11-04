//
//  Hat+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Hat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Hat> {
        return NSFetchRequest<Hat>(entityName: "Hat");
    }

    @NSManaged public var name: String?
    @NSManaged public var styleDescription: String?
    @NSManaged public var dandies: NSOrderedSet?
    @NSManaged public var primaryMaterial: Material?

}

// MARK: Generated accessors for dandies
extension Hat {

    @objc(insertObject:inDandiesAtIndex:)
    @NSManaged public func insertIntoDandies(_ value: Dandy_, at idx: Int)

    @objc(removeObjectFromDandiesAtIndex:)
    @NSManaged public func removeFromDandies(at idx: Int)

    @objc(insertDandies:atIndexes:)
    @NSManaged public func insertIntoDandies(_ values: [Dandy_], at indexes: NSIndexSet)

    @objc(removeDandiesAtIndexes:)
    @NSManaged public func removeFromDandies(at indexes: NSIndexSet)

    @objc(replaceObjectInDandiesAtIndex:withObject:)
    @NSManaged public func replaceDandies(at idx: Int, with value: Dandy_)

    @objc(replaceDandiesAtIndexes:withDandies:)
    @NSManaged public func replaceDandies(at indexes: NSIndexSet, with values: [Dandy_])

    @objc(addDandiesObject:)
    @NSManaged public func addToDandies(_ value: Dandy_)

    @objc(removeDandiesObject:)
    @NSManaged public func removeFromDandies(_ value: Dandy_)

    @objc(addDandies:)
    @NSManaged public func addToDandies(_ values: NSOrderedSet)

    @objc(removeDandies:)
    @NSManaged public func removeFromDandies(_ values: NSOrderedSet)

}
