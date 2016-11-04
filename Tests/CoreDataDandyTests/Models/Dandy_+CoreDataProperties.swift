//
//  Dandy_+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Dandy_ {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dandy_> {
        return NSFetchRequest<Dandy_>(entityName: "Dandy_");
    }

    @NSManaged public var bio: String?
    @NSManaged public var dandyID: String?
    @NSManaged public var dateOfBirth: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var gossip: NSSet?
    @NSManaged public var hats: NSSet?
    @NSManaged public var predecessor: Dandy_?
    @NSManaged public var successor: Dandy_?

}

// MARK: Generated accessors for gossip
extension Dandy_ {

    @objc(addGossipObject:)
    @NSManaged public func addToGossip(_ value: Gossip)

    @objc(removeGossipObject:)
    @NSManaged public func removeFromGossip(_ value: Gossip)

    @objc(addGossip:)
    @NSManaged public func addToGossip(_ values: NSSet)

    @objc(removeGossip:)
    @NSManaged public func removeFromGossip(_ values: NSSet)

}

// MARK: Generated accessors for hats
extension Dandy_ {

    @objc(addHatsObject:)
    @NSManaged public func addToHats(_ value: Hat)

    @objc(removeHatsObject:)
    @NSManaged public func removeFromHats(_ value: Hat)

    @objc(addHats:)
    @NSManaged public func addToHats(_ values: NSSet)

    @objc(removeHats:)
    @NSManaged public func removeFromHats(_ values: NSSet)

}
