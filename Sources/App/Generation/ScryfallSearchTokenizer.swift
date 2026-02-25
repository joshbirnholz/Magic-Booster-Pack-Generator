//
//  ScryfallSearchTokenizer.swift
//  Spellbook
//
//  Created by Josh Birnholz on 8/9/22.
//  Copyright © 2022 iowncode. All rights reserved.
//

import Foundation

struct ScryfallTokenizer {  
  enum Directive: Equatable, CustomStringConvertible {
    case includeExtas      // include:extras
    case sort(Swiftfall.SearchOrder)         // sort:edhrec
    case unique(Swiftfall.Unique)       // unique:prints / unique:art
    case prefer(ScryfallSearchToken.Prefer)       // prefer:newest
    case direction(Swiftfall.SearchOrderDirection) // order:asc
    
    var description: String {
      switch self {
      case .includeExtas:
        "include:extras"
      case .sort(let sort):
        "sort:\(sort.rawValue)"
      case .unique(let unique):
        "unique:\(unique.rawValue)"
      case .prefer(let prefer):
        "prefer:\(prefer.rawValue)"
      case .direction(let direction):
        "direction:\(direction)"
      }
    }
  }
  
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
				case "c", "color", "colors":
          if let num = Int(value), let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .exactly) {
            return .colorCount(.color, num, quantifier)
          }
          
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: valueColors == [.c] ? .exactly : .including) else { return nil }
          
					guard !valueColors.isEmpty else { return nil }
					return .colors(.color, valueColors, quantifier)
				case "commander", "id", "identity", "ci":
          if let num = Int(value), let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: .exactly) {
            return .colorCount(.identity, num, quantifier)
          }
          
					guard let quantifier = ScryfallSearchToken.Quantifier(value: qualifier, valueForColon: valueColors == [.c] ? .exactly : .atMost) else { return nil }
          
					guard !valueColors.isEmpty else { return nil }
					return .colors(.identity, valueColors, quantifier)
				case "t", "type":
					guard qualifier == ":" || qualifier == "=" else { return nil }
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
        case "name":
          guard qualifier == ":" || qualifier == "=" else { return nil }
          return .cardName(value)
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
  
  private func groupParentheses(_ tokens: [TokenizedPart]) -> TokenizedPart? {
    var stack: [[TokenizedPart]] = [[]]
    
    for token in tokens {
      switch token {
      case .openParenthesis:
        stack.append([])
      case .closeParenthesis:
        guard stack.count > 1 else { return nil } // mismatched
        let completed = stack.removeLast()
        stack[stack.count - 1].append(.group(completed))
      default:
        stack[stack.count - 1].append(token)
      }
    }
    
    guard stack.count == 1 else { return nil } // unclosed parenthesis
    return buildExpression(stack[0])
  }
  
  private func buildExpression(_ tokens: [TokenizedPart]) -> TokenizedPart? {
    var slice = tokens[...]
    return parseOr(&slice)
  }
  
  // OR binds loosest
  private func parseOr(_ tokens: inout ArraySlice<TokenizedPart>) -> TokenizedPart? {
    guard var left = parseAnd(&tokens) else { return nil }
    
    while let first = tokens.first, case .or(nil) = first {
      tokens.removeFirst()
      guard let right = parseAnd(&tokens) else { break }
      left = .or((left, right))
    }
    
    return left
  }
  
  // AND is implicit adjacency — keep consuming while next token isn't OR
  private func parseAnd(_ tokens: inout ArraySlice<TokenizedPart>) -> TokenizedPart? {
    guard var left = parseNot(&tokens) else { return nil }
    
    while let next = tokens.first {
      // Stop if we see an OR — let the caller handle it
      if case .or(nil) = next { break }
      // Stop if nothing parseable follows
      guard let right = parseNot(&tokens) else { break }
      left = .and((left, right))
    }
    
    return left
  }
  
  // NOT is a prefix operator
  private func parseNot(_ tokens: inout ArraySlice<TokenizedPart>) -> TokenizedPart? {
    if let first = tokens.first, case .not(nil) = first {
      tokens.removeFirst()
      guard let operand = parseAtom(&tokens) else { return nil }
      return .not(operand)
    }
    return parseAtom(&tokens)
  }
  
  // Atoms: named values, key:value strings, and groups
  private func parseAtom(_ tokens: inout ArraySlice<TokenizedPart>) -> TokenizedPart? {
    guard let first = tokens.first else { return nil }
    
    switch first {
    case .string, .name:
      tokens.removeFirst()
      return first
    case .group(let contents):
      tokens.removeFirst()
      // Recursively parse the group's contents as a full expression
      var inner = contents[...]
      return parseOr(&inner).map { .group([$0]) }
    case .not(nil), .or(nil), .and(nil):
      // These are operators, not atoms — don't consume
      return nil
    default:
      return nil
    }
  }

  private func token(for query: String) -> (token: TokenizedPart, directives: [Directive])? {
    // 1. Lex: regex → flat token list
    let (flat, directives) = lex(query)
    guard !flat.isEmpty, let token = groupParentheses(flat) else { return nil }
    
    // 2. Group: handle parentheses with a stack
    return (token, directives)
  }
  
  private func lex(_ query: String) -> (parts: [TokenizedPart], directives: [Directive]) {
    var parts: [TokenizedPart] = []
    var directives: [Directive] = []
    
    let valueAllowedWordsString = #"\w°>²\]!{®\[—"\*-<:;&\?―•\\\.½"™#@\|\^'\$\+„=}\/…¾,˝−一-龠ぁ-ゔァ-ヴーa-zA-Z0-9ａ-ｚＡ-Ｚ０-９々〆〤ヶ~"#
    let regex = #"(?<prefix>[\(\)-])|(?<exact>!(?:"(?<exactDoubleQuoteValue>[\#(valueAllowedWordsString)'\s\(\)]+)"|'(?<exactSingleQuoteValue>[\#(valueAllowedWordsString)"\(\)\s]+)'|(?<exactValue>[\#(valueAllowedWordsString)]+)))|(?:(?:(?<field>\w+)(?<op>>=|<=|>|<|=|!=|:))?(?:"(?<doubleQuoteValue>[\#(valueAllowedWordsString)'\s\(\)]+)"|'(?<singleQuoteValue>[\#(valueAllowedWordsString)"\(\)\s]+)'|(?<value>[\#(valueAllowedWordsString)]+)))"#
    
    for match in query.matches(forRegex: regex) {
      if let part = makeTokenizedPart(from: match) {
        if let directive = directive(from: part) {
          directives.append(directive)
        } else {
          parts.append(part)
        }
      }
    }
    
    return (parts, directives)
  }
  
  private func makeTokenizedPart(from token: RegexResult) -> TokenizedPart? {
    let prefix = token["prefix"]?.value
    switch prefix {
    case "(": return .openParenthesis
    case ")": return .closeParenthesis
    case "-": return .not(nil)
    default: break
    }
    
    if token["exact"]?.value != nil {
      let value = token["exactDoubleQuoteValue"]?.value
      ?? token["exactSingleQuoteValue"]?.value
      ?? token["exactValue"]?.value
      guard let value else { return nil }
      return .name(value, exact: true)
    }
    
    let field = token["field"]?.value
    let op = token["op"]?.value
    let value = token["doubleQuoteValue"]?.value
    ?? token["singleQuoteValue"]?.value
    ?? token["value"]?.value
    
    if let field, let op, let value {
      return .string(quality: field, qualifier: op, value: value)
    } else if let value {
      switch value.lowercased() {
      case "or":  return .or(nil)
      case "and": return nil
      case "++":  return .string(quality: "unique", qualifier: ":", value: "prints")
      case "@@":  return .string(quality: "unique", qualifier: ":", value: "art")
      default:
        if value.hasPrefix("!") {
          return .name(String(value.dropFirst()), exact: true)
        }
        return .name(value, exact: false)
      }
    }
    
    return nil
  }
  
  private func directive(from part: TokenizedPart) -> Directive? {
    guard case .string(let quality, let qualifier, let value) = part, qualifier == ":" else {
      return nil
    }
    let v = value.lowercased()
    
    switch quality.lowercased() {
    case "include" where v == "extras":
      return .includeExtas
    case "sort":
      if let o = Swiftfall.SearchOrder(rawValue: v) {
        return .sort(o)
      } else if v == "mv" {
        return .sort(.cmc)
      }
    case "unique":
      if let u = Swiftfall.Unique(rawValue: v) {
        return .unique(u)
      }
    case "prefer":
      if let p = ScryfallSearchToken.Prefer(rawValue: v) {
        return .prefer(p)
      } else if v == "ub" {
        return .prefer(.universesBeyond)
      } else if v == "notub" {
        return .prefer(.notUniversesBeyond)
      }
    case "order":
      if let o = Swiftfall.SearchOrderDirection(rawValue: v) {
        return.direction(o)
      }
    default:
      break
    }
    
    return nil
  }

	func string(for query: String) -> String? {
    guard let (token, directives) = self.token(for: query) else { return nil }
		var string = String(describing: token)
    
    if !directives.isEmpty {
      string += " "
      string += directives.map(String.init).joined(separator: " ")
    }
    
    return string
	}
	
  public func scryfallToken(for query: String, ignoreUnrecognized: Bool = false) -> (token: ScryfallSearchToken, directives: [Directive])? {
    guard let (token, directives) = self.token(for: query) else {
			// Coudln't get tokenized part
			return nil
		}
//		return token.scryfallToken
    if let fullToken = ignoreUnrecognized ? token.scryfallTokenIgnoringUnrecognized : token.scryfallToken {
      return (fullToken, directives)
    } else {
      return nil
    }
	}
}
