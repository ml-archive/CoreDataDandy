//
//  Dandy_+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 4/11/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Dandy_ {

    @NSManaged var bio: String?
    @NSManaged var dandyID: String?
    @NSManaged var dateOfBirth: NSDate?
    @NSManaged var name: String?
    @NSManaged var gossip: NSSet?
    @NSManaged var hats: NSSet?
    @NSManaged var predecessor: Dandy_?
    @NSManaged var successor: Dandy_?

}
