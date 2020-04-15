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
		}
		
		public static func name(for line: String) -> String {
			switch line.lowercased() {
			case "deck", "main deck", "maindeck": return GroupName.deck.rawValue
			case "sideboard", "", "\n": return GroupName.sideboard.rawValue
			case "commander", "command": return GroupName.command.rawValue
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
	
	private static let regex = #"^(?:(?:\/\/)?(\S+)$|\s*(\d+)\s+([^\(\n]+\S)(?:\s*|\s+\(\s*(\S+)\s*\)(?:\s+(\S+)\s*|\s*)))$"#
	
	public static func parse(deckList: String) -> [CardGroup] {
		let matches = deckList.matches(forRegex: regex, options: [.anchorsMatchLines])
		var cardGroups: [CardGroup] = []
		
		for (_, groups) in matches {
			switch groups.count {
			case 1:
				let newGroup = CardGroup(name: CardGroup.name(for: groups[0].value), cardCounts: [])
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
				let cardCount = CardCount(identifier: .collectorNumberSet(collectorNumber: collectorNumber, set: set), count: number)
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			default:
				break
			}
		}
		
		return cardGroups
	}
}
