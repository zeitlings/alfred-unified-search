//
//  FileHandler.swift
//  suffix web search
//
//  Created by Patrick Sy on 24/09/2024.
//

import Foundation

struct FileHandler {
	typealias WebSearch = WebSearches.WebSearch
	
	static let fm: FileManager = .default
	static let dataDirPath: String = Workflow.Env.workflowDataDirectory!
	static let customizationFile: URL = .init(fileURLWithPath: dataDirPath)
		.appending(component: "config_searches")
		.appendingPathExtension("json")
	private static let jsonDecoder: JSONDecoder = .init()
	private static let jsonEncoder: JSONEncoder = .init()
	
	static func getSearches() -> [WebSearch] {
		
		guard
			let workflowFolder: String = Workflow.Env.workflowPath,
			fm.fileExists(atPath: "\(workflowFolder)/assets/searches.json"),
			let searchesJSON: Data = fm.contents(atPath: "\(workflowFolder)/assets/searches.json"),
			var webSearches: [WebSearch] = try? jsonDecoder.decode(WebSearches.Module.self, from: searchesJSON).searches
		else {
			Workflow.quit("Unable to retrieve Searches from assets.")
		}
		
		//Workflow.log("Number of builtin Web-Searches: \(webSearches.count).")
		
		if Workflow.includeCustomAlfredWebsearches {
			let customAlfredSearches: [WebSearch] = getAlfredWebSearches()
			if customAlfredSearches.isEmpty {
				Workflow.log("Custom Alfred Web-Searches are included, but none were enabled. Enable at least one custom Alfred Websearch to include it in \(Workflow.Env.workflowName ?? "the workflow").")
			}
			for customAlfredSearch in customAlfredSearches
			where webSearches.firstIndex(where: { $0.name == customAlfredSearch.name }) == nil
			// Ignore duplicate names~
			{
				webSearches.append(customAlfredSearch)
			}
		}
		
		let customizedSearches: [WebSearch] = getCustomizedSearches()
		for customizedSearch in customizedSearches {
			if let index: Int = webSearches.firstIndex(of: customizedSearch) {
				webSearches[index].active = customizedSearch.active
				webSearches[index].isDefault = customizedSearch.isDefault
			}
		}
		
		return webSearches
	}
	
	static private func getCustomizedSearches() -> [WebSearch] {
		//Workflow.log("File: \(customizationFile.path)")
		guard fm.fileExists(atPath: customizationFile.path(percentEncoded: false)),
			  let data: Data = try? .init(contentsOf: customizationFile),
			  let searches: [WebSearch] = try? jsonDecoder.decode([WebSearch].self, from: data)
		else {
			return []
		}
		return searches
	}
	
	static private func getAlfredWebSearches() -> [WebSearch] {
		guard let websearchPreferencesPath: String = Workflow.Env.websearchPreferencesPath else {
			Workflow.log("Websearch Preferences Path not found", .warning)
			Workflow.log("Envvar Preferences: <\(Workflow.Env.preferences ?? "NO PREFERENCES")>", .info)
			return []
		}
		//Workflow.log("✓ Websearch Preferences Path: <\(websearchPreferencesPath)>", .debug)
		guard let websearchPreferencesPlist: Data = {
			do {
				return try Data(contentsOf: URL(fileURLWithPath: websearchPreferencesPath))
			} catch {
				Workflow.log("Error reading websearch preference plist: \(error.localizedDescription)", .error)
				return nil
			}
		}() else {
			Workflow.log("Unable to read Websearch Preferences Plist", .warning)
			return []
		}
		
		let websearchCustomIcons: [String: String] = {
			guard let alfredResourcesPath: String = Workflow.Env.alfredResourcesPath else {
				Workflow.log("Alfred Resources Path not found", .warning)
				return [:]
			}
			
			guard let contents: [URL] = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: alfredResourcesPath), includingPropertiesForKeys: nil)
			else {
				Workflow.log("Unable to read Alfred Resources Directory", .warning)
				return [:]
			}
			var iconMap: [String: String] = [:]
			let prefix: String = "features.websearch.custom."
			for resource in contents {
				let path: String = resource.path
				let file: String = resource.lastPathComponent
				if file.hasPrefix(prefix) {
					// features.websearch.custom.1D0D1ECF-8328-4E09-A01B-D797EEE12662.png
					iconMap[resource.deletingPathExtension().pathExtension] = path
					//Workflow.log("Key:   <\(resource.deletingPathExtension().pathExtension)>", .debug)
					//Workflow.log("Value: <\(path)>", .debug)
				}
			}
			return iconMap
		}()
		
		if let sites: CustomSites = try? PropertyListDecoder().decode(CustomSites.self, from: websearchPreferencesPlist) {
			//Workflow.log("✓ Decoded Custom WebSearch Plist", .debug)
			let searches: [WebSearch] = sites.customSites.reduce(into: []) { partialResult, kv in
				let site: CustomSite = kv.value
				if site.enabled {
					partialResult.append(
						.init(name: site.text,
							  url: site.url.replacing("{query}", with: "{input}"),
							  shorthand: site.keyword,
							  active: true,
							  isDefault: false,
							  icon: websearchCustomIcons[kv.key],
							  isAlfredWebsearch: true
							 )
					)
					//Workflow.log("CustomSite UUID: \(kv.key)")
				}
			}
			return searches
		}
		Workflow.log("Failed to decode CustomSites", .warning)
		return []
	}
	
	static func saveCustomizedSearch(_ webSearch: WebSearch) throws {
		let webSearch: WebSearch = webSearch
		var searches: [WebSearch] = getCustomizedSearches()
		if let index = searches.firstIndex(of: webSearch) {
			searches[index] = webSearch
		} else {
			searches.append(webSearch)
		}
		
		let encoded: Data = try jsonEncoder.encode(searches)
		if !fm.fileExists(atPath: dataDirPath) {
			try fm.createDirectory(at: URL(fileURLWithPath: dataDirPath), withIntermediateDirectories: true)
		}
		try encoded.write(to: customizationFile)
	}
	
}
