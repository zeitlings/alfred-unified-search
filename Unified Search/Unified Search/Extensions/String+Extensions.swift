//
//  String+Extensions.swift
//  suffix web search
//
//  Created by Patrick Sy on 22/09/2024.
//

extension StringProtocol {
	var trimmed: String { self.trimmingCharacters(in: .whitespacesAndNewlines) }
}
