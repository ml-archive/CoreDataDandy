//
//  Flattery+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Flattery {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flattery> {
        return NSFetchRequest<Flattery>(entityName: "Flattery");
    }

    @NSManaged public var ambition: String?

}
