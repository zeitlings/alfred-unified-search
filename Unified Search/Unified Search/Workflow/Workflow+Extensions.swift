//
//  Workflow+Extensions.swift
//  suffix web search
//
//  Created by Patrick Sy on 22/09/2024.
//

import Foundation


// MARK: Environment extensions

extension Workflow {
	
	enum FilterBehaviour: String {
		case always, onTab
	}
	static let filterBehaviour: FilterBehaviour = .init(rawValue: envvar("filter_behaviour") ?? "") ?? .always
	static let onlyShowMatches: Bool = envvar("only_matches") == "1"
	static let includeCustomAlfredWebsearches: Bool = envvar("include_custom_alfred_websearches") == "1"
	
}
