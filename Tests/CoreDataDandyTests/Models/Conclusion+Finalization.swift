//
//  Conclusion+Finalization.swift
//  CoreDataDandyTests
//
//  Created by Noah Blake on 10/31/16.
//
//

import Foundation

extension Conclusion: MappingFinalizer {
	public func finalizeMapping(of json: JSONObject) {
		if var content = content {
			content += "_FINALIZED"
			self.content = content
		}
	}
}
