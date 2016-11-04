//
//  Gossip+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Gossip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Gossip> {
        return NSFetchRequest<Gossip>(entityName: "Gossip");
    }

    @NSManaged public var details: String?
    @NSManaged public var secret: String?
    @NSManaged public var topic: String?
    @NSManaged public var purveyor: Dandy_?

}
