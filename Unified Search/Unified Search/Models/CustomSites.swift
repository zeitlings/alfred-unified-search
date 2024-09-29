//
//  CustomSites.swift
//  suffix web search
//
//  Created by Patrick Sy on 27/09/2024.
//

import Foundation

struct CustomSites: Codable {
	let customSites: [String: CustomSite]
}

// Struct for each site entry
struct CustomSite: Codable {
	let enabled: Bool
	let keyword: String
	let text: String
	let url: String
}
