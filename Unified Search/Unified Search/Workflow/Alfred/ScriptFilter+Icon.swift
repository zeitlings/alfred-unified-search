//
//  ScriptFilter+Icon.swift
//  GPT Nexus
//
//  Created by Patrick Sy on 13/06/2024.
//

import Foundation

struct Icon: Codable, Equatable, ExpressibleByStringLiteral {
	enum IconType: String, Codable {
		case fileicon, filetype
	}
	var type: IconType?
	var path: String
	
	init(path: String, type: IconType? = nil) {
		self.path = path
		self.type = type
	}
	
	init(stringLiteral value: String) {
		self = Icon(path: value)
	}
}

extension Icon {
	static let config: Icon = "images/icons/workflow.config.png"
	static let configDir: Icon = "images/icons/workflow.config.dir.png"
	static let info: Icon = "images/icons/info.png"
	static let failure: Icon = "images/icons/failure.png"
}

