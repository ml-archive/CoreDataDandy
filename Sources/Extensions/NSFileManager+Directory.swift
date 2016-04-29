//
//  NSFileManager+Directory.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 4/28/16.
//
//

import Foundation


extension NSFileManager {
	static var documentDirectoryURL: NSURL {
		let urls = defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		
		if let url = urls.last {
			return url
		}
		
		preconditionFailure("Failed to find or a Documents directory.")
	}
	
	static func directoryExists(at url: NSURL) -> Bool {
		let path = url.absoluteString.stringByReplacingOccurrencesOfString("file://", withString: "")
		
		var isDirectory = ObjCBool(false)
		defaultManager().fileExistsAtPath(path, isDirectory:&isDirectory)
		
		return Bool(isDirectory)
	}
	
	static func createDirectory(at url: NSURL) throws {
		try defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: false, attributes: nil)
	}
}