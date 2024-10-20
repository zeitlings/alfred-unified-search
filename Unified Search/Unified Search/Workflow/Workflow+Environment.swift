//
//  Workflow+Environment.swift
//  suffix web search
//
//  Created by Patrick Sy on 22/09/2024.
//

import Foundation

extension Workflow {
	
	static let injectQuicklook: Bool = envvar("config_always_inject_quicklookurl") == "true"
	
	static func envvar(_ key: String) -> String? {
		Env.environment[key]
	}

	enum Env {
		static let environment: [String:String] = ProcessInfo.processInfo.environment
		static let workflowUID: String? = environment["alfred_workflow_uid"]
		static let workflowName: String? = environment["alfred_workflow_name"]
		static let debugPaneIsOpen: Bool  =  environment["alfred_debug"] == "1"
		static let workflowVersion: String? = environment["alfred_workflow_version"]
		static let workflowBundleID: String? = environment["alfred_workflow_bundleid"]
		/// The path to the workflow directory
		static let workflowPath: String? = {
			guard let preferences: String, let workflowUID: String else {
				return nil
			}
			return "\(preferences)/workflows/\(workflowUID)"
		}()
		/// ~/Library/Application Support/Alfred/Alfred.alfredpreferences
		static let preferences: String? = environment["alfred_preferences"]
		static let preferencesLocalHash: String? = environment["alfred_preferences_localhash"]
		static let localPreferences: String? = {
			guard let path: String = preferences,
				  let localHash: String = preferencesLocalHash
			else {
				return nil
			}
			return "\(path)/preferences/local/\(localHash)"
		}()
		static let alfredVersion: String? = environment["alfred_version"]
		static let alfredVersionBuild: Int? = Int(environment["alfred_version_build"] ?? "")
		/// `~/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/com.zeitlings.gpt.nexus/`
		static let workflowCacheDirectory: String? = environment["alfred_workflow_cache"]
		/// `~/Library/Application Support/Alfred/Workflow Data/com.zeitlings.gpt.nexus/`
		static let workflowDataDirectory: String? = environment["alfred_workflow_data"]
		static let websearchPreferencesPath: String? = preferences?.appending("/preferences/features/websearch/prefs.plist")
		// Custom Alfred Websearch icons are stored here
		static let alfredResourcesPath: String? = preferences?.appending("/resources")
	}
	
	
}

