//
//  ScryfallSearchTokenizer.swift
//  Spellbook
//
//  Created by Josh Birnholz on 8/9/22.
//  Copyright © 2022 iowncode. All rights reserved.
//

import Foundation

struct ScryfallTokenizer {
	private indirect enum TokenizedPart: CustomStringConvertible {
		case string(quality: String, qualifier: String, value: String)
		case name(String, exact: Bool = false)
		case or((TokenizedPart, TokenizedPart)?)
		case and((TokenizedPart, TokenizedPart)?)
		case not(TokenizedPart?)
		case group([TokenizedPart])
		case openParenthesis
		case closeParenthesis
		
		var description: String {
			switch self {
			case .string(let quality, let qualifier, let value):
				return "\(quality)\(qualifier)\(value)"
			case .name(let value, let exact):
				return exact ? "!\(value)" : value
			case .or(let value):
				if let (first, second) = value {
					return "(\(first) or \(second))"
				} else {
					return "OR"
				}
			case .and(let value):
				if let (first, second) = value {
					return "\(first) \(second)"
				} else {
					return "AND"
				}
			case .not(let value):
				if let value = value {
					return value.isGroup ? "-(\(value))" : "-\(value)"
				} else {
					return "NOT"
				}
			case .openParenthesis:
				return "("
			case .closeParenthesis:
				return ")"
			case .group(let items):
				let text = items.map(String.init(describing:)).joined(separator: " ")
				return items.count > 1 ? "(\(text))" : text
			}
		}
		
		var isGroup: Bool {
			switch self {
			case .string:
				return false
			case .name:
				return false
			case .or(let value?):
				return false
			case .and:
				return false
			case .not(let value?):
				return value.isGroup
			case .group:
				return true
			default:
				return false
			}
		}
		
		var scryfallTokenIgnoringUnrecognized: ScryfallSearchToken? {
			switch self {
			case .and(let object?):
				switch (object.0.scryfallToken, object.1.scryfallToken) {
				case (let left?, let right?):
					return .and(left, right)
				case (let left?, _):
					return left
				case (_, let right?):
					return right
				default:
					return nil
				}
			case .group(let objects):
				let tokens = objects.compactMap { $0.scryfallToken }
				return .init(andMultiple: tokens)
			default:
				if let token = scryfallToken {
					return token
				} else {
					return .criterion("unrecognized")
				}
			}
		}
		
		fileprivate var scryfallToken: ScryfallSearchToken? {
			func spaceFixed(_ string: String) -> String {
				string.contains(" ") ? "\"\(string)\"" : string
			}
			
			switch self {
			case .string(quality: let quality, qualifier: let qualifier, value: var value):
				
				let valueColors: [ScryfallSearchToken.Color] = {
					let dict: [String: [ScryfallSearchToken.Color]] = [
						"white": [.w],
						"blue": [.u],
						"black": [.b],
						"red": [.r],
						"green": [.g],
						"azorius": [.w, .u],
						"boros": [.r, .w],
						"dimir": [.u, .b],
						"golgari": [.b, .g],
						"gruul": [.r, .g],
						"izzet": [.u, .r],
						"orzhov": [.w, .b],
						"rakdos": [.b, .r],
						"selesnya": [.w, .g],
						"simic": [.u, .g],
						"abzan": [.w, .b, .g],
						"bant": [.w, .u, .g],
						"esper": [.w, .u, .b],
						"grixis": [.u, .b, .r],
						"jeskai": [.w, .u, .r],
						"jund": [.b, .r, .g],
						"mardu": [.w, .b, .r],
						"naya": [.w, .r, .g],
						"sultai": [.u, .b, .g],
						"temur": [.u, .r, .g],
						"silverquill": [.w, .b],
						"prismari": [.u, .r],
						"witherbloom": [.b, .g],
						"lorehold": [.r, .w],
						"quandrix": [.g, .u],
						"indatha": [.w, .b, .g],
						"cabaretti": [.r, .g, .w],
						"ketria": [.g, .u, .r],
						"obscura": [.w, .u, .b],
						"raugrin": [.u, .r, .w],
						"savai": [.r, .w, .b],
						"brokers": [.g, .w, .u],
						"maestros": [.u, .b, .r],
						"zagoth": [.b, .g, .u],
						"riveteers": [.b, .r, .g]
					]
					
					return dict[value.lowercased()] ?? colors(in: value).contents
				}()
				
				if let legality = ScryfallSearchToken.Legality(rawValue: quality.lowercased()) {
					return .legal(legality, value)
				}
				
				switch quality.lowercased() {
				case "c", "color":
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: valueColors == [.c] ? .exactly : .including) else { return nil }
					guard !valueColors.isEmpty else { return nil }
					return .colors(.color, valueColors, quantifier)
				case "commander", "id", "identity", "ci":
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: valueColors == [.c] ? .exactly : .atMost) else { return nil }
					guard !valueColors.isEmpty else { return nil }
					return .colors(.identity, valueColors, quantifier)
				case "t", "type":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					if value.lowercased() == "legend" {
						value = "legendary"
					}
					if value.lowercased() == "walker" {
						value = "planeswalker"
					}
					return .type(value)
				case "o", "oracle":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					return .oracleContains(value)
				case "mana", "m":
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .including) else { return nil }
					return .manaCost(value, quantifier)
				case "pow", "power":
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .exactly) else { return nil }
					return .stats(.power, quantifier, value)
				case "tou", "toughness":
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .exactly) else { return nil }
					return .stats(.toughness, quantifier, value)
				case "loyalty":
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .exactly) else { return nil }
					return .stats(.loyalty, quantifier, value)
				case "cmc", "mv", "manavalue":
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .exactly) else { return nil }
					return .stats(.cmc, quantifier, value)
        case "cn", "collectornumber", "number", "collector":
          guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .exactly) else { return nil }
          return .collectorNumber(quantifier, value)
				case "is", "has":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					return .criterion(value)
				case "not":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					return .not(.criterion(value))
				case "rarity", "r":
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .exactly) else { return nil }
					guard let rarity = ScryfallSearchToken.Rarity(rawValue: value.lowercased()) ?? ScryfallSearchToken.Rarity.allCases.first(where: { $0.rawValue.first?.lowercased() == value.first?.lowercased() }) else { return nil }
					return .rarity(rarity, quantifier)
				case "s", "e", "set", "edition":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					return .sets(value.components(separatedBy: ","))
				case "a", "artist":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					return .artist(value)
				case "wm", "watermark":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					return .watermark(value)
				case "border":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					guard let color = ScryfallSearchToken.BorderColor(rawValue: value.lowercased()) else { return nil }
					return .border(color)
				case "ft", "flavor":
					guard qualifier == ":" || qualifier == "=" else { return nil }
					return .flavorText(value)
				case "include":
					return .include(value)
				case "unique":
					if value.lowercased() == "prints" || value.lowercased() == "art" {
						return .unique(value)
					} else {
						return nil
					}
				case "lore":
					return .lore(value)
				case "format", "f":
					return .legal(.legal, value)
				case "owned":
					guard let value = Int(value), let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .including) else { return nil }
					return .owned(value, quantifier)
