//
//  DeckParser.swift
//  Magic Board
//
//  Created by Josh Birnholz on 2/20/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation

public struct DeckParser {
	public struct CardGroup {
		public enum GroupName: String {
			case deck = "Deck"
			case sideboard = "Sideboard"
			case command = "Commander"
			case companion = "Companion"
		}
		
		public static func name(for line: String) -> String {
			switch line.lowercased() {
			case "deck", "main deck", "maindeck", "main", "creatures", "creature", "instant", "instants", "land", "lands", "sorceries", "sorcery", "spell", "spells", "enchantment", "enchantments", "artifact", "artifacts": return GroupName.deck.rawValue
			case "sideboard", "", "\n": return GroupName.sideboard.rawValue
			case "commander", "command": return GroupName.command.rawValue
			case "companion": return GroupName.companion.rawValue
			default:
				return line
			}
		}
		
		public var name: String?
		public var cardCounts: [CardCount]
	}
	
	public struct CardCount: Hashable, Equatable {
		public var identifier: MTGCardIdentifier
		public var count: Int
	}
	
	public static func parse(deckList: String) -> [CardGroup] {
		let regex = #"^(?:(?:\/\/)?(\S*)\s*$|\s*(\d+)\s+([^\(\n]+\S)(?:\s*|\s+\(\s*(\S+)\s*\)(?:\h+(\S+)\s*|\s*)))$"#
		
		let matches = deckList.matches(forRegex: regex, options: [.anchorsMatchLines])
		var cardGroups: [CardGroup] = []
		
		for (_, groups) in matches {
			switch groups.count {
			case 1:
				let value = groups[0].value.trimmingCharacters(in: .whitespacesAndNewlines)
				let newGroup = CardGroup(name: CardGroup.name(for: value), cardCounts: [])
				cardGroups.append(newGroup)
			case 2:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
				let name = groups[1].value
				guard let number = Int(count) else { continue }
				let cardCount = CardCount(identifier: .name(name), count: number)
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			case 3:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
				let name = groups[1].value
				let set = groups[2].value
				
				guard let number = Int(count) else { continue }
				let cardCount = CardCount(identifier: .nameSet(name: name, set: set), count: number)
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			case 4:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
				let name = groups[1].value
				let set = groups[2].value
				let collectorNumber = groups[3].value
				
				guard let number = Int(count) else { continue }
				let cardCount = CardCount(identifier: .collectorNumberSet(collectorNumber: collectorNumber, set: set, name: name), count: number)
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			default:
				break
			}
		}
		
		return cardGroups
	}
	
	public static func parse(deckstatsDecklist: String) -> [CardGroup] {
		let regex = #"(?:^\/\/(\S+)$|^([0-9]+) (?:\[(.+)\] (.+)$|(.+)$))"#
		
		var commanderLines: [String] = []
		
		var lines: [String] = deckstatsDecklist
			.components(separatedBy: .newlines)
			.compactMap {
				var line = $0
				if let range = line.range(of: "//") {
					line.removeSubrange(range)
				}
				
				let isCommander = line.contains("!Commander")
				
				if let index = line.firstIndex(of: "#") {
					line = String(line[..<index])
				}
				
				guard !isCommander else {
					commanderLines.append(line)
					return nil
				}
				
				return line
		}
		
		if !commanderLines.isEmpty {
			commanderLines.insert("Commander", at: 0)
			lines.insert(contentsOf: commanderLines, at: 0)
		}
		
		let deckList = lines.joined(separator: "\n")
		
		let matches = deckList.matches(forRegex: regex, options: [.anchorsMatchLines])
		var cardGroups: [CardGroup] = []
		
		for (_, groups) in matches {
			switch groups.count {
			case 1:
				let value = groups[0].value.trimmingCharacters(in: .whitespacesAndNewlines)
				let newGroup = CardGroup(name: CardGroup.name(for: value), cardCounts: [])
				cardGroups.append(newGroup)
			case 2:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
				let name = groups[1].value
				guard let number = Int(count) else { continue }
				let cardCount = CardCount(identifier: .name(name), count: number)
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			case 3:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
				let name = groups[2].value
				let set = groups[1].value
				
				guard let number = Int(count) else { continue }
				let cardCount = CardCount(identifier: .nameSet(name: name, set: set), count: number)
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			default:
				break
			}
		}
		
		return cardGroups
	}
}
