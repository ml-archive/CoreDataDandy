//
//  Space+CoreDataProperties.swift
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

extension Space {

    @NSManaged var name: String?
    @NSManaged var spaceState: String?

}
