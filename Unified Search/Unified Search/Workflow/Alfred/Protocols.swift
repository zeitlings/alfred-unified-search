//
//  Protocols.swift
//  GPT Nexus
//
//  Created by Patrick Sy on 16/06/2024.
//

protocol Inflatable {
	init()
}

extension Inflatable {
	static func with(_ populator: (inout Self) throws -> ()) rethrows -> Self {
		var response = Self()
		try populator(&response)
		return response
	}
}
