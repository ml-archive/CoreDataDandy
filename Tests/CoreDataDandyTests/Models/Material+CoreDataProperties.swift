//
//  Material+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Material {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Material> {
        return NSFetchRequest<Material>(entityName: "Material");
    }

    @NSManaged public var name: String?
    @NSManaged public var origin: String?
    @NSManaged public var hats: Hat?

}
