//
//  main.swift
//  suffix web search
//
//  Created by Patrick Sy on 22/09/2024.
//

import Foundation

let g_FilterSeperator: String = "||"
let g_QuicklookHint: Character = ">"

struct Search {
	
	typealias WebSearch = WebSearches.WebSearch
	
	/// Used for autocomplete where  filter  behaviour is `always` and only defaults are shown
	static let queryFull: String = Workflow.userInput ?? ""
	static var query: String = queryFull
	static let queryHasFilterSeperator: Bool = query.firstRange(of: g_FilterSeperator) != nil
	static var suffixIsExactMatch: Bool = false
	static var suffix: String = ""
	static var injectQuicklook: Bool = false
	static private let fm: FileManager = .default
	
	static func run() {
		guard !query.trimmed.isEmpty else {
			Workflow.info("Please enter text to search for.")
		}
		Self.probe()
		Self.injectQuicklook = getQuicklookHint()
		let suffix: String? = getFilterHint(suffixMode: queryHasFilterSeperator) // last query component
		let suffixIsWildcard: Bool = suffix == "*"
		let webSearches: [WebSearch] = FileHandler.getSearches()
		guard webSearches.first(where: { $0.isDefault }) != nil else {
			Workflow.info("At least one search must be configured as default.")
		}
		if !suffixIsWildcard, let suffix,
		   webSearches.first(where: { $0.matches(suffix: suffix) }) != nil
		{
			Self.suffixIsExactMatch = true
			Self.suffix = suffix
		}
		
		var items: [Item] = []
		let subtitle: String = "Search for '\(query)'"
		if let suffix: String, !suffixIsWildcard {
			let fuzzy: Fuzzy = .init(query: suffix)
			let matches = fuzzy.sorted(candidates: webSearches, matchesOnly: Workflow.onlyShowMatches)
			items = matches.compactMap({ $0.target.alfredItem(query: query) })
			if items.isEmpty {
				items = webSearches.filter(\.isDefault).compactMap({ $0.alfredItem(query: queryFull)} )
				items[0].subtitle = "Search for '\(queryFull)'"
			} else {
				items[0].subtitle = subtitle
			}
		} else {
			items = suffixIsWildcard
				? webSearches.sorted(by: { $0.isDefault && !$1.isDefault }).compactMap({ $0.alfredItem(query: query)} )
				: webSearches.filter(\.isDefault).compactMap({ $0.alfredItem(query: query)} )
			items[0].subtitle = queryHasFilterSeperator
				? subtitle
				: Workflow.filterBehaviour == .always
					? subtitle
					: "[Tap ⇥ to Filter] \(subtitle)"
		}
		
		Workflow.return(Response(items: items))
	}
}

Search.run()
