//
//  Plebian+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Plebian {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Plebian> {
        return NSFetchRequest<Plebian>(entityName: "Plebian");
    }

    @NSManaged public var name: String?

}
