//
//  Space+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Space {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Space> {
        return NSFetchRequest<Space>(entityName: "Space");
    }

    @NSManaged public var name: String?
    @NSManaged public var spaceState: String?

}
