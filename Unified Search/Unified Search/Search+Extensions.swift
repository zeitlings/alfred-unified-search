//
//  Search+Extensions.swift
//  suffix web search
//
//  Created by Patrick Sy on 23/09/2024.
//

import Foundation

extension Search {
	
	static func getFilterHint(suffixMode queryHasFilterSeperator: Bool) -> String? {
		let components: [String] = query.split(separator: g_FilterSeperator).map(\.trimmed)
		// If the separator is present, act on it regardless of set behaviour
		let queryHasFilterSuffix: Bool = components.count > 1
		
		if queryHasFilterSeperator {
			Self.query = components[0]
			return queryHasFilterSuffix ? components[1] : nil
		}
		
		switch Workflow.filterBehaviour {
		case .always:
			guard
				let lastComponent: String = query.split(separator: " ").last?.trimmed,
				let lastComponentRange: Range<String.Index> = Self.query.ranges(of: lastComponent).last
			else {
				Workflow.quit("Unexepctedly could not find a filter suffix in query: <\(query)>")
			}
			if lastComponent != Self.query {
				Self.query = Self.query[..<lastComponentRange.lowerBound].trimmed
				return lastComponent
			} else {
				return nil
			}
		case .onTab:
			assert(!queryHasFilterSuffix)
			return nil
		}
	}
}


extension Search {
	
	@discardableResult
	static func probe(fm: FileManager = .default) -> Never? {
		let query = Self.query.trimmed
		guard !query.isEmpty else {
			return nil
		}
		var items: [Item] = []
		switch true {
		case ["help", "?"].contains(query):
						
			items.append(.with({
				$0.title = "Configure Web Search Instances"
				$0.icon = .config
				$0.autocomplete = ":c "
				$0.valid = false
			}))

			items.append(.with({
				$0.title = "Open Workflow Configuration"
				$0.arg = .string("alfredpreferences://navigateto/workflows>workflow>\(Workflow.Env.workflowUID!)>userconfig>key")
				$0.icon = .config
				$0.variables = .triggerOpen
			}))
			
			if let dataPath: String = Workflow.Env.workflowDataDirectory,
			   fm.fileExists(atPath: FileHandler.customizationFile.path(percentEncoded: false))
			{
				items.append(.with({
					$0.title = "Browse Data Folder"
					$0.arg = .string(dataPath)
					$0.icon = .configDir
					$0.variables = .nested(["trigger":.string("browse")])
				}))
			}
			
			Workflow.return(.init(items: items))
			
		case query.hasPrefix(":c"):
			
			let searchFilter: String? = {
				let q: String = query.dropFirst(2).trimmed
				return q.isEmpty ? nil : q
			}()
			
			let searches: [WebSearch] = FileHandler.getSearches()
			
			let items: [Item] = {
				if let searchFilter {
					let fuzzy: Fuzzy = .init(query: searchFilter)
					let matches = fuzzy.sorted(candidates: searches, matchesOnly: true)
					return matches.map({ $0.target.configAlfredItem })
				}
				return searches.map(\.configAlfredItem)
			}()
			
			Workflow.return(.init(items: items))
			
		case query == "|configuring|":
			
			let env: [String: String] = Workflow.Env.environment
			guard env["token"] == "valid" else {
				Workflow.info("Command has been prevented from being triggered")
			}
			guard
				let searchName: String = env["config_search_name"],
				let configAction: String = env["config_action"]
			else {
				Workflow.info("Failure trying to extract search name and config action.")
			}
			
			let searches: [WebSearch] = FileHandler.getSearches()
			guard var search: WebSearch = searches.first(where: { $0.name == searchName }) else {
				Workflow.info("Unable to find web search named: \(searchName)")
			}
			do {
				func finish(customizing search: WebSearch) throws -> Never {
					try FileHandler.saveCustomizedSearch(search)
					Workflow.external(id: "init", argument: ":c \(searchName)")
				}
				switch configAction {
				case "add_default":
					search.isDefault = true
					try finish(customizing: search)
				case "remove_default":
					search.isDefault = false
					try finish(customizing: search)
				case "activate":
					search.active = true
					try finish(customizing: search)
				case "deactivate":
					search.active = false
					try finish(customizing: search)
				default:
					Workflow.info("Unexpected config action: <\(configAction)>", searchName)
				}
			} catch {
				Workflow.info("Error performing config action (\(configAction) on <\(searchName)>: \(error.localizedDescription)")
			}
			
		default: ()
		}
		
		return nil
	}
	
}
