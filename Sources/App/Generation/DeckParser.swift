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
			case maybeboard = "Maybeboard"
		}
		
		public static func name(for line: String, defaultToMain: Bool = false) -> String {
			switch line.lowercased() {
			case "deck", "main deck", "maindeck", "main", "creatures", "creature", "instant", "instants", "land", "lands", "sorceries", "sorcery", "spell", "spells", "enchantment", "enchantments", "artifact", "artifacts": return GroupName.deck.rawValue
			case "sideboard", "", "\n": return GroupName.sideboard.rawValue
			case "commander", "command": return GroupName.command.rawValue
			case "companion": return GroupName.companion.rawValue
			case "maybe", "maybeboard": return GroupName.maybeboard.rawValue
			case _ where defaultToMain: return GroupName.deck.rawValue
			default:
				return line
			}
		}
		
		public var name: String?
		public var cardCounts: [CardCount]
	}
	
  public struct CardCount: Hashable, Equatable {
    init(identifier: MTGCardIdentifier, count: Int, foil: Bool = false, alter: URL? = nil) {
      self.identifier = identifier
      self.count = count
      self.foil = foil
      self.alter = alter
    }
    
    public var identifier: MTGCardIdentifier
    public var count: Int
    public var foil: Bool
    public var alter: URL?
  }
	
	public static func parse(deckList: String, autofix: Bool) -> [CardGroup] {
		var deckList = deckList.replacingOccurrences(of: "\r", with: "")
		
		var commanderLines: [String] = []
		
		if let range = deckList.range(of: "\n\n") {
			deckList.replaceSubrange(range, with: "\n\nSideboard\n")
		}
		
		var lines: [String] = deckList
			.components(separatedBy: .newlines)
			.compactMap {
				var line = $0
				if line.hasPrefix("//"), let range = line.range(of: "//") {
					line.removeSubrange(range)
				}
				
				let isCommander = line.contains("!Commander")
				
				guard !isCommander else {
					commanderLines.append(line)
					return nil
				}
				
				line = line.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !line.isEmpty else { return nil }
				
				return line
		}
		
		if !commanderLines.isEmpty {
			commanderLines.insert("Commander", at: 0)
			lines.insert(contentsOf: commanderLines, at: 0)
		}
		
		deckList = lines.joined(separator: "\n")
		
		let regex = #"^(?:(?:\/\/)?(\S*)\s*$|\s*(\d+)\s+([^\(\n]+\S)(?:\s*|\s+\(\s*(\S*)\s*\)(?:\h+(\S+)\s*|\s*)))$"#
		
		let matches = deckList.matches(forRegex: regex, options: [.anchorsMatchLines])
		var cardGroups: [CardGroup] = []
		
		for (_, groups) in matches {
			switch groups.count {
			case 1:
				let value = groups[0].value.trimmingCharacters(in: .whitespacesAndNewlines)
				let newGroup = CardGroup(name: CardGroup.name(for: value, defaultToMain: true), cardCounts: [])
				cardGroups.append(newGroup)
			case 2:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
				let name: String = {
					let value = groups[1].value
					if let index = value.lastIndex(of: "#") {
						return String(value.prefix(upTo: index)).trimmingCharacters(in: .whitespacesAndNewlines)
					} else {
						return value
					}
				}()
				guard let number = Int(count) else { continue }
				let cardCount = CardCount(identifier: .name(name), count: number)
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			case 3:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
				let name: String = {
					let value = groups[1].value
					if let index = value.lastIndex(of: "#") {
						return String(value.prefix(upTo: index)).trimmingCharacters(in: .whitespacesAndNewlines)
					} else {
						return value
					}
				}()
				let set = groups[2].value
				
				guard let number = Int(count) else { continue }
				
				if autofix && set.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					let cardCount = CardCount(identifier: .name(name), count: number)
					cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
				} else {
					let cardCount = CardCount(identifier: .nameSet(name: name, set: set), count: number)
					cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
				}
			case 4:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
				let name: String = {
					let value = groups[1].value
					if let index = value.lastIndex(of: "#") {
						return String(value.prefix(upTo: index)).trimmingCharacters(in: .whitespacesAndNewlines)
					} else {
						return value
					}
				}()
				let set = groups[2].value
				let collectorNumber = groups[3].value
				
				guard let number = Int(count) else { continue }
				
				if autofix && set.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					let cardCount = CardCount(identifier: .name(name), count: number)
					cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
				} else {
					let cardCount = CardCount(identifier: .collectorNumberSet(collectorNumber: collectorNumber, set: set, name: name), count: number)
					cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
				}
			default:
				break
			}
		}
		
		// Merge groups with the same names
		cardGroups = cardGroups.reduce([], { partialResult, currentGroup in
			guard !currentGroup.cardCounts.isEmpty else { return partialResult }
			
			var partialResult = partialResult
			
			if let existingGroupIndex = partialResult.firstIndex(where: { $0.name == currentGroup.name }) {
				partialResult[existingGroupIndex].cardCounts.append(contentsOf: currentGroup.cardCounts)
			} else {
				partialResult.append(currentGroup)
			}
			
			return partialResult
		})
		
		return cardGroups
	}
	
  public static func parse(deckstatsDecklist: String, keepOriginalGroups: Bool = false) -> [CardGroup] {
		let regex = #"(?:^\/\/(\S+)$|^([0-9]+) (?:\[(.+)\] (.+)$|(.+)$))|(.+$)"#
		
		var commanderLines: [String] = []
		
		var lines: [String] = deckstatsDecklist
			.components(separatedBy: .newlines)
			.compactMap {
				var line = $0
				if line.hasPrefix("//"), let range = line.range(of: "//") {
					line.removeSubrange(range)
				}
				
				if line.hasPrefix("SB: "), let range = line.range(of: "SB: ") {
					line.removeSubrange(range)
				}
				
				let isCommander = line.contains("!Commander")
				
				guard !isCommander else {
					commanderLines.append(line)
					return nil
				}
				
				line = line.trimmingCharacters(in: .whitespacesAndNewlines)
				guard !line.isEmpty else { return nil }
				
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
        let newGroup = CardGroup(name: keepOriginalGroups ? value : CardGroup.name(for: value, defaultToMain: true), cardCounts: [])
				cardGroups.append(newGroup)
			case 2:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
        let isFoil = groups[1].value.lowercased().contains("!foil")
				var alterURL: URL?
				let name: String = {
					var value = groups[1].value
					if let index = value.firstIndex(of: "<") {
						value.removeSubrange(index...)
						value = value.trimmingCharacters(in: .whitespacesAndNewlines)
					}
					
					if let index = value.lastIndex(of: "#") {
						let commentIndex = value.index(after: index)
						if value.indices.contains(commentIndex) {
							let comment = String(value.suffix(from: commentIndex)).trimmingCharacters(in: .whitespacesAndNewlines)
							let commentComponents = comment.components(separatedBy: .whitespacesAndNewlines)
							alterURL = commentComponents.first(where: {
								guard let url = URL(string: $0), ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased()) else { return false }
								return true
							}).flatMap(URL.init(string:))
						}
						return String(value.prefix(upTo: index)).trimmingCharacters(in: .whitespacesAndNewlines)
					} else {
						return value
					}
				}()
				guard let number = Int(count) else { continue }
        
        var cardCount = CardCount(identifier: .name(name), count: number, foil: isFoil)
				cardCount.alter = alterURL
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			case 3:
				if cardGroups.isEmpty {
					let newGroup = CardGroup(name: cardGroups.isEmpty ? CardGroup.GroupName.deck.rawValue : nil, cardCounts: [])
					cardGroups.append(newGroup)
				}
				
				let count = groups[0].value
        let isFoil = groups[2].value.lowercased().contains("!foil")
				var alterURL: URL?
				let name: String = {
					var value = groups[2].value
					if let index = value.firstIndex(of: "<") {
						value.removeSubrange(index...)
						value = value.trimmingCharacters(in: .whitespacesAndNewlines)
					}
					
					if let index = value.lastIndex(of: "#") {
						let commentIndex = value.index(after: index)
						if value.indices.contains(commentIndex) {
							let comment = String(value.suffix(from: commentIndex)).trimmingCharacters(in: .whitespacesAndNewlines)
							let commentComponents = comment.components(separatedBy: .whitespacesAndNewlines)
							alterURL = commentComponents.first(where: {
								guard let url = URL(string: $0), ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased()) else { return false }
								return true
							}).flatMap(URL.init(string:))
						}
						return String(value.prefix(upTo: index)).trimmingCharacters(in: .whitespacesAndNewlines)
					} else {
						return value
					}
				}()
				
				let setComponents = groups[1].value.components(separatedBy: "#")
				
				let set = setComponents[0]
				
				guard let number = Int(count) else { continue }
				var cardCount: CardCount
				
				if setComponents.count > 1, let collectorNumber = setComponents.last {
          cardCount = CardCount(identifier: .collectorNumberSet(collectorNumber: collectorNumber, set: set, name: name), count: number, foil: isFoil)
				} else {
          cardCount = CardCount(identifier: .nameSet(name: name, set: set), count: number, foil: isFoil)
				}
				
				cardCount.alter = alterURL
				cardGroups[cardGroups.count-1].cardCounts.append(cardCount)
			default:
				break
			}
		}
		
		// Merge groups with the same names
		cardGroups = cardGroups.reduce([], { partialResult, currentGroup in
			guard !currentGroup.cardCounts.isEmpty else { return partialResult }
			
			var partialResult = partialResult
			
			if let existingGroupIndex = partialResult.firstIndex(where: { $0.name == currentGroup.name }) {
				partialResult[existingGroupIndex].cardCounts.append(contentsOf: currentGroup.cardCounts)
			} else {
				partialResult.append(currentGroup)
			}
			
			return partialResult
		})
		
		return cardGroups
	}
	
	public static func parse(moxfieldDeck: MoxfieldDeck) -> [CardGroup] {
		var groups: [CardGroup] = []
		
		let cardInfos = Array(moxfieldDeck.mainboard.values).sorted(by: { $0.card.name < $1.card.name })
		
		let counts: [CardCount] = cardInfos.map(\.cardCount)
		groups.append(CardGroup(name: CardGroup.GroupName.deck.rawValue, cardCounts: counts))
		
		if let commanders = moxfieldDeck.commanders {
			let commanderCardCounts = commanders.values.map(\.cardCount)
			groups.append(CardGroup(name: CardGroup.GroupName.command.rawValue, cardCounts: commanderCardCounts))
		}
		
		if let sideboard = moxfieldDeck.sideboard {
			let counts: [CardCount] = sideboard.values.map(\.cardCount)
			groups.append(CardGroup(name: CardGroup.GroupName.sideboard.rawValue, cardCounts: counts))
		}
		
		return groups
	}
	
	public static func parse(archidektDeck: ArchidektDeck) -> [CardGroup] {
		var groups: [CardGroup] = []
		
		var cards = archidektDeck.cards.sorted { $0.card.oracleCard.name < $1.card.oracleCard.name }
		cards.removeAll { $0.categories.contains("Maybeboard") }
		
		let commanderCards = cards.separateAll { $0.categories.contains("Commander") }
		let sideboardCards = cards.separateAll { $0.categories.contains("Sideboard") }
		
		groups.append(CardGroup(name: CardGroup.GroupName.deck.rawValue, cardCounts: cards.map(\.cardCount)))
		
		if !commanderCards.isEmpty {
			groups.append(CardGroup(name: CardGroup.GroupName.command.rawValue, cardCounts: commanderCards.map(\.cardCount)))
		}
		
		if !sideboardCards.isEmpty {
			groups.append(CardGroup(name: CardGroup.GroupName.sideboard.rawValue, cardCounts: sideboardCards.map(\.cardCount)))
		}
		
		return groups
	}
}

extension Collection {
	func sorted<Value: Comparable>(on property: KeyPath<Element, Value>, by areInIncreasingOrder: (Value, Value) -> Bool) -> [Element] {
		return sorted { currentElement, nextElement in
			areInIncreasingOrder(currentElement[keyPath: property], nextElement[keyPath: property])
		}
	}
	
	func sorted<Value: Comparable>(on property: KeyPath<Element, Value>) -> [Element] {
		return sorted { currentElement, nextElement in
			currentElement[keyPath: property] < nextElement[keyPath: property]
		}
	}
}
