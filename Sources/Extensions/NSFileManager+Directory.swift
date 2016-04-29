//
//  NSFileManager+Directory.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 4/28/16.
//
//

import Foundation


extension NSFileManager {
	/// The url of the NSFileManager's `.DocumentDirectory`
	static var documentDirectoryURL: NSURL {
		let urls = defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		
		if let url = urls.last {
			return url
		}
		
		preconditionFailure("Failed to find or a Documents directory.")
	}
	
	/// Returns whether a directory exists at a given file url.
	///
	/// - parameter url: The file url of the directory. For instance "file://root/dandy/documents"
	///
	/// - returns: Whether a directory exists at the given url. Note that false may indicate either that
	/// a file exists at this url or that nothing exists at this directory.
	static func directoryExists(at url: NSURL) -> Bool {
		let path = url.pathComponents?.joinWithSeparator("/") ?? ""
		
		var isDirectory = ObjCBool(false)
		defaultManager().fileExistsAtPath(path, isDirectory:&isDirectory)
		
		return Bool(isDirectory)
	}
	
	/// Creates a directory at a given URL.
	///
	/// - parameter url: The file url of the directory to create.
	///
	/// - throws: A number of errors may lead to an exception here. The two most common exceptions are raised
	/// when a directory already exists at this url or in response to insufficient user permissions.
	static func createDirectory(at url: NSURL) throws {
		try defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: false, attributes: nil)
	}
}