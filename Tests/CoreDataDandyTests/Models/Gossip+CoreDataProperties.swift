//
//  Gossip+CoreDataProperties.swift
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

extension Gossip {

    @NSManaged var details: String?
    @NSManaged var secret: String?
    @NSManaged var topic: String?
    @NSManaged var purveyor: Dandy_?

}
