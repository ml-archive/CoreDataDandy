//
//  Conclusion+CoreDataProperties.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 11/10/16.
//
//

import Foundation
import CoreData


extension Conclusion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conclusion> {
        return NSFetchRequest<Conclusion>(entityName: "Conclusion");
    }

    @NSManaged public var content: String?
    @NSManaged public var id: String?

}
