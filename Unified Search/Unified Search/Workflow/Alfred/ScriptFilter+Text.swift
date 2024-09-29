//
//  ScriptFilter+Text.swift
//  GPT Nexus
//
//  Created by Patrick Sy on 13/06/2024.
//

import Foundation

struct Text: Codable, Equatable {
	var copy: String?
	var largetype: String?

	init(copy: String? = nil, largetype: String? = nil) {
		self.copy = copy
		self.largetype = largetype
	}
}
