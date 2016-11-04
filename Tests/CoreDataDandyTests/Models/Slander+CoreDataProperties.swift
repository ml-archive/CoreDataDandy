//
//  Slander+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Slander {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Slander> {
        return NSFetchRequest<Slander>(entityName: "Slander");
    }

    @NSManaged public var statement: String?

}
