//
//  NSManagedObject+Dandy.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 10/31/16.
//
//

import CoreData

extension NSManagedObject {
	public class func entityDescription() -> NSEntityDescription? {
		return NSEntityDescription.entity(forEntityName: String(describing: self),
										  in: Dandy.coordinator.mainContext)
	}
	
	public class func inserted() -> NSManagedObject? {
		if #available(iOS 10.0, *) {
			return self.init(context: Dandy.coordinator.mainContext)
		} else {
			if let description = entityDescription() {
				return NSManagedObject(entity: description,
				                       insertInto: Dandy.coordinator.mainContext)
			}
		}
		
		return nil
	}
	
	public class func type(named className: String) -> NSManagedObject.Type? {
		return NSClassFromString(className) as? NSManagedObject.Type
	}
}