//				case "frame":
//					guard qualifier == ":" || qualifier == "=" else { return nil }
//					return .frame
				case "in":
					// TODO: support actuall scryfall In
					if value.lowercased() == "collection" {
						return .criterion("owned")
					}
					return nil
				default:
					return nil
				}
			case .name(let name, let exact):
				return .cardName(name,exact: exact)
			case .or(let object?):
				guard let left = object.0.scryfallToken, let right = object.1.scryfallToken else {
					return nil
				}
				return .or(left, right)
			case .and(let object?):
				guard let left = object.0.scryfallToken, let right = object.1.scryfallToken else {
					return nil
				}
				return .and(left, right)
			case .not(let object):
				guard let token = object?.scryfallToken else { return nil }
				return .not(token)
			case .group(let objects):
				let tokens = objects.compactMap { $0.scryfallToken }
				guard tokens.count == objects.count else { return nil }
				return .init(andMultiple: tokens)
			case .openParenthesis:
				return nil
			case .closeParenthesis:
				return nil
			case .or(.none):
				return nil
			case .and(.none):
				return nil
			}
		}
	}
	
//	enum TokenizerError: Error {
//
//	}

	private func token(for query: String) -> TokenizedPart? {
		let valueAllowedWordsString = #"\w°>²\]!{®\[—”\*-<:;&\?―•\\\.½“™#@\|\^’\$\+„=}\/…¾,˝−一-龠ぁ-ゔァ-ヴーa-zA-Z0-9ａ-ｚＡ-Ｚ０-９々〆〤ヶ~"#
		let regex = #"(?<prefix>[!\(\)-])|(?:(?:(?<quality>\w+)(?<qualifier>>=|<=|>|<|=|!=|:))?(?:"(?<doubleQuoteValue>[\#(valueAllowedWordsString)'\s\(\)]+)"|'(?<singleQuoteValue>[\#(valueAllowedWordsString)"\(\)\s]+)'|(?<value>[\#(valueAllowedWordsString)]+)))"#
		
		var exactIndex: Int?
		
		let tokens: [TokenizedPart] = query.matches(forRegex: regex).enumerated().compactMap { (index, token) in
			let prefix = token["prefix"]?.value
			switch prefix {
			case "(":
				return .openParenthesis
			case ")":
				return .closeParenthesis
			case "-":
				return .not(nil)
			case "!":
				exactIndex = index
			default:
				break
			}
			
			let quality = token["quality"]?.value
			let qualifier = token["qualifier"]?.value
			let value = token["doubleQuoteValue"]?.value ?? token["singleQuoteValue"]?.value ?? token["value"]?.value
			
			if let quality = quality, let qualifier = qualifier, let value = value {
				return .string(quality: quality, qualifier: qualifier, value: value)
			} else {
				if let value = value {
					switch value.lowercased() {
					case "or":
						return .or(nil)
					case "and":
	//					return .and(nil)
						return nil // AND operator does nothing, just put the things next to each other and they will get ANDed.
					default:
						let isExact = exactIndex == index-1
						exactIndex = nil
						return .name(value, exact: isExact)
					}
				}
			}
			
			return nil
		}
		
		var sections: [[TokenizedPart]] = [[]]
		var indent = 0
		for token in tokens {
			if case .closeParenthesis = token {
				indent -= 1
				continue
			}
			
			if case .openParenthesis = token {
				indent += 1
				sections.append([])
				continue
			}
			
			guard sections.indices.contains(indent) else {
				// Mismatched parentheses
				return nil
			}
			
			sections[indent].append(token)
		}
    
		// Resolve NOT

		for (sectionIndex, section) in sections.enumerated().reversed() {
			for (itemIndex, item) in section.enumerated().reversed() {
				if case .not(let value) = item, value == nil {
					// find next index.
					let nextIndex = section.enumerated().filter {
						if case .or = $0.1 { return false }
						if case .and = $0.1 { return false }
						return $0.0 > itemIndex
					}.first?.offset
					
					if let nextIndex = nextIndex {
						let next = sections[sectionIndex].remove(at: nextIndex)
						sections[sectionIndex][itemIndex] = .not(next)
					} else if sections.indices.contains(sectionIndex+1) {
						let nextSection = sections.remove(at: sectionIndex+1)
						let group = TokenizedPart.group(nextSection)
						sections[sectionIndex][itemIndex] = .not(group)
					}
				}
			}
		}

		// Guard here to ensure all NOTs are handled.

		// Resolve OR

		for (sectionIndex, section) in sections.enumerated().reversed() {
			var section = section
			resolveOrInSection(&section)
			sections[sectionIndex] = section
		}

		// Guard here to ensure all ORs are handled.
    
		// Resolve ANDs

		let joinedSections: [TokenizedPart] = Array(sections.joined())

		guard !joinedSections.isEmpty else {
			return nil
		}
		guard joinedSections.count >= 2 else {
			return joinedSections[0]
		}
		
		var result: TokenizedPart

		let object = (joinedSections[0], joinedSections[1])
		let finalTokens = joinedSections[2...]
		
		result = .and(object)

		for token in finalTokens {
			let object = (result, token)
			result = .and(object)
		}
		
		return result
	}
	
	private func resolveOrInSection(_ section: inout [TokenizedPart]) {
		for (itemIndex, item) in section.enumerated().reversed() {
			if case .or(let value) = item, value == nil {
				let previousIndex = itemIndex-1
				let nextIndex = itemIndex+1
				if section.indices.contains(previousIndex) && section.indices.contains(nextIndex) {
					let next = section.remove(at: nextIndex)
					section.remove(at: itemIndex)
					let previous = section.remove(at: previousIndex)
					
					let object = (previous, next)
					section.insert(TokenizedPart.or(object), at: previousIndex)
				}
			} else if case .group(let group) = item {
				var group = group
				resolveOrInSection(&group)
				section[itemIndex] = .group(group)
			} else if case .not(let notGroup) = item, case .group(let group) = notGroup {
				var group = group
				resolveOrInSection(&group)
				section[itemIndex] = .not(.group(group))
			}
		}
	}

	private func string(for query: String) -> String? {
		guard let token = self.token(for: query) else { return nil }
		return String(describing: token)
	}
	
	public func scryfallToken(for query: String, ignoreUnrecognized: Bool = false) -> ScryfallSearchToken? {
		guard let token = self.token(for: query) else {
			// Coudln't get tokenized part
			return nil
		}
//		return token.scryfallToken
		return ignoreUnrecognized ? token.scryfallTokenIgnoringUnrecognized : token.scryfallToken
	}
}
