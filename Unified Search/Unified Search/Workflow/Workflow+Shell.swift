//
//  Workflow+Shell.swift
//  suffix web search
//
//  Created by Patrick Sy on 24/09/2024.
//

import Foundation

extension Workflow {
	static func external(id triggerId: String, argument: String, process: Process = .init()) -> Never {
		guard
			let bundleId: String = Env.workflowBundleID,
			let encoded: String = argument.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
		else {
			let errorInfo: String = "Failure preparing for External Trigger"
			let errorMessage: String = "BundleID: \(Env.workflowBundleID ?? "Must be set"). TriggerID \(triggerId)"
			quit(errorInfo, errorMessage)
		}
		let command: String = "open alfred://runtrigger/\(bundleId)/\(triggerId)/?argument=\(encoded)"
		process.bash(with: command)
		exit(.success)
	}
}

fileprivate extension Process {
	func bash(with command: String) {
		launchPath = "/bin/bash"
		arguments = ["-c", command]
		launch()
		waitUntilExit()
	}
}
