//
//  Hat+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 4/4/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Hat {

    @NSManaged var name: String?
    @NSManaged var styleDescription: String?
    @NSManaged var dandies: NSOrderedSet?
    @NSManaged var primaryMaterial: NSManagedObject?

}
