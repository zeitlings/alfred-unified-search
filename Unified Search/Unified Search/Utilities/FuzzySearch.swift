//
//  FuzzySearch.swift
//  suffix web search
//
//  Created by Patrick Sy on 22/09/2024.
//

typealias WebSearch = WebSearches.WebSearch

struct Fuzzy {
	let query: String.UnicodeScalarView
	private let adjBonus: Int
	private let sepBonus: Int
	private let camelBonus: Int
	private let leadPenalty: Int
	private let maxLeadPenalty: Int
	private let unmatchedPenalty: Int
	private let separators: Set<UnicodeScalar>
	private let stripDiacritics: Bool
	
	init(
		query: String,
		adjBonus: Int = 5,
		sepBonus: Int = 10, // Increase for more dominant initial character matching
		camelBonus: Int = 10,
		leadPenalty: Int = -3,
		maxLeadPenalty: Int = -9,
		unmatchedPenalty: Int = -1,
		separators: String = "_-.–/ ",
		stripDiacritics: Bool = true // Strip diacritics from targets if query is plain ASCII
	) {
		self.query = query.unicodeScalars
		self.adjBonus = adjBonus
		self.sepBonus = sepBonus
		self.camelBonus = camelBonus
		self.leadPenalty = leadPenalty
		self.maxLeadPenalty = maxLeadPenalty
		self.unmatchedPenalty = unmatchedPenalty
		self.separators = Set(separators.unicodeScalars)
		self.stripDiacritics = stripDiacritics && query.allSatisfy({ $0.isASCII })
	}
}

extension Fuzzy {
	struct MatchResult: Comparable, Equatable {
		let isMatch: Bool
		let score: Int
		let query: String
		let target: WebSearches.WebSearch
		
		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.target == rhs.target && lhs.score == rhs.score
		}
		
		static func < (lhs: Self, rhs: Self) -> Bool {
			lhs.score < rhs.score
		}
		
	}
}


extension Fuzzy {
	
	//https://gist.github.com/menzenski/f0f846a254d269bd567e2160485f4b89
	func match(in target: WebSearch) -> MatchResult {
		if target.shorthand?.lowercased() == String(query).lowercased() {
			return MatchResult(isMatch: true, score: 100, query: String(query), target: target)
		}
		let targetScalars: String.UnicodeScalarView = {
			stripDiacritics ? target.name.folding(options: [.diacriticInsensitive], locale: nil).unicodeScalars : target.name.unicodeScalars
		}()
		let targetLen: Int = targetScalars.count
		let targetBuffer: ContiguousArray<UnicodeScalar> = .init(targetScalars)
		
		var score = 0
		var pIdx = 0
		var sIdx = 0
		let pLen = query.count
		
		var prevMatch = false
		var prevLower = false
		var prevSep = true
		var bestLetter: UnicodeScalar? = nil
		var bestLower: UnicodeScalar? = nil
		var bestLetterIdx = -1
		var bestLetterScore = 0
		var matchedIndices: ContiguousArray<Int> = []
		matchedIndices.reserveCapacity(pLen)
		
		while sIdx < targetLen {
			let pChar: UnicodeScalar? = pIdx < pLen ? query[query.index(query.startIndex, offsetBy: pIdx)] : nil
			let sChar: UnicodeScalar = targetBuffer[sIdx]
			let pLower: UnicodeScalar? = pChar?.properties.lowercaseMapping.unicodeScalars.first
			let sLower: UnicodeScalar = sChar.properties.lowercaseMapping.unicodeScalars.first!
			let sUpper: UnicodeScalar = sChar.properties.uppercaseMapping.unicodeScalars.first!
			let nextMatch: Bool = pChar != nil && pLower == sLower
			let rematch: Bool = bestLetter != nil && bestLower == sLower
			let advanced: Bool = nextMatch && bestLetter != nil
			let pRepeat: Bool = bestLetter != nil && pChar != nil && bestLower == pLower
			
			if advanced || pRepeat {
				score &+= bestLetterScore
				matchedIndices.append(bestLetterIdx)
				bestLetter = nil
				bestLower = nil
				bestLetterIdx = -1
				bestLetterScore = 0
			}
			
			if nextMatch || rematch {
				var newScore = 0
				if pIdx == 0 {
					score &+= max(sIdx &* leadPenalty, maxLeadPenalty)
				}
				if prevMatch {
					newScore &+= adjBonus
				}
				if prevSep {
					newScore &+= sepBonus
				}
				if prevLower && sChar == sUpper && sLower != sUpper {
					newScore &+= camelBonus
				}
				if nextMatch {
					pIdx &+= 1
				}
				if newScore >= bestLetterScore {
					if bestLetter != nil {
						score &+= unmatchedPenalty
					}
					bestLetter = sChar
					bestLower = sLower
					bestLetterIdx = sIdx
					bestLetterScore = newScore
				}
				prevMatch = true
				
			} else {
				score &+= unmatchedPenalty
				prevMatch = false
			}
			
			prevLower = sChar == sLower && sLower != sUpper
			prevSep = separators.contains(sChar)
			
			sIdx &+= 1
		}
		
		if bestLetter != nil {
			score &+= bestLetterScore
			matchedIndices.append(bestLetterIdx)
		}
		
		return MatchResult(isMatch: pIdx == pLen, score: score, query: String(query), target: target)
	}
	
	func sorted(candidates: [WebSearch], matchesOnly: Bool = true) -> [MatchResult] {
		let processedCandidates: [MatchResult] = candidates.map { match(in: $0) }.sorted(by: >)
		return matchesOnly ? processedCandidates.filter(\.isMatch) : processedCandidates
	}
}
