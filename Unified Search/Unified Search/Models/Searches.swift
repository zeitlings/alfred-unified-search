//
//  Searches.swift
//  suffix web search
//
//  Created by Patrick Sy on 22/09/2024.
//

import Foundation

fileprivate let inputPlaceholder: String = "{input}"

enum WebSearches {}

extension WebSearches {
	struct Module: Codable, Hashable {
		let version: String
		let author: String
		let updated: String
		var searches: [WebSearch]

		init(version: String, author: String, updated: String, searches: [WebSearch]) {
			self.version = version
			self.author = author
			self.updated = updated
			self.searches = searches
		}
	}
	
	struct WebSearch: Codable, Hashable, Equatable {
		let name: String
		let url: String
		var shorthand: String?
		var active: Bool
		var isDefault: Bool
		let icon: String?
		let isAlfredWebsearch: Bool?
		
		init(name: String, url: String, shorthand: String?, active: Bool, isDefault: Bool, icon: String?, isAlfredWebsearch: Bool?) {
			self.name = name
			self.url = url
			self.shorthand = shorthand
			self.active = active
			self.isDefault = isDefault
			self.icon = icon
			self.isAlfredWebsearch = isAlfredWebsearch
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine(name)
			hasher.combine(url)
		}
		
		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.name == rhs.name && lhs.url == rhs.url
		}
		
	}
}

extension WebSearches.WebSearch {
	
	func alfredItem(query: String) -> Item? {
		guard active else { return nil }
		let arg: Argument = .string(url.replacing(inputPlaceholder, with: query))
		return .with {
			$0.arg = arg
			$0.title = name
			if let isAlfredWebsearch, isAlfredWebsearch {
				$0.title = name.replacing("{query}", with: "{input}") //+ " (active: \(active))"
			}
			if let icon {
				if let isAlfredWebsearch, isAlfredWebsearch {
					$0.icon = .init(path: icon)
				} else {
					$0.icon = .init(path: "images/icons/\(icon).png")
				}
			}
			$0.autocomplete = Workflow.filterBehaviour == .always
				? "\(Search.queryFull) \(g_FilterSeperator) "
				: "\(query) \(g_FilterSeperator) "
			
			if let shorthand {
				$0.shift = .init(arg: arg, subtitle: "Shorthand: \(shorthand)", icon: nil)
			}
			$0.alt = .init(arg: arg, subtitle: url, icon: nil)
		}
	}
	
	var configAlfredItem: Item {
		.with {
			$0.title = name
			if let isAlfredWebsearch, isAlfredWebsearch {
				$0.title = name.replacing("{query}", with: "{input}")
			}
			if let icon {
				if let isAlfredWebsearch, isAlfredWebsearch {
					$0.icon = .init(path: icon)
				} else {
					$0.icon = .init(path: "images/icons/\(icon).png")
				}
			}
			let defaultMessage: String = isDefault ? "Remove default" : "Add default"
			let activeMessage: String = active ? "Deactivate" : "Activate"
			$0.subtitle = "⌘ \(defaultMessage)  ·  ⌥ \(activeMessage)"
			$0.arg = .string(name)
			$0.valid = false
			
			$0.cmd = .with({
				$0.arg = .string(name)
				$0.valid = true
				$0.subtitle = "⏎ \(defaultMessage)"
				$0.variables = .nested([
					"trigger": .string("config"),
					"token": .string("valid"),
					"config_action": .string(isDefault ? "remove_default" : "add_default")
				])
			})
			
			$0.alt = .with({
				$0.arg = .string(name)
				$0.valid = true
				$0.subtitle = "⏎ \(activeMessage)"
				$0.variables = .nested([
					"trigger": .string("config"),
					"token": .string("valid"),
					"config_action": .string(active ? "deactivate" : "activate")
				])
			})
			
			if let shorthand {
				$0.shift = .with({
					$0.valid = false
					$0.subtitle = "Shorthand: \(shorthand)"
					if let isAlfredWebsearch, isAlfredWebsearch {
						$0.subtitle?.append(" [Custom Search]")
					}
				})
			}
			
		}
	}
	
}
