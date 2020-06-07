//
//  BoosterPack.swift
//  Cockatrice to Scryfall
//
//  Created by Josh Birnholz on 3/26/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Vapor)
import Vapor
#endif

typealias ObjectStateJSON = String

enum PackError: Error {
	case wrongNumberOfCards
	case noImage
	case noValidPromo
	case notInBoosters
	case notEnoughLands
	case emptyInput
	case noCards
	case unsupported
	case noName
	case noCardFound(String)
	
	var code: Int {
		switch self {
		case .wrongNumberOfCards:
			return 0
		case .noImage:
			return 1
		case .noValidPromo:
			return 2
		case .notInBoosters:
			return 3
		case .notEnoughLands:
			return 4
		case .noCards:
			return 5
		case .unsupported:
			return 6
		case .noName:
			return 7
		case .noCardFound(_):
			return 8
		case .emptyInput:
			return 9
		}
	}
}

public enum Input: Int, CaseIterable {
	case scryfallSetCode
//		case scryfallSetJSON
	case cockatriceJSON
	case cardlist
	
	var title: String {
		switch self {
		case .cockatriceJSON: return "Cockatrice JSON"
//			case .scryfallSetJSON: return "Scryfall Set JSON"
		case .scryfallSetCode: return "Scryfall Set"
		case .cardlist: return "Deck List"
		}
	}
}

public enum Output: Int, CaseIterable {
	case boosterPack
	case boosterBox
	case prereleaseKit
	case landPack
	
	var title: String {
		switch self {
		case .boosterPack:
			return "Booster Pack"
		case .boosterBox:
			return "Booster Box"
		case .prereleaseKit:
			return "Prerelease Pack"
		case .landPack:
			return "Land Pack"
			//			case .allCards:
			//				return "All Cards"
		}
	}
	
	var prompt: String {
		switch self {
		case .boosterPack:
			return "Generate 1 booster pack."
		case .boosterBox:
			return "Generate a booster box (usually 36 packs)."
		case .prereleaseKit:
			return "Generate a prerelease pack (6 boosters and a promo card)."
		case .landPack:
			return "Generate a pack of basic lands."
			//			case .allCards:
			//				return "Generate a deck with all of the input cards."
		}
	}
	
}

enum Mode {
	/// 1 basic land, 1 rare (or a mythic 1/8 of the time), 3 uncommons, the rest common
	case `default`
	/// Same as default, but gauarantees a planeswalker in every pack
	case warOfTheSpark
	case twoLands
	/// Ensures that between 5 and 10 cards in the back use the future frame.
	case futureSight
	/// 1 basic land, 1 rare, 2 uncommons, 6 commons
	case unglued
	///
	case alliancesChronicles
	/// Like default, but one common slot is replaced by any rarity double-faced card.
	case innistradDoubleFaced
	/// Like default, but one common slot is replaced by a common or uncommon double-faced card. In 1/8 packs, one additional common slot is replaced by a rare/mythic double-faced card.
	case shadowsOverInnistradDoubleFaced
	/// Showcase mutate commons/uncommons show up in 1/3 packs. Showcase rare/mythics show up in 2/29 packs.
	case ikoria
	
	case zendikarExpeditions
	case amonkhetInvocations
	case kaladeshInventions
	
	/// Basic land is replaced with a foil of any rarity, OR, except 1/53 packs, a Power Nine card
	case vintageMasters
}

extension MTGCard {
	func partner<S: Sequence>(from cards: S) -> MTGCard? where S.Element == MTGCard {
		guard let allParts = allParts else { return nil }
		guard oracleText?.lowercased().contains("partner with") == true else { return nil }
		guard let part = allParts.first(where: { $0.component == .comboPiece }) else { return nil }
		return cards.first(where: { $0.scryfallID == part.scryfallID })
	}
	
	var hasPartner: Bool {
		return oracleText?.lowercased().contains("partner with") == true
	}
}

enum FoilPolicy {
	/// Foil cards appear 1 in 67 cards, or 22.5% chance in any one booster pack
	case pre2020
	/// Foil cards appear 1 in 45 cards, or 33.4% chance in any one booster pack
	case modern
	
	/// Foil cards appear in 52/53 booster packs
	case vintageMasters
	
	fileprivate var limit: Int {
		switch self {
		case .pre2020: return 225
		case .modern: return 334
		case .vintageMasters: return 981
		}
	}
}

func generatePack(rarities: [MTGCard.Rarity: [MTGCard]], customSlotRarities: [MTGCard.Rarity: [MTGCard]], basicLands: [MTGCard], tokens: [MTGCard], showcaseRarities: [MTGCard.Rarity: [MTGCard]], extendedArt: [MTGCard], meldResults: [MTGCard], mode: Mode, includeExtendedArt: Bool, masterpieceCards: [MTGCard], foilPolicy: FoilPolicy) -> [MTGCard] {
	var pack: [MTGCard] = []
	
	let guaranteedPlaneswalkerSlot = mode == .warOfTheSpark ? (0...3).randomElement()! : nil
	
	let landRarities: [MTGCard.Rarity: [MTGCard]]? = {
		guard Set(basicLands.map(\.rarity)).count > 1 else {
			return nil
		}
		
		return .init(grouping: basicLands, by: \.rarity)
	}()
	
	enum ShowcaseRarity {
		case random
		case commonUncommon
		case rareMythic
		
		var allowedRarities: Set<MTGCard.Rarity> {
			switch self {
			case .commonUncommon: return [.common, .uncommon]
			case .rareMythic: return [.rare, .mythic]
			case .random: return Set(MTGCard.Rarity.allCases)
			}
		}
	}
	
	let includeMythic = (1...8).randomElement()! == 8
	let includedShowcaseRarity: ShowcaseRarity? = {
		guard !showcaseRarities.values.joined().isEmpty else { return nil }
		
		if mode == .ikoria {
			if (1...29).randomElement()! <= 2 {
				return .rareMythic
			} else if (1...3).randomElement() == 1 {
				return .commonUncommon
			} else {
				return nil
			}
		} else {
			return (1...9).randomElement() == 9 ? .random : nil
		}
	}()
	let shouldIncludeRareMythicDoubleFaced = (1...8).randomElement()! == 8 // for shadowsOverInnistradDoubleFaced mode
	let includeMasterpiece: Bool = {
		guard !masterpieceCards.isEmpty else { return false }
		switch mode {
		case .amonkhetInvocations: return (1...129).randomElement() == 1
		case .kaladeshInventions: return (1...144).randomElement() == 1
		case .zendikarExpeditions: return (1...112).randomElement() == 1
		default: return false
		}
	}()
	let includedFoilRarity: MTGCard.Rarity? = {
		guard (1...1000).randomElement()! <= foilPolicy.limit else { return nil }
		
		let rarityValue = (1...1000).randomElement()!
		switch rarityValue {
		case 1...500: return .common
		case 1...833: return .uncommon
		case 1...979: return .rare
		default: return .mythic
		}
	}()
	
	var uniqueCardCount: Int { Set(pack.compactMap { $0.name }).count }
	var allColorsCount: Int { Set(pack.compactMap { $0.colors }.joined()).count }
	var showcaseOkay: Bool {
		guard let showcaseRarity = includedShowcaseRarity, !showcaseRarities.values.joined().isEmpty else {
			return true
		}
		
		// If the pack should contain a showcase, and there are showcase cards in the set,
		// ensure that the pack actually does contain a showcase card.
		return pack.contains(where: { $0.frameEffects?.contains("showcase") == true && showcaseRarity.allowedRarities.contains($0.rarity) })
	}
	var futureSightOkay: Bool {
		guard mode == .futureSight else { return true }
		let futureCount = pack.reduce(into: 0) { (count, card) in
			if card.frame == "future" {
				count += 1
			}
		}
		return (5...10).contains(futureCount)
	}
	
	let landRarity: MTGCard.Rarity = {
		switch (1...13).randomElement()! {
		case 1:
			if let mythics = landRarities?[.mythic], !mythics.isEmpty, (1...8).randomElement()! == 8 {
				return .mythic
			} else if let rares = landRarities?[.rare], !rares.isEmpty {
				return .rare
			} else {
				fallthrough
			}
		case 2, 3, 4:
			return .uncommon
		default:
			return .common
		}
	}()
	let landCount = mode == .twoLands ? 2 : 1
	
	let cardCount: Int = {
		var nonTokenCount: Int
		
		switch mode {
		case .unglued:
			nonTokenCount = 11
		case .alliancesChronicles:
			nonTokenCount = 14
		default:
			nonTokenCount = 16
		}
		
		if basicLands.isEmpty {
			nonTokenCount -= 1
		}
		
		if tokens.isEmpty {
			nonTokenCount -= 1
		}
		
		if mode == .vintageMasters {
			nonTokenCount += 1
		}
		
		return nonTokenCount
	}()
	
	repeat {
		pack.removeAll()
		
		let lands = landRarities?[landRarity]?.shuffled().prefix(landCount) ?? basicLands.shuffled().prefix(landCount)
		pack.insert(contentsOf: lands, at: 0)
		
		if includeMasterpiece, let masterpiece = masterpieceCards.randomElement() {
			pack.insert(masterpiece, at: 0)
		} /*else if let rarity = includedShowcaseRarity {
			let card: MTGCard? = {
				switch rarity {
				case .random:
					return showcaseRarities.values.joined().randomElement()
				case .commonUncommon:
					return [(showcaseRarities[.common] ?? []), (showcaseRarities[.uncommon] ?? [])].joined().randomElement()
				case .rareMythic:
					return [(showcaseRarities[.rare] ?? []), (showcaseRarities[.mythic] ?? [])].joined().randomElement()
				}
			}()
			if let showcase = card {
				pack.insert(showcase, at: 0)
			}
		} */else if let rarity = includedFoilRarity, let foil = [(rarities[rarity] ?? []), (customSlotRarities[rarity] ?? [])].joined().filter(\.isFoilAvailable).randomElement() {
			if includeExtendedArt, let extendedArtVersion = extendedArt.filter({ $0.name == foil.name }).randomElement() {
				pack.insert(extendedArtVersion, at: 0)
			} else if rarity != .common {
				pack.insert(foil, at: 0)
			}
		} else if mode == .vintageMasters, let powerNine = customSlotRarities.values.joined().randomElement() {
			// Vintage Masters packs that don't contain a foil card instead contain a Power Nine card.
			pack.insert(powerNine, at: 0)
		}
		
		let rareSlotRarities = guaranteedPlaneswalkerSlot == 3 ? customSlotRarities : rarities
		if includeMythic, let mythic = rareSlotRarities[.mythic]?.randomElement() {
			pack.insert(mythic, at: 0)
			
			if mythic.hasPartner, let partner = mythic.partner(from: rarities.values.joined()) {
				pack.insert(partner, at: 0)
			}
		} else if let rare = rareSlotRarities[.rare]?.randomElement() {
			pack.insert(rare, at: 0)
			
			if rare.hasPartner, let partner = rare.partner(from: rarities.values.joined()) {
				pack.insert(partner, at: 0)
			}
		}
		
		let uncommonCount: Int = {
			var base: Int = {
				switch mode {
				case .unglued:
					return 2
				default:
					return 3
				}
			}()
			
			if pack.contains(where: \.hasPartner) {
				base -= 1
			}
			
			return base
		}()
		
//		var uncommons = rarities[.uncommon]?.shuffled().prefix(uncommonCount) ?? []
		var uncommons: [MTGCard] = {
			var uncommons: [MTGCard] = []
			
			while uncommons.count < uncommonCount {
				var card: MTGCard
				
				var cardIsValid: Bool {
					if card.hasPartner && (pack.contains(where: \.hasPartner) || uncommons.contains(where: \.hasPartner)) {
						return false
					}
					return !uncommons.contains(card)
				}
				
				repeat {
					guard let uncommonCard = rarities[.uncommon]?.randomElement() else {
						return []
					}
					card = uncommonCard
				} while !cardIsValid
				
				uncommons.append(card)
				if let partner = card.partner(from: rarities.values.joined()) {
					uncommons.append(partner)
				}
			}
			
			while uncommons.count > uncommonCount {
				guard let index = uncommons.enumerated().compactMap({ $0.element.hasPartner ? nil : $0.offset }).randomElement() else { return [] }
				uncommons.remove(at: index)
			}
			
			return uncommons
		}()
		
		if let slot = guaranteedPlaneswalkerSlot, slot != 3, let uncommonPlaneswalker = customSlotRarities[.uncommon]?.randomElement() {
			uncommons[slot] = uncommonPlaneswalker
		}
		
		pack.insert(contentsOf: uncommons, at: 0)
		
		if mode == .innistradDoubleFaced, let doubleFaced = customSlotRarities.values.joined().randomElement() {
			pack.insert(doubleFaced, at: 0)
		}
		
		if mode == .shadowsOverInnistradDoubleFaced {
			if shouldIncludeRareMythicDoubleFaced {
				let rareOrMythicDoubleFacedCards = (customSlotRarities[.rare] ?? []) + (customSlotRarities[.mythic] ?? [])
				if let doubleFaced = rareOrMythicDoubleFacedCards.randomElement() {
					pack.insert(doubleFaced, at: 0)
				}
			}
			
			let commonOrUncommonDoubleFacedCards = (customSlotRarities[.common] ?? []) + (customSlotRarities[.uncommon] ?? [])
			if let doubleFaced = commonOrUncommonDoubleFacedCards.randomElement() {
				pack.insert(doubleFaced, at: 0)
			}
		}
		
		let commonCount: Int = {
			var count = cardCount-pack.count
			if !tokens.isEmpty {
				count -= 1
			}
			return count
		}()
		let commons = rarities[.common]?.shuffled().prefix(commonCount) ?? []
		pack.insert(contentsOf: commons, at: 0)
		
		// Tokens
		
		func tokensAreEqual(_ first: MTGCard, _ second: MTGCard) -> Bool {
			if first.oracleID == second.oracleID && first.oracleID != nil {
				return true
			}
			if first == second {
				return true
			}
			if first.name == second.name && first.typeLine == second.typeLine && first.colors == second.colors && first.oracleText == second.oracleText && first.power == second.power && first.toughness == second.toughness {
				return true
			}
			
			return false
		}
		
		if !tokens.isEmpty {
			var availableTokens: [MTGCard] = []
			
			let uniqueTokens: [MTGCard] = {
				var uniqueTokens: [MTGCard] = []
				
				for token in tokens {
					if !uniqueTokens.contains(where: { tokensAreEqual(token, $0) }) {
						uniqueTokens.append(token)
					}
				}
				
				return uniqueTokens
			}()
			
			for token in uniqueTokens {
				let cardsToLookAt: [MTGCard] = pack + pack.compactMap { card in
					guard let meldResultRelation = card.allParts?.first(where: { $0.scryfallID != card.scryfallID && $0.component == .meldResult } ),
						let meldResult = meldResults.first(where: { $0.scryfallID == meldResultRelation.scryfallID }) else {
						return nil
					}
					return meldResult
				}
				
				for card in cardsToLookAt {
					if card.allParts?.contains(where: { $0.scryfallID == token.scryfallID }) == true
						|| token.allParts?.contains(where: { $0.scryfallID == card.scryfallID }) == true {
						availableTokens.append(token)
					} /*else if token.name?.lowercased() == "on an adventure" && card.layout == "adventure" {
						availableTokens.append(token)
					} else if token.name?.lowercased() == "the monarch" && card.oracleText?.lowercased().contains("monarch") == true {
						availableTokens.append(token)
					} */else if let name = token.name?.lowercased(), card.oracleText?.contains(name) == true {
						availableTokens.append(token)
					} else if card.allParts?.contains(where: { $0.name == token.name }) == true {
						availableTokens.append(token)
					} else if token.allParts?.contains(where: { $0.name == card.name }) == true {
						availableTokens.append(token)
					}
				}
			}
			
			if availableTokens.isEmpty {
				availableTokens = tokens
			}
			
			if var token = availableTokens.randomElement() {
				token = tokens.shuffled().first(where: { tokensAreEqual(token, $0) })!
				
				// Add a second face to the token.
//				func removeEqualTokens() {
//					availableTokens.removeAll (where: {
//						tokensAreEqual($0, token)
//					})
//				}
//
//				removeEqualTokens()
//
//				if availableTokens.isEmpty {
//					availableTokens = tokens
//					removeEqualTokens()
//				}
//
//				if token.layout != "double_faced_token", var backSide = availableTokens.randomElement() {
//					backSide = tokens.shuffled().first(where: { tokensAreEqual(backSide, $0) })!
//
//					let frontFace = MTGCard.Face(typeLine: token.typeLine,
//												 power: token.power,
//												 toughness: token.toughness,
//												 oracleText: token.oracleText,
//												 flavorText: token.flavorText,
//												 name: token.name,
//												 loyalty: token.loyalty,
//												 manaCost: token.manaCost,
//												 colors: token.colors,
//												 imageUris: token.imageUris)
//					let altface = MTGCard.Face(typeLine: backSide.typeLine,
//											   power: backSide.power,
//											   toughness: backSide.toughness,
//											   oracleText: backSide.oracleText,
//											   flavorText: backSide.flavorText,
//											   name: backSide.name,
//											   loyalty: backSide.loyalty,
//											   manaCost: backSide.manaCost,
//											   colors: backSide.colors,
//											   imageUris: backSide.imageUris)
//					if var faces = token.cardFaces {
//						faces.append(altface)
//						token.cardFaces = faces
//					} else {
//						token.cardFaces = [frontFace, altface]
//					}
//					token.layout = "double_faced_token"
//				}
				
				pack.append(token)
			}
		}
		
		if let includedShowcaseRarity = includedShowcaseRarity {
			let showcaseCards: [(Int, MTGCard)] = pack.filter({ $0.frameEffects?.contains("extendedart") != true }).enumerated().compactMap { (index, card) in
				guard let showcaseCard = includedShowcaseRarity.allowedRarities.compactMap({ showcaseRarities[$0] }).joined().filter({ $0.name == card.name }).randomElement() else { return nil }

				guard includedShowcaseRarity.allowedRarities.contains(showcaseCard.rarity) else {
					return nil
				}

				return (index, showcaseCard)
			}

			if let (index, showcaseCard) = showcaseCards.randomElement() {
				pack[index] = showcaseCard
			}
		}
		
//		if includeExendedArt && !extendedArt.isEmpty {
//			let extendedArtCards: [(Int, MTGCard)] = pack.enumerated().compactMap { (index, card) in
//				guard let extendedArtCard = extendedArt.filter({ $0.name == card.name }).randomElement() else { return nil }
//				return (index, extendedArtCard)
//			}
//
//			if let (index, extendedArtCard) = extendedArtCards.randomElement() {
//				pack[index] = extendedArtCard
//			}
//		}
		
		var problems: [String] = []
		
		if allColorsCount != 5 {
			problems.append("Pack doesn't have 5 colors")
		}
		if uniqueCardCount != cardCount {
			problems.append("Card count is wrong; Should be \(cardCount), was \(uniqueCardCount)")
		}
		if !futureSightOkay {
			problems.append("Future sight isn't satisfied")
		}
		if !showcaseOkay {
			problems.append("No showcase card")
		}
		
		print(problems.joined(separator: ", "))
		
	} while allColorsCount != 5 || uniqueCardCount != cardCount || !futureSightOkay || !showcaseOkay
	
	print("Using pack")
	
	return pack
}

enum MysterBoosterSlot: Hashable, Equatable {
	case monocolorCommonUncommon(MTGColor)
	case multicolorCommonUncommon
	case artifactLandCommonUncommon
	case preM15card
	case m15RareMythic
	case playtest
	case foil
}

func processMysteryBoosterCards(_ cards: [MTGCard]) -> [MysterBoosterSlot: [MTGCard]] {
	let additionalMainCards: [MTGCard] = {
		do {
			switch cards.first?.set.lowercased() {
			case "cmb1", "fmb1":
				// Add main mystery booster cards to convention/store set.
				return try Swiftfall.getSet(code: "mb1").getCards().compactMap { $0?.data }.joined().compactMap(MTGCard.init)
			case "mb1":
				// Add foils to normal mystery booster set.
				return try Swiftfall.getSet(code: "fmb1").getCards().compactMap { $0?.data }.joined().compactMap(MTGCard.init)
			default:
				return []
			}
		} catch {
			return []
		}
	}()
	
	let cards = cards + additionalMainCards
	
	return .init(grouping: cards) { card in
		if card.set == "cmb1" {
			return .playtest
		}
		
		if card.set == "fmb1" {
			return .foil
		}
		
		guard card.frame == "2015" else {
			return .preM15card
		}
		
		if (card.typeLine?.lowercased().contains("land") == true || card.typeLine?.lowercased().contains("artifact") == true) && (card.rarity == .common || card.rarity == .uncommon) {
			return .artifactLandCommonUncommon
		}
		
		if card.rarity == .rare || card.rarity == .mythic {
			return .m15RareMythic
		}
		
		// cards past here are 2015 frame and common/uncommon, and not lands or artifacts
		
		guard let colors = card.colors, colors.count == 1, let color = colors.first, color.rawValue.count == 1 else {
			return .multicolorCommonUncommon
		}
		
		return .monocolorCommonUncommon(color)
	}
}

func generateMysteryBooster(cards: [MysterBoosterSlot: [MTGCard]]) -> [MTGCard] {
	var pack: [MTGCard] = []
	
	var uniqueCardCount: Int { Set(pack.compactMap { $0.name }).count }
	var allColorsCount: Int { Set(pack.compactMap { $0.colors }.joined()).count }
	
	repeat {
		pack.removeAll()
		
		for color: MTGColor in [.white, .blue, .black, .red, .green] {
			let colorCommonUncommons = cards[.monocolorCommonUncommon(color)]?.shuffled().prefix(2) ?? []
			pack.append(contentsOf: colorCommonUncommons)
		}
		
		if let multicolorCommonUncommon = cards[.multicolorCommonUncommon]?.randomElement() {
			pack.append(multicolorCommonUncommon)
		}
		
		if let artifactLandCommonUncommon = cards[.artifactLandCommonUncommon]?.randomElement() {
			pack.append(artifactLandCommonUncommon)
		}
		
		if let preM15 = cards[.preM15card]?.randomElement() {
			pack.append(preM15)
		}
		
		if let m15RareMythic = cards[.m15RareMythic]?.randomElement() {
			pack.append(m15RareMythic)
		}
		
		if let playtestCard = cards[.playtest]?.randomElement() {
			pack.append(playtestCard)
		} else if let foil = cards[.foil]?.randomElement() {
			pack.append(foil)
		}
	} while allColorsCount != 5 || uniqueCardCount != 15
	
	
	return pack
}

func processPlanarChaosCards(cards: [MTGCard]) -> (normalRarities: [MTGCard.Rarity: [MTGCard]], colorshiftedRarities: [MTGCard.Rarity: [MTGCard]]) {
	var colorshifted: [MTGCard] = []
	var normal: [MTGCard] = []
	
	for card in cards {
		if card.frameEffects?.contains("colorshifted") == true {
			colorshifted.append(card)
		} else {
			normal.append(card)
		}
	}
	
	return (.init(grouping: normal, by: \.rarity), .init(grouping: colorshifted, by: \.rarity))
}

func generatePlanarChaosPack(normalRarities: [MTGCard.Rarity: [MTGCard]], colorshiftedRarities: [MTGCard.Rarity: [MTGCard]]) -> [MTGCard] {
	var pack: [MTGCard] = []
	
	var uniqueCardCount: Int { Set(pack.compactMap { $0.name }).count }
	var allColorsCount: Int { Set(pack.compactMap { $0.colors }.joined()).count }
	
	repeat {
		pack.removeAll()
		
		if let commons = normalRarities[.common]?.shuffled().prefix(8) {
			pack.append(contentsOf: commons)
		}
		
		if let uncommons = normalRarities[.uncommon]?.shuffled().prefix(2) {
			pack.append(contentsOf: uncommons)
		}
		
		if let rare = normalRarities[.rare]?.randomElement() {
			pack.append(rare)
		}
		
		if let colorshiftedCommons = colorshiftedRarities[.common]?.shuffled().prefix(3) {
			pack.append(contentsOf: colorshiftedCommons)
		}
		
		if let colorshiftedUncommons = colorshiftedRarities[.uncommon], let colorshiftedRares = colorshiftedRarities[.rare] {
			let all = colorshiftedUncommons + colorshiftedRares
			if let colorshiftedUncommonOrRare = all.shuffled().randomElement() {
				pack.append(colorshiftedUncommonOrRare)
			}
		}
	} while allColorsCount != 5 || uniqueCardCount != 15
	
	return pack
}

fileprivate struct CardInfo {
	private static let defaultBack = URL(string: "https://img.scryfall.com/card_backs/image/normal/0a/0aeebaf5-8c7d-4636-9e82-8c27447861f7.jpg")!
	private static let tokenBack = URL(string: "http://josh.birnholz.com/tts/tback.jpg")!
	
	var faceURL: URL
	var backURL: URL
	var nickname: String
	var description: String
	
	var backIsHidden: Bool
	var sideways: Bool
	
	var num: Int
	/// The num, * 100
	var id: Int { num * 100 }

	var facedown: Bool = true
	
	private var transform: String {
		if facedown {
			return """
			"Transform": {
			  "posX": 0.5254047,
			  "posY": 1.21068287,
			  "posZ": 0.19025977,
			  "rotX": -0.0008576067,
			  "rotY": 180.000061,
			  "rotZ": 179.9986,
			  "scaleX": 1.0,
			  "scaleY": 1.0,
			  "scaleZ": 1.0
			}
			"""
		} else {
			return """
			"Transform": {
			  "posX": 0.1779872,
			  "posY": 3.08887124,
			  "posZ": 0.29411754,
			  "rotX": 358.469971,
			  "rotY": 179.966263,
			  "rotZ": 1.77417183,
			  "scaleX": 1.0,
			  "scaleY": 1.0,
			  "scaleZ": 1.0
			}
			"""
		}
	}
	
	var customDeck: String {
		return """
		{
		  "FaceURL": "\(faceURL)",
		  "BackURL": "\(backURL)",
		  "NumWidth": 1,
		  "NumHeight": 1,
		  "BackIsHidden": \(backIsHidden),
		  "UniqueBack": false
		}
		"""
	}
	
	fileprivate var cardCustomObject: String {
		return """
		{
		  "Name": "CardCustom",
		  \(transform),
		  "Nickname": "\(nickname)",
		  "Description": "\(description)",
		  "GMNotes": "",
		  "ColorDiffuse": {
			"r": 0.713235259,
			"g": 0.713235259,
			"b": 0.713235259
		  },
		  "Locked": false,
		  "Grid": true,
		  "Snap": true,
		  "IgnoreFoW": false,
		  "Autoraise": true,
		  "Sticky": true,
		  "Tooltip": true,
		  "GridProjection": false,
		  "HideWhenFaceDown": \(backIsHidden),
		  "Hands": true,
		  "CardID": \(id),
		  "SidewaysCard": \(sideways),
		  "CustomDeck": {
			"\(num)": \(customDeck)
		  },
		  "XmlUI": "",
		  "LuaScript": "",
		  "LuaScriptState": "",
		  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"\(altFaceCustomObject)
		}
		"""
	}
	
	fileprivate var numToCustomDeck: String {
		return """
		"\(num)": \(customDeck)
		"""
	}
	
	private init(faceURL: URL, backURL: URL = Self.defaultBack, nickname: String, description: String, sideways: Bool = false, backIsHidden: Bool = true) {
		self.faceURL = faceURL
		self.nickname = nickname
		self.description = description
		self.num = 13
		self.otherStates = []
		self.state = 1
		self.backURL = backURL
		self.sideways = sideways
		self.backIsHidden = backIsHidden
	}
	
	private var otherStates: [CardInfo]
	
	/// The 1-indexed value for which state is being shown. This only has a use if `otherStates` is not empty, and there should not be a value in `otherStates` with a `state` value matching this one.
	private var state: Int
	
	private var altFaceCustomObject: String {
		guard !otherStates.isEmpty else { return "" }
		
		let customObjects = otherStates.map { object in
			"\"\(object.state)\": \(object.cardCustomObject)"
		}
		
		let altFaceCustomObject = """
		,\n"States": {
			\(customObjects.joined(separator: ",\n"))
		}
		"""
		return altFaceCustomObject
	}
	
	// Uses the given number
	init?(num: Int, card: MTGCard) {
		if card.layout == "transform", let faces = card.cardFaces, faces.count == 2,
			let front = faces[0].imageUris?["normal"] ?? faces[0].imageUris?["large"],
			let back = faces[1].imageUris?["normal"] ?? faces[1].imageUris?["large"] {
			let frontName = faces[0].name ?? ""
			let backName = faces[1].name ?? ""
			
			self.faceURL = front
			self.backURL = Self.defaultBack
			self.nickname = frontName
			self.description = "// \(backName)"
			
			var backState = CardInfo(faceURL: back, backURL: front, nickname: backName, description: "// \(frontName)", sideways: false)
			backState.state = 2
			otherStates = [backState]
			self.state = 1
			self.sideways = false
			
			self.backIsHidden = true
		} else if card.layout == "meld", let faceURL = card.imageUris?["normal"] ?? card.imageUris?["large"], let result = card.allParts?.first(where: { $0.name != card.name && $0.component == .meldResult }), let backURL = URL(string: "https://img.scryfall.com/card_backs/image/normal/\(card.scryfallCardBackID.uuidString.lowercased().prefix(2))/\(card.scryfallCardBackID.uuidString.lowercased()).jpg") {
			let frontName = card.name ?? ""
			let backName = result.name
			
			self.backURL = Self.defaultBack
			self.nickname = frontName
			self.backIsHidden = true
			self.faceURL = faceURL
			self.description = "// \(backName)"
			self.sideways = false
			
			var backState = CardInfo(faceURL: backURL, backURL: faceURL, nickname: backName, description: "// \(frontName)", sideways: true, backIsHidden: true)
			backState.state = 2
			self.otherStates = [backState]
			self.state = 1
			
		} else if let faceURL = card.imageUris?["normal"] ?? card.imageUris?["large"] {
			self.faceURL = faceURL
			if card.layout == "double_faced_token", let faces = card.cardFaces, faces.count >= 2, let backFaceURL = faces[1].imageUris?["normal"] ?? faces[1].imageUris?["large"] {
				self.backURL = backFaceURL
				self.nickname = ""
			} else {
				self.backURL = Self.defaultBack
				self.nickname = card.printedName ?? card.name ?? ""
				self.backIsHidden = true
			}
			self.description = ""
			self.otherStates = []
			self.state = 1
			self.backIsHidden = !(card.layout.contains("token") || card.layout == "emblem")
			
			self.sideways = card.layout == "split" && (card.set != "cmb1" && (card.oracleText?.lowercased().contains("aftermath") == false))
		} else {
			return nil
		}
		
		self.num = num
	}
	
	/// frontState should be contained in allStates.
	init?(offset: Int, currentState: MTGCard, allStates: [MTGCard]) {
		var allStates = allStates.sorted(by: { ($0.name ?? "") < ($1.name ?? "") })
		
		guard let currentStateIndex = allStates.firstIndex(of: currentState) else { return nil }
		
		// fix names
		allStates = allStates.map { card in
			enum Difference {
				case powerToughness
				case color
				case oracle
			}
			var differences: [Difference] = []
			for otherCard in allStates where otherCard.name == card.name && otherCard != card {
				if otherCard.power != card.power || otherCard.toughness != card.toughness {
					differences.append(.powerToughness)
				}
				if otherCard.colors != card.colors {
					differences.append(.color)
				}
				if otherCard.oracleText != card.oracleText {
					differences.append(.oracle)
				}
			}
			
			if differences.isEmpty {
				return card
			} else {
				var nameParts: [String] = []
				
				if let power = card.power, let toughness = card.toughness {
					let pt = [power, toughness].joined(separator: "/")
					nameParts.append(pt)
				}
				
				if let colors = card.colors {
					let colors = colors.map { $0.name.capitalized }.sorted().joined(separator: "/")
					nameParts.append(colors)
				}
				
				nameParts.append(card.name ?? "")
				
				if differences.contains(.oracle) {
					// Do nothing. future: maybe put "(1)" or something.
				}
				
				var newCard = card
				newCard.name = nameParts.joined(separator: " ")
				return newCard
			}
		}
		
		self.init(offset: offset, card: currentState)
		
		self.state = currentStateIndex + 1
		self.backURL = Self.tokenBack
		
		self.otherStates = allStates.enumerated().compactMap(CardInfo.init(offset:card:)).enumerated().compactMap { index, otherStateCardInfo in
			guard index != currentStateIndex else { return nil }
			var other = otherStateCardInfo
			other.state = index + 1
			other.backURL = Self.tokenBack
			return other
		}
		
	}
	
	// Uses the given number plus one
	init?(offset: Int, card: MTGCard) {
		self.init(num: offset+1, card: card)
	}
	
}

fileprivate var packTexturesExist: [String: Bool] = [:]

func singleCompleteToken(tokens: [MTGCard], export: Bool) throws -> ObjectStateJSON {
	guard !tokens.isEmpty, let first = tokens.first, let cardInfo = CardInfo(offset: 0, currentState: first, allStates: tokens) else { throw PackError.noCards }
	
	if !export {
		return cardInfo.cardCustomObject
	}
	
	return """
	{
	  "SaveName": "",
	  "GameMode": "",
	  "Gravity": 0.5,
	  "PlayArea": 0.5,
	  "Date": "",
	  "Table": "",
	  "Sky": "",
	  "Note": "",
	  "Rules": "",
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "ObjectStates": [
		\(cardInfo.cardCustomObject)
	  ],
	  "TabStates": {},
	  "VersionNumber": ""
	}
	"""
}

/// Put commons into the array first (index 0) and rares last. Then the basic land after the rares.
func boosterPackJSON(setName: String, setCode: String, name: String? = nil, cards: [MTGCard], tokens: [MTGCard] = [], inPack: Bool = true, cardBack: URL? = nil) throws -> ObjectStateJSON {
	
//	let cardInfo = Array(cards.enumerated().compactMap(CardInfo.init(offset:card:)))
	let cardInfo: [CardInfo] = cards.reversed().enumerated().compactMap { sequence in
		if (sequence.element.layout == "token" || sequence.element.layout == "emblem") && !tokens.isEmpty {
			return CardInfo(offset: sequence.offset, currentState: sequence.element, allStates: tokens)
		} else {
			var cardInfo = CardInfo(offset: sequence.offset, card: sequence.element)
			if let back = cardBack {
				cardInfo?.backURL = back
			}
			return cardInfo
		}
	}
//	guard cardInfo.count == 15 || cardInfo.count == 16 else { throw PackError.wrongNumberOfCards }
	let packName = name ?? ""
	
	let deck = """
	{
	"Name": "Deck",
	  "Transform": {
		"posX": 0.1779872,
		"posY": 3.08887124,
		"posZ": 0.29411754,
		"rotX": 358.469971,
		"rotY": 179.966263,
		"rotZ": 1.77417183,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "\(!inPack ? packName : "")",
	  "Description": "",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 0.713235259,
		"g": 0.713235259,
		"b": 0.713235259
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": true,
	  "Hands": false,
	  "SidewaysCard": false,
	  "DeckIDs": \(cardInfo.map(\.id)),
	  "CustomDeck": {
		\(cardInfo.map(\.numToCustomDeck).joined(separator: ",\n"))
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "ContainedObjects": [
		\(cardInfo.map(\.cardCustomObject).joined(separator: ",\n"))
	  ],
	  "GUID": "416ecf"
	}
	"""
	
	if !inPack {
		return deck
	}
	
	var packTextureURL = URL(string: "http://josh.birnholz.com/tts/resources/pack/\(setCode).jpg")!
	let exists = packTexturesExist[setCode] ?? fileExists(at: packTextureURL)
	packTexturesExist[setCode] = exists
	if !exists {
		print("No pack texture for \(setCode), using default")
		packTextureURL = URL(string: "http://josh.birnholz.com/tts/resources/pack/default.jpg")!
	} else {
		print("Found pack texture for \(setCode)")
	}
	
	let bagLuaScript = """
	function onObjectLeaveContainer(bag, object)
	  if (bag.getGUID() == self.getGUID()) then
	    destroyObject(bag)
	  end
	end

	function filterObjectEnter(object)
	  return false
	end
	""".replacingOccurrences(of: "\n", with: "\\n")
	
	let pack = """
	{
	  "Name": "Custom_Model_Bag",
	  "Transform": {
		"posX": -5.75182,
		"posY": 0.960000038,
		"posZ": 1.48507118,
		"rotX": -3.88456328E-07,
		"rotY": 179.672028,
		"rotZ": -3.12079976E-07,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "\(name ?? "\(setName) Booster Pack")",
	  "Description": "",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "MaterialIndex": -1,
	  "MeshIndex": -1,
	  "CustomMesh": {
	  "MeshURL": "http://josh.birnholz.com/tts/resources/pack/MagicPack_\(Bool.random() ? 1 : 2).obj",
		"DiffuseURL": "\(packTextureURL)",
		"NormalURL": "http://josh.birnholz.com/tts/resources/pack/NormalMap_CardPack.png",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 0,
		"TypeIndex": 6,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.5,
		  "SpecularSharpness": 3.93060017,
		  "FresnelStrength": 0.8772789
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "\(bagLuaScript)",
	  "LuaScriptState": "",
	  "ContainedObjects": [
		\(deck)
	  ],
	  "GUID": "d944ee"
	}
	"""
	
	// function onObjectLeaveContainer(bag, object)\n    if (bag.getGUID() == self.getGUID()) then\n        destroyObject(bag)\n    end\nend
	
	return pack
}

func singleBoosterPack(setName: String, setCode: String, boosterPack: [MTGCard], tokens: [MTGCard], inPack: Bool? = nil, export: Bool, cardBack: URL? = nil) throws -> String {
	let boosterPackString: String
	
	if let inPack = inPack {
		boosterPackString = try boosterPackJSON(setName: setName, setCode: setCode, cards: boosterPack, tokens: tokens, inPack: inPack, cardBack: cardBack)
	} else {
		boosterPackString = try boosterPackJSON(setName: setName, setCode: setCode, cards: boosterPack, tokens: tokens, cardBack: cardBack)
	}
	
	if !export {
		return boosterPackString
	}
	
	return """
	{
	  "SaveName": "",
	  "GameMode": "",
	  "Gravity": 0.5,
	  "PlayArea": 0.5,
	  "Date": "",
	  "Table": "",
	  "Sky": "",
	  "Note": "",
	  "Rules": "",
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "ObjectStates": [
		\(boosterPackString)
	  ],
	  "TabStates": {},
	  "VersionNumber": ""
	}
"""
}

func singleCardFuzzy(name: String, facedown: Bool, export: Bool) throws -> String {
	let card = try Swiftfall.getCard(fuzzy: name)
	let mtgCard = MTGCard(card)
	return try singleCard(mtgCard, facedown: facedown, export: export)
}

func singleCardExact(name: String, facedown: Bool, export: Bool) throws -> String {
	let card = try Swiftfall.getCard(exact: name)
	let mtgCard = MTGCard(card)
	return try singleCard(mtgCard, facedown: facedown, export: export)
}

func singleCardCodeNumber(code: String, number: String, facedown: Bool, export: Bool) throws -> String {
	let card = try Swiftfall.getCard(code: code, number: number)
	let mtgCard = MTGCard(card)
	return try singleCard(mtgCard, facedown: facedown, export: export)
}

func singleCardRand(facedown: Bool, export: Bool) throws -> String {
	let card = try Swiftfall.getRandomCard()
	let mtgCard = MTGCard(card)
	return try singleCard(mtgCard, facedown: facedown, export: export)
}

func singleCardScryfallQuery(query: String, facedown: Bool, export: Bool) throws -> String {
	guard let card = Swiftfall.getCards(query: query).compactMap({ $0?.data }).joined().randomElement() else {
		throw PackError.noCards
	}
	let mtgCard = MTGCard(card)
	return try singleCard(mtgCard, facedown: facedown, export: export)
}

func singleCard(_ card: MTGCard, tokens: [MTGCard] = [], facedown: Bool = true, export: Bool = false) throws -> String {
//	let cardInfo: [CardInfo] = cards.reversed().enumerated().compactMap { sequence in
//		if (sequence.element.layout == "token" || sequence.element.layout == "emblem") && !tokens.isEmpty {
//			return CardInfo(offset: sequence.offset, currentState: sequence.element, allStates: tokens)
//		} else {
//			var cardInfo = CardInfo(offset: sequence.offset, card: sequence.element)
//			if let back = cardBack {
//				cardInfo?.backURL = back
//			}
//			return cardInfo
//		}
//	}
	
	let info: CardInfo?
	if card.layout == "token" || card.layout == "emblem" && !tokens.isEmpty {
		info = CardInfo(offset: 1, currentState: card, allStates: tokens)
	} else {
		info = CardInfo(num: 1, card: card)
	}
	
	guard var cardInfo = info else { throw PackError.noImage }
	cardInfo.facedown = facedown
	
	if !export {
		return cardInfo.cardCustomObject
	}
	
	return """
	{
	  "SaveName": "",
	  "GameMode": "",
	  "Gravity": 0.5,
	  "PlayArea": 0.5,
	  "Date": "",
	  "Table": "",
	  "Sky": "",
	  "Note": "",
	  "Rules": "",
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "ObjectStates": [
		\(cardInfo.cardCustomObject)
	  ],
	  "TabStates": {},
	  "VersionNumber": ""
	}
	"""
}

func allTokensForSet(setCode: String) throws -> [MTGCard] {
	let set: Swiftfall.ScryfallSet
	do {
		set = try Swiftfall.getSet(code: "t\(setCode)")
	} catch {
		set = try Swiftfall.getSet(code: setCode)
	}
	
	let cards = set.getCards().compactMap { $0?.data }.joined().compactMap(MTGCard.init).sorted { ($0.name ?? "") < ($1.name ?? "") }
	
	guard !cards.isEmpty else {
		throw PackError.noCards
	}
	
	return cards
}

func boosterBag(setName: String, setCode: String, boosterPacks: [[MTGCard]], names: [String?]? = nil, tokens: [MTGCard], inPack: Bool = true, export: Bool, cardBack: URL? = nil) throws -> String {
	
	let names: [String?] = names ?? Array(repeating: String?.none, count: boosterPacks.count)
	let packs = zip(boosterPacks, names)
	let boosterPackString = try packs.map { cards, name in
		if cards.count == 1, let card = cards.first {
			return try singleCard(card, tokens: tokens, facedown: false, export: false)
		} else {
			return try boosterPackJSON(setName: setName, setCode: setCode, name: name, cards: cards, tokens: tokens, inPack: inPack, cardBack: cardBack)
		}
	}.joined(separator: ",\n")
	
	let objectState = """
	{
	  "Name": "Bag",
	  "Transform": {
		"posX": 0.0611134768,
		"posY": 0.7749667,
		"posZ": -0.376334637,
		"rotX": 2.406074E-05,
		"rotY": 2.67337819E-05,
		"rotZ": -7.517204E-06,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "\(setName)",
	  "Description": "",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 0.7058823,
		"g": 0.366520882,
		"b": 0.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "MaterialIndex": -1,
	  "MeshIndex": -1,
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "ContainedObjects": [
		\(boosterPackString)
	  ],
	  "GUID": "929456"
	}
	"""
	
	if !export {
		return objectState
	}
	
	return """
	{
	  "SaveName": "",
	  "GameMode": "",
	  "Gravity": 0.5,
	  "PlayArea": 0.5,
	  "Date": "",
	  "Table": "",
	  "Sky": "",
	  "Note": "",
	  "Rules": "",
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "ObjectStates": [
		\(objectState)
	  ],
	  "TabStates": {},
	  "VersionNumber": ""
	}
"""
}

func checkIfFileExists(at url: URL, timeout: TimeInterval = 1.0, completion: @escaping (Bool) -> Void) {
	var request = URLRequest(url: url)
	request.httpMethod = "HEAD"
	request.timeoutInterval = timeout

	let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
		if let httpResp: HTTPURLResponse = response as? HTTPURLResponse {
			completion(httpResp.statusCode == 200)
		}
	})

	task.resume()
}

fileprivate var fileExists: [URL: Bool] = [:]

func fileExists(at url: URL, timeout: TimeInterval = 1.0) -> Bool {
	if let exists = fileExists[url] {
		return exists
	}
	
	var result = false
	let semaphore = DispatchSemaphore(value: 0)
	checkIfFileExists(at: url, timeout: timeout) { (exists) in
		result = exists
		fileExists[url] = exists
		semaphore.signal()
	}
	semaphore.wait()
	return result
}

func spindownDieJSON(setCode: String) -> String {
	func checkIfFileExists(at url: URL, timeout: TimeInterval = 1.0, completion: @escaping (Bool) -> Void) {
		var request = URLRequest(url: url)
		request.httpMethod = "HEAD"
		request.timeoutInterval = timeout

		let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
			if let httpResp: HTTPURLResponse = response as? HTTPURLResponse {
				completion(httpResp.statusCode == 200)
			}
		})

		task.resume()
	}
	
	func spindownURL(for setCode: String = "default") -> URL {
		return URL(string: "http://josh.birnholz.com/tts/resources/spindowns/\(setCode).jpg")!
	}
	
	var spindownTextureURL = spindownURL(for: setCode)
	
	if !fileExists(at: spindownTextureURL) {
		print("Spindown die doesn't exist for \(setCode), using default")
		spindownTextureURL = spindownURL()
	} else {
		print("Found spindown die for \(setCode)")
	}
	
	return """
	{
	  "Name": "Custom_Dice",
	  "Transform": {
		"posX": 0.008555034,
		"posY": 1.69137132,
		"posZ": -3.544787,
		"rotX": 10.8124132,
		"rotY": 123.675209,
		"rotZ": 198.000076,
		"scaleX": 1.6499995,
		"scaleY": 1.6499995,
		"scaleZ": 1.6499995
	  },
	  "Nickname": "",
	  "Description": "",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomImage": {
		"ImageURL": "\(spindownTextureURL)",
		"ImageSecondaryURL": "",
		"ImageScalar": 1.0,
		"WidthScale": 0.0,
		"CustomDice": {
		  "Type": 5
		}
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "563957",
	  "RotationValues": [
		{
		  "Value": "1",
		  "Rotation": {
			"x": 349.0,
			"y": 61.0,
			"z": 18.0
		  }
		},
		{
		  "Value": "2",
		  "Rotation": {
			"x": 307.0,
			"y": 120.0,
			"z": 19.0
		  }
		},
		{
		  "Value": "3",
		  "Rotation": {
			"x": 307.0,
			"y": 242.0,
			"z": 305.0
		  }
		},
		{
		  "Value": "4",
		  "Rotation": {
			"x": 349.0,
			"y": 302.0,
			"z": 306.0
		  }
		},
		{
		  "Value": "5",
		  "Rotation": {
			"x": 11.0,
			"y": 2.0,
			"z": 342.0
		  }
		},
		{
		  "Value": "6",
		  "Rotation": {
			"x": 53.0,
			"y": 183.0,
			"z": 344.0
		  }
		},
		{
		  "Value": "7",
		  "Rotation": {
			"x": 53.0,
			"y": 61.0,
			"z": 54.0
		  }
		},
		{
		  "Value": "8",
		  "Rotation": {
			"x": 11.0,
			"y": 239.0,
			"z": 54.0
		  }
		},
		{
		  "Value": "9",
		  "Rotation": {
			"x": 350.0,
			"y": 60.0,
			"z": 89.0
		  }
		},
		{
		  "Value": "10",
		  "Rotation": {
			"x": 308.0,
			"y": 242.0,
			"z": 90.0
		  }
		},
		{
		  "Value": "11",
		  "Rotation": {
			"x": 307.0,
			"y": 359.0,
			"z": 164.0
		  }
		},
		{
		  "Value": "12",
		  "Rotation": {
			"x": 307.0,
			"y": 122.0,
			"z": 232.0
		  }
		},
		{
		  "Value": "13",
		  "Rotation": {
			"x": 349.0,
			"y": 297.0,
			"z": 234.0
		  }
		},
		{
		  "Value": "14",
		  "Rotation": {
			"x": 12.0,
			"y": 121.0,
			"z": 270.0
		  }
		},
		{
		  "Value": "15",
		  "Rotation": {
			"x": 53.0,
			"y": 301.0,
			"z": 270.0
		  }
		},
		{
		  "Value": "16",
		  "Rotation": {
			"x": 53.0,
			"y": 59.0,
			"z": 198.0
		  }
		},
		{
		  "Value": "17",
		  "Rotation": {
			"x": 52.0,
			"y": 300.0,
			"z": 126.0
		  }
		},
		{
		  "Value": "18",
		  "Rotation": {
			"x": 11.0,
			"y": 241.0,
			"z": 126.0
		  }
		},
		{
		  "Value": "19",
		  "Rotation": {
			"x": 350.0,
			"y": 182.0,
			"z": 163.0
		  }
		},
		{
		  "Value": "20",
		  "Rotation": {
			"x": 10.0,
			"y": 123.0,
			"z": 197.0
		  }
		}
	  ]
	}
	"""
}

fileprivate let ikoKeywordCounters = """
{
  "Name": "Bag",
  "Transform": {
	"posX": -6.777817,
	"posY": 0.8443537,
	"posZ": -7.817539,
	"rotX": 1.56413319E-06,
	"rotY": -0.0008121254,
	"rotZ": -9.338259E-07,
	"scaleX": 0.625000358,
	"scaleY": 0.625000358,
	"scaleZ": 0.625000358
  },
  "Nickname": "Keyword Counters",
  "Description": "",
  "GMNotes": "",
  "ColorDiffuse": {
	"r": 0.948306859,
	"g": 0.201321363,
	"b": 0.04890474
  },
  "Locked": false,
  "Grid": true,
  "Snap": true,
  "IgnoreFoW": false,
  "Autoraise": true,
  "Sticky": true,
  "Tooltip": true,
  "GridProjection": false,
  "HideWhenFaceDown": false,
  "Hands": false,
  "MaterialIndex": -1,
  "MeshIndex": -1,
  "XmlUI": "",
  "LuaScript": "",
  "LuaScriptState": "",
  "ContainedObjects": [
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -6.219716,
		"posY": 2.22268486,
		"posZ": -7.994092,
		"rotX": 2.18798184,
		"rotY": 180.177811,
		"rotZ": 9.11981,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Vigilance",
	  "Description": "Attacking doesn't cause this creature to tap.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/vigilance.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "04dcaa"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -5.919861,
		"posY": 2.18360448,
		"posZ": -8.129306,
		"rotX": 3.16053081,
		"rotY": 180.23822,
		"rotZ": 7.62483931,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Trample",
	  "Description": "This creature can deal excess combat damage to player or planeswalker it's attacking.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/trample.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "e8275c"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -6.53923225,
		"posY": 2.228614,
		"posZ": -7.86438465,
		"rotX": 355.2326,
		"rotY": 180.320038,
		"rotZ": 352.409119,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Reach",
	  "Description": "This creature can block creatures with flying.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/reach.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "dcefa9"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -5.94240475,
		"posY": 2.18941116,
		"posZ": -8.024761,
		"rotX": 1.42003739,
		"rotY": 180.110123,
		"rotZ": 8.204921,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Menace",
	  "Description": "This creature can't be blocked except by two or more creatures.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/menace.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "f40ae8"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -6.09961033,
		"posY": 2.195459,
		"posZ": -8.1168,
		"rotX": 4.54916954,
		"rotY": 180.321609,
		"rotZ": 8.30754852,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Lifelink",
	  "Description": "Damage dealt by this creature also causes you to gain that much life.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/lifelink.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "7f0537"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -6.562606,
		"posY": 2.19606638,
		"posZ": -8.264934,
		"rotX": 8.308485,
		"rotY": 179.699814,
		"rotZ": 355.7851,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Hexproof",
	  "Description": "This permanent can't be the target of spells or abilities your opponents control.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/hexproof.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "986258"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -6.40014458,
		"posY": 2.1800518,
		"posZ": -8.411829,
		"rotX": 9.376959,
		"rotY": 180.008,
		"rotZ": 0.08347981,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Flying",
	  "Description": "This creature can't be blocked except by creatures with flying and/or reach.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/flying.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "54339b"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -6.37583637,
		"posY": 2.18421459,
		"posZ": -8.355139,
		"rotX": 9.472151,
		"rotY": 180.047592,
		"rotZ": 0.659264863,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Flying",
	  "Description": "This creature can't be blocked except by creatures with flying and/or reach.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/flying2.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "b5c29d"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -6.944547,
		"posY": 2.22130442,
		"posZ": -8.149659,
		"rotX": 3.156734,
		"rotY": 179.815262,
		"rotZ": 173.107132,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "First Strike",
	  "Description": "This creature deals combat damage before creatures without first strike.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/firststrike.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "3b2a18"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -6.91309834,
		"posY": 2.20018721,
		"posZ": -7.157598,
		"rotX": 355.451,
		"rotY": 180.246613,
		"rotZ": 350.381744,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "Deathtouch",
	  "Description": "Any amount of damage this deals to a creature is enough to destroy it.",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/deathtouch.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "d20a40"
	},
	{
	  "Name": "Custom_Model",
	  "Transform": {
		"posX": -7.29321861,
		"posY": 2.22171664,
		"posZ": -7.77272654,
		"rotX": 358.9615,
		"rotY": 180.061,
		"rotZ": 171.396683,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "+1/+1 Counter",
	  "Description": "",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/counters/1_1.obj",
		"DiffuseURL": "http://josh.birnholz.com/tts/resources/counters/counters.jpg",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 0,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "GUID": "40d66b"
	}
  ],
  "GUID": "64680d"
}
"""

func prereleasePack(setName: String, setCode: String, boosterPacks: [[MTGCard]], promoCard: MTGCard, tokens: [MTGCard], basicLands: [MTGCard], includePromoCard: Bool?, includeLands: Bool?, includeSheet: Bool?, includeSpindown: Bool?, export: Bool) throws -> String {
	let includeSheet = includeSheet ?? true
	let includeSpindown = includeSpindown ?? true
	let includeLands = includeLands ?? true
	let includePromoCard = includePromoCard ?? true
	
	let boosterPackString = try boosterPacks.map { try boosterPackJSON(setName: setName, setCode: setCode, cards: $0, tokens: tokens) }.joined(separator: ",\n")
	let promoCardString = try singleCard(promoCard, facedown: false)
	
	var containedObjects: [String] = []
	
	if includeSpindown {
		containedObjects.append(spindownDieJSON(setCode: setCode))
	}
	
	if includeSheet {
		containedObjects.append(prereleaseSheet)
	}
	
	// Add supplemental objects
	switch setCode {
	case "iko":
		containedObjects.insert(ikoKeywordCounters, at: 1)
	default:
		break
	}
	
	if includePromoCard {
		containedObjects.append(promoCardString)
	}
	
	containedObjects.append(boosterPackString)
	
	if includeLands {
		let landPacks = try landPacksJSON(basicLands: basicLands)
		containedObjects.append(contentsOf: landPacks)
	}
	
	var boxTextureName = setCode
	var boxURL: URL { URL(string: "http://josh.birnholz.com/tts/resources/prerelease/\(boxTextureName).jpg")! }
	
	if !fileExists(at: boxURL) {
		boxTextureName = "default"
		print("No texture for \(setCode) prerelease box, using default")
	} else {
		print("Found texture for \(setCode) prerelease box")
	}
	
	let objectState = """
	{
	  "Name": "Custom_Model_Bag",
	  "Transform": {
		"posX": -5.646385,
		"posY": 0.9599922,
		"posZ": 1.21570218,
		"rotX": 9.832292E-06,
		"rotY": 180.0,
		"rotZ": -8.7960525E-06,
		"scaleX": 1.0,
		"scaleY": 1.0,
		"scaleZ": 1.0
	  },
	  "Nickname": "\(setName) Prerelease Pack",
	  "Description": "",
	  "GMNotes": "",
	  "ColorDiffuse": {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0
	  },
	  "Locked": false,
	  "Grid": true,
	  "Snap": true,
	  "IgnoreFoW": false,
	  "Autoraise": true,
	  "Sticky": true,
	  "Tooltip": true,
	  "GridProjection": false,
	  "HideWhenFaceDown": false,
	  "Hands": false,
	  "MaterialIndex": -1,
	  "MeshIndex": -1,
	  "Number": 0,
	  "CustomMesh": {
		"MeshURL": "http://josh.birnholz.com/tts/resources/prerelease/Pre-Release_Box.obj",
		"DiffuseURL": "\(boxURL)",
		"NormalURL": "",
		"ColliderURL": "",
		"Convex": true,
		"MaterialIndex": 3,
		"TypeIndex": 6,
		"CustomShader": {
		  "SpecularColor": {
			"r": 1.0,
			"g": 1.0,
			"b": 1.0
		  },
		  "SpecularIntensity": 0.0,
		  "SpecularSharpness": 2.0,
		  "FresnelStrength": 0.0
		},
		"CastShadows": true
	  },
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "ContainedObjects": [
		\(containedObjects.reversed().joined(separator: ",\n"))
	  ],
	  "GUID": "929456"
	}
	"""
	
	if !export {
		return objectState
	}
	
	return """
	{
	  "SaveName": "",
	  "GameMode": "",
	  "Gravity": 0.5,
	  "PlayArea": 0.5,
	  "Date": "",
	  "Table": "",
	  "Sky": "",
	  "Note": "",
	  "Rules": "",
	  "XmlUI": "",
	  "LuaScript": "",
	  "LuaScriptState": "",
	  "ObjectStates": [
		\(objectState)
	  ],
	  "TabStates": {},
	  "VersionNumber": ""
	}
"""
}

func allLandPacksSingleJSON(setCards: (cards: [MTGCard], setCode: String)?, specialOptions: [String], export: Bool) throws -> String {
	let lands: [MTGCard] = try {
		if let (cards, setCode) = setCards {
			let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: true)
			return processed.basicLands
		} else {
			return Swiftfall
			.getCards(query: "type='basic land –'", unique: false)
			.compactMap { $0?.data }
			.joined()
			.compactMap(MTGCard.init)
		}
	}()
	
	let landPacks = try landPacksJSON(basicLands: lands)
	
	let objectState = """
		{
		  "Name": "Bag",
		  "Transform": {
			"posX": -3.06584024,
			"posY": 0.7009516,
			"posZ": 1.23003662,
			"rotX": 1.61583137E-06,
			"rotY": -8.71582743E-05,
			"rotZ": -2.39790438E-06,
			"scaleX": 1.39999974,
			"scaleY": 1.39999974,
			"scaleZ": 1.39999974
		  },
		  "Nickname": "Land Packs",
		  "Description": "",
		  "GMNotes": "",
		  "ColorDiffuse": {
			"r": 0.7058823,
			"g": 0.366520882,
			"b": 0.0
		  },
		  "Locked": false,
		  "Grid": true,
		  "Snap": true,
		  "IgnoreFoW": false,
		  "Autoraise": true,
		  "Sticky": true,
		  "Tooltip": true,
		  "GridProjection": false,
		  "HideWhenFaceDown": false,
		  "Hands": false,
		  "MaterialIndex": -1,
		  "MeshIndex": -1,
		  "XmlUI": "",
		  "LuaScript": "",
		  "LuaScriptState": "",
		  "ContainedObjects": [
			\(landPacks.joined(separator: ",\n"))
		  ],
		  "GUID": "929456"
		}
		"""
		
		if !export {
			return objectState
		}
		
		return """
		{
		  "SaveName": "",
		  "GameMode": "",
		  "Gravity": 0.5,
		  "PlayArea": 0.5,
		  "Date": "",
		  "Table": "",
		  "Sky": "",
		  "Note": "",
		  "Rules": "",
		  "XmlUI": "",
		  "LuaScript": "",
		  "LuaScriptState": "",
		  "ObjectStates": [
			\(objectState)
		  ],
		  "TabStates": {},
		  "VersionNumber": ""
		}
	"""
}

func landPacksJSON(basicLands: [MTGCard]) throws -> [String] {
	let plains = basicLands.filter { $0.name == "Plains" }
	let islands = basicLands.filter { $0.name == "Island" }
	let swamps = basicLands.filter { $0.name == "Swamp" }
	let mountains = basicLands.filter { $0.name == "Mountain" }
	let forests = basicLands.filter { $0.name == "Forest" }
	
	guard !plains.isEmpty, !islands.isEmpty, !swamps.isEmpty, !mountains.isEmpty, !forests.isEmpty else {
		throw PackError.notEnoughLands
	}
	
	var landPacks: [[MTGCard]] = []
	
	for lands in [plains, islands, swamps, mountains, forests] {
		var pack: [MTGCard] = []
		
		repeat {
			pack.append(contentsOf: lands)
		} while pack.count < 20
		
		pack.shuffle()
		pack = Array(pack.prefix(20))
		landPacks.append(pack)
	}
	
	return try landPacks.map { try boosterPackJSON(setName: $0.first!.name!, setCode: "", cards: $0, inPack: false) }
}

fileprivate let prereleaseSheet = """
{
  "Name": "Custom_PDF",
  "Transform": {
	"posX": 8.722531,
	"posY": 0.960000336,
	"posZ": 3.4387958,
	"rotX": 1.52150221E-08,
	"rotY": 180.027908,
	"rotZ": -3.133754E-07,
	"scaleX": 1.47602439,
	"scaleY": 1.0,
	"scaleZ": 1.47602439
  },
  "Nickname": "",
  "Description": "",
  "GMNotes": "",
  "ColorDiffuse": {
	"r": 1.0,
	"g": 1.0,
	"b": 1.0
  },
  "Locked": false,
  "Grid": true,
  "Snap": true,
  "IgnoreFoW": false,
  "Autoraise": true,
  "Sticky": true,
  "Tooltip": true,
  "GridProjection": false,
  "HideWhenFaceDown": false,
  "Hands": false,
  "CustomPDF": {
	"PDFUrl": "http://josh.birnholz.com/tts/prebuild.pdf",
	"PDFPassword": "",
	"PDFPage": 0,
	"PDFPageOffset": 0
  },
  "XmlUI": "",
  "LuaScript": "",
  "LuaScriptState": "",
  "GUID": "10df3c"
}
"""

public func generate(input: Input, inputString: String, output: Output, export: Bool, boxCount: Int? = nil, prereleaseIncludePromoCard: Bool? = nil, prereleaseIncludeLands: Bool? = nil, prereleaseIncludeSheet: Bool? = nil, prereleaseIncludeSpindown: Bool? = nil, prereleaseBoosterCount: Int? = nil, includeExtendedArt: Bool, includeBasicLands: Bool, includeTokens: Bool, specialOptions: [String] = [], cardBack: URL? = nil) throws -> String {
	let mtgCards: [MTGCard]
	let setName: String
	let setCode: String?
	let tokens: [MTGCard]
	var foilPolicy: FoilPolicy = .modern
	
	switch input {
	case .cockatriceJSON:
		var allCards: [MTGCard]
		(allCards, setName, setCode) = try cardsFromCockatriceJSON(json: inputString)
		
		if includeTokens {
			tokens = allCards.separate { $0.layout == "token" || $0.typeLine?.lowercased().contains("emblem") == true || $0.typeLine?.lowercased().contains("token") == true }
		} else {
			tokens = []
		}
		
		mtgCards = allCards
		
		do {
			let encoder = JSONEncoder()
			let data = try encoder.encode(mtgCards)
			if let string = String(data: data, encoding: .utf8) {
				print(string)
			}
		} catch {
			print(error)
		}
	case .scryfallSetCode:
		let customSets = [
			"net": "net",
			"netropolis": "net"
		]
		
		if let customsetcode = customSets[inputString.lowercased()] {
			let jsonURL: URL? = {
				#if canImport(Vapor)
				let directory = DirectoryConfig.detect()
				let configDir = "Sources/App/Generation"
				return URL(fileURLWithPath: directory.workDir)
					.appendingPathComponent(configDir, isDirectory: true)
					.appendingPathComponent("custom-\(customsetcode).json", isDirectory: false)
				#else
				return Bundle.main.url(forResource: "custom-\(customsetcode)", withExtension: "json")
				#endif
			}()
			
			if let url = jsonURL, let data = try? Data(contentsOf: url), let string = String(data: data, encoding: .utf8) {
				return try generate(input: .cockatriceJSON, inputString: string, output: output, export: export, boxCount: boxCount, prereleaseIncludePromoCard: prereleaseIncludePromoCard, prereleaseIncludeLands: prereleaseIncludeLands, prereleaseIncludeSheet: prereleaseIncludeSheet, prereleaseIncludeSpindown: prereleaseIncludeSpindown, prereleaseBoosterCount: prereleaseBoosterCount, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens)
			}
		}
		
		let set = try Swiftfall.getSet(code: inputString)
		mtgCards = set.getCards().compactMap { $0?.data }.joined().compactMap(MTGCard.init)
		setName = set.name
		setCode = set.code
		
		let tokenCutoff = Date(timeIntervalSince1970: 1184284800) // Only sets released after this date include tokens
		if includeTokens, let code = set.code, let tokenSet = try? Swiftfall.getSet(code: "t\(code)"), let releaseDate = set.releasedAt, releaseDate >= tokenCutoff {
			tokens = tokenSet.getCards().compactMap { $0?.data }.joined().compactMap(MTGCard.init)
		} else {
			tokens = []
		}
		
		if setCode?.lowercased() == "vma" {
			foilPolicy = .vintageMasters
		} else {
			let foilCutoff = Date(timeIntervalSince1970: 1562889600) // Sets released after this date use the modern foil policy.
			if let releaseDate = set.releasedAt, releaseDate < foilCutoff {
				foilPolicy = .pre2020
			}
		}
	case .cardlist:
		return try deck(decklist: inputString, export: export, cardBack: cardBack)
	}
	
	guard !mtgCards.isEmpty else { throw PackError.noCards }
	
	let mode: Mode = {
		switch setCode?.lowercased() {
		case "war": return .warOfTheSpark
		case "s99": return .twoLands
		case "fut": return .futureSight
		case "ugl": return .unglued
		case "all", "chr": return .alliancesChronicles
		case "isd", "dka": return .innistradDoubleFaced
		case "soi", "emn": return .shadowsOverInnistradDoubleFaced
		case "iko": return .ikoria
		case "akh", "hou": return .amonkhetInvocations
		case "bfz", "ogw": return .zendikarExpeditions
		case "kld", "aer": return .kaladeshInventions
		case "vma": return .vintageMasters
		default: return .default
		}
	}()
	
	switch output {
	case .boosterBox:
		return try boosterBox(setName: setName, cards: mtgCards, tokens: tokens, setCode: setCode, mode: mode, export: export, boxCount: boxCount, includeExtendedArt: includeExtendedArt, foilPolicy: foilPolicy, specialOptions: specialOptions, includeBasicLands: includeBasicLands, includeTokens: includeTokens)
	case .boosterPack:
		return try boosterPack(setName: setName, cards: mtgCards, tokens: tokens, setCode: setCode, mode: mode, export: export, includeExtendedArt: includeExtendedArt, foilPolicy: foilPolicy, specialOptions: specialOptions, includeBasicLands: includeBasicLands, includeTokens: includeTokens)
	case .prereleaseKit:
		return try prereleaseKit(setName: setName, setCode: setCode ?? mtgCards.first?.set ?? inputString, cards: mtgCards, tokens: tokens, mode: mode, export: export, packCount: boxCount, includePromoCard: prereleaseIncludePromoCard, includeLands: prereleaseIncludeLands, includeSheet: prereleaseIncludeSheet, includeSpindown: prereleaseIncludeSpindown, boosterCount: prereleaseBoosterCount, includeExtendedArt: includeExtendedArt, foilPolicy: foilPolicy, specialOptions: specialOptions)
	case .landPack:
		return try allLandPacksSingleJSON(setCards: (cards: mtgCards, setCode: setCode ?? mtgCards.first?.set ?? inputString), specialOptions: specialOptions, export: export)
	}
}

func cardsFromCockatriceJSON(json: String) throws -> (cards: [MTGCard], setName: String, setCode: String?) {
	let data = json.data(using: .utf8)!
	let decoder = JSONDecoder()
	let cardDB = try decoder.decode(CockatriceCardDatabase.self, from: data)
	
	let cards: [(MTGCard, CockatriceCardDatabase.Card)] = cardDB.cards.enumerated().compactMap { (MTGCard(card: $1, collectorNumber: String($0+1)), $1) }
	
	let mtgCards: [MTGCard] = cards.map { mtgCard, cockatriceCard in
		var mtgCard = mtgCard
		var reverseRelated = cockatriceCard.reverseRelated ?? []
		
		if mtgCard.oracleText?.contains("Arm") == true || mtgCard.oracleText?.contains(" arm ") == true {
			reverseRelated.append(contentsOf: ["Weapon (Bow)", "Weapon (Katana)", "Weapon (Pistol)", "Weapon (Rifle)"].map(CockatriceCardDatabase.Card.ReverseRelated.init))
		}
		
		if mtgCard.typeLine?.lowercased().contains("basic") == true && mtgCard.typeLine?.lowercased().contains("land") == true && mtgCard.name?.hasPrefix("NET") == true {
			mtgCard.name = mtgCard.name?.replacingOccurrences(of: "NET ", with: "")
		}
		
		mtgCard.allParts = reverseRelated.compactMap { relation in
			guard let relatedCard = cards.first(where: { $0.0.name == relation.text })?.0 else { return nil }
			
			return MTGCard.RelatedCard(scryfallID: relatedCard.scryfallID,
									   component: .token,
									   name: relatedCard.name ?? "",
									   typeLine: relatedCard.typeLine,
									   url: relatedCard.scryfallURL)
		}
		
		if mtgCard.name?.hasPrefix("Weapon") == true && mtgCard.layout == "token" {
			mtgCard.name = "Weapon"
		}
			
		
		return mtgCard
	}
	
	return (mtgCards, cardDB.sets.first?.value.longname ?? "", cardDB.sets.first?.value.name)
}

struct ProcessedCards {
	var rarities: [MTGCard.Rarity: [MTGCard]]
	var customSlotRarities: [MTGCard.Rarity: [MTGCard]]
	/// The cards that should go into the basic land slot. Usually just basic lands, but not always.
	var basicLandsSlotCards: [MTGCard]
	var tokens: [MTGCard]
	var meldResults: [MTGCard]
	var showcaseRarities: [MTGCard.Rarity: [MTGCard]]
	var extendedArtCards: [MTGCard]
	var masterpieces: [MTGCard]
	/// Only Plains, Island, Swamp, Mountain, and Forest cards.
	var basicLands: [MTGCard]
}

fileprivate func process(cards: [MTGCard], setCode: String?, specialOptions: [String], includeBasicLands: Bool) throws -> ProcessedCards {
	var mainCards = cards
	
	let basicLandSlotCards: [MTGCard] = { () -> [MTGCard] in
		switch setCode?.lowercased() {
		case "grn", "rna":
			return cards.filter { $0.typeLine?.lowercased().contains("gate") == true }
		case "dgm":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "(set:rtr or set:gtc) type:land -type:basic")
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "frf":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "((set:ktk oracle:'search your library') or (set:frf oracle:'gain 1 life')) type:land")
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "cns", "cn2":
			return cards.filter { $0.watermark == "conspiracy" }
		case "tsp":
			return Swiftfall
				.getCards(query: "is:timeshifted")
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "emn":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:soi type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "aer":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:kld type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "ogw":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:bfz type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
				+ cards.filter { $0.typeLine?.lowercased().contains("basic") == true && $0.typeLine?.lowercased().contains("land") == true && $0.typeLine?.lowercased().contains("—") == true }
		case "bng", "jou":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:ths type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "gtc":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:rtr type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "dka":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:isd type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "wwk":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:zen type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "arb", "con":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:ala type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "iko":
			let basicLands = mainCards.separate { $0.typeLine?.lowercased().contains("basic") == true && $0.typeLine?.lowercased().contains("land") == true }
			guard includeBasicLands else { return [] }
			let dualLands = mainCards.separate { $0.typeLine?.lowercased().contains("land") == true && $0.oracleText?.contains("enters the battlefield tapped") == true && $0.oracleText?.contains("gain 1 life") == true }
			return basicLands + dualLands
		case "mir", "vis", "5ed", "por", "wth", "tmp", "sth", "exo", "p02", "usg", "ulg", "6ed", "ptk", "uds", "mmq", "nem", "pcy", "inv", "pls", "7ed", "csp", "dis", "gpt", "rav", "9ed", "lrw", "mor", "shm", "eve", "apc", "ody", "tor", "jud", "ons", "lgn", "scg", "mrd", "dst", "5dn", "chk", "bok", "sok", "plc":
			return []
		default:
			let basicLands = mainCards.separate { $0.typeLine?.lowercased().contains("basic") == true && $0.typeLine?.lowercased().contains("land") == true }
			guard includeBasicLands else { return [] }
			return basicLands
		}
		}().filter { $0.isFoundInBoosters && !$0.isPromo }
	
	// Actual basic lands. Used when creating land packs
	let basicLands: [MTGCard] = {
		let defaultBasicLands = { basicLandSlotCards.filter { $0.typeLine?.contains("Basic") == true && $0.typeLine?.contains("Land") == true && $0.typeLine?.contains("—") == true && $0.frameEffects?.contains("showcase") != true } }() // Get basic lands with a type. This will find normal basic lands and basic snow lands, but not Wastes, which appears at Common rarity, not land rarity.
		
		switch setCode?.lowercased() ?? "" {
		case "dgm":
			return Swiftfall
				.getCards(query: "(set:rtr or set:gtc) type:land type:basic", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
//		case "cns", "cn2":
//			return []
//		// TODO: Find lands for conspiracy.
		case "thb":
			// Use regular, non-Nyx basic lands that aren't found in boosters for THB.
			return cards.filter { $0.typeLine?.lowercased().contains("basic") == true && $0.typeLine?.lowercased().contains("land") == true && !$0.isFoundInBoosters && !$0.isPromo }
		case "tsp",
			 _ where basicLandSlotCards.isEmpty:
			return cards.filter { $0.typeLine?.lowercased().contains("basic") == true && $0.typeLine?.lowercased().contains("land") == true && $0.isFoundInBoosters && !$0.isPromo }
		case "ogw":
			return basicLandSlotCards.filter { $0.name != "Wastes" }
		case _ where Set(defaultBasicLands.compactMap { $0.name }).count == 5:
			return defaultBasicLands
		default:
			// Just get the most recent standard set basic lands if there are none others.
			return Swiftfall
			.getCards(query: "type='basic land –'", unique: false)
			.compactMap { $0?.data }
			.joined()
			.compactMap(MTGCard.init)
		}
	}()
	
	let additionalMainCards: [MTGCard] = try {
		switch setCode?.lowercased() {
		case "dgm":
			return Swiftfall
				.getCards(query: "(set:rtr or set:gtc) type:land oracle:'pay 2 life'")
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "cmb1", "fmb1":
			// Add main mystery booster cards to convention/store set.
			return try Swiftfall
				.getSet(code: "mb1")
				.getCards()
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "mb1":
			// Add foils to normal mystery booster set.
			return try Swiftfall
				.getSet(code: "fmb1")
				.getCards()
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "iko" where specialOptions.contains("c20partners"):
			var cards = Swiftfall
				.getCards(query: "set:c20 o:'partner with'")
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
			
			for i in 0 ..< cards.count {
				cards[i].isFoundInBoosters = true
			}
			return cards
		default:
			return []
		}
		}()
	
	mainCards.append(contentsOf: additionalMainCards)
	
	switch setCode?.lowercased() {
	case "iko":
		let godzillaSeriesCollectorNumbers = (364...387).map(String.init) + ["373A"]
		mainCards.removeAll { card in
			godzillaSeriesCollectorNumbers.contains(card.collectorNumber)
		}
	default:
		break
	}
	
	let showcases: [MTGCard.Rarity: [MTGCard]] = .init(grouping: mainCards.separate { $0.frameEffects?.contains("showcase") == true }, by: \.rarity)
	
	let extendedArt = mainCards.separate { $0.borderColor == .borderless || $0.frameEffects?.contains("extendedart") == true }
	
	let tokensAndEmblems = mainCards.separate {
		$0.typeLine?.lowercased().contains("token") == true || $0.typeLine?.lowercased().contains("emblem") == true
	}
	
	mainCards = mainCards.filter { $0.isFoundInBoosters && $0.language == .english && !$0.isPromo }
	
	guard mainCards.contains(where: { $0.isFoundInBoosters }) else {
		throw PackError.notInBoosters
	}
	
	let meldResults: [MTGCard] = mainCards.separate { card in
		guard card.layout == "meld", let parts = card.allParts else { return false }
		return parts.contains(where: { $0.component == .meldResult && $0.scryfallID == card.scryfallID }) == true
	}
	
	let customSlotRarities: [MTGCard.Rarity: [MTGCard]] = {
		switch setCode?.lowercased() {
		case "isd", "dka", "soi", "emn":
			return .init(grouping: mainCards.separate(by: { $0.layout == "transform" || $0.layout == "meld" }), by: \.rarity)
		case "war":
			return .init(grouping: mainCards.separate(by: { $0.typeLine?.lowercased().contains("planeswalker") == true }), by: \.rarity)
		case "vma":
			return .init(grouping: mainCards.separate { (1...9).contains(Int($0.collectorNumber) ?? 0) }, by: \.rarity)
		default:
			return [:]
		}
	}()
	
	let masterpieces: [MTGCard] = try {
		switch setCode?.lowercased() {
		case "bfz":
			return try Swiftfall
				.getSet(code: "exp")
				.getCards()
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
				.filter { (1...25).contains(Int($0.collectorNumber) ?? 0) }
		case "ogw":
			return try Swiftfall
				.getSet(code: "exp")
				.getCards()
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
				.filter { (26...45).contains(Int($0.collectorNumber) ?? 0) }
		case "kld":
			return try Swiftfall
				.getSet(code: "mps")
				.getCards()
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
				.filter { (1...30).contains(Int($0.collectorNumber) ?? 0) }
		case "aer":
			return try Swiftfall
				.getSet(code: "mps")
				.getCards()
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
				.filter { (31...54).contains(Int($0.collectorNumber) ?? 0) }
		case "akh":
			return try Swiftfall
				.getSet(code: "mp2")
				.getCards()
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
				.filter { (1...30).contains(Int($0.collectorNumber) ?? 0) }
		case "hou":
			return try Swiftfall
				.getSet(code: "mp2")
				.getCards()
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
				.filter { (31...54).contains(Int($0.collectorNumber) ?? 0) }
		default:
			return []
		}
	}()
	
	let rarities: [MTGCard.Rarity: [MTGCard]] = .init(grouping: mainCards, by: \.rarity)
	
	return ProcessedCards(rarities: rarities,
						  customSlotRarities: customSlotRarities,
						  basicLandsSlotCards: basicLandSlotCards,
						  tokens: tokensAndEmblems,
						  meldResults: meldResults,
						  showcaseRarities: showcases,
						  extendedArtCards: extendedArt,
						  masterpieces: masterpieces,
						  basicLands: basicLands)
}

fileprivate func boosterBox(setName: String, cards: [MTGCard], tokens: [MTGCard], setCode: String?, mode: Mode, export: Bool, boxCount: Int?, includeExtendedArt: Bool, foilPolicy: FoilPolicy, specialOptions: [String], includeBasicLands: Bool, includeTokens: Bool) throws -> String {
	let count: Int = {
		if let boxCount = boxCount, boxCount > 0 {
			return boxCount
		}
		
		switch setCode {
		case "cns", "cn2", "med", "me2", "me3", "me4", "vma", "tpr", "mma", "mm2", "mm3", "ema", "ima", "a25", "uma":
			return 24
		default:
			return 36
		}
	}()
	
	if setCode?.lowercased() == "mb1" || setCode?.lowercased() == "fmb1" || setCode?.lowercased() == "cmb1" {
		let cards = processMysteryBoosterCards(cards)
		let packs: [[MTGCard]] = (1...count).map { _ in generateMysteryBooster(cards: cards) }
		
		return try boosterBag(setName: "Mystery Booster", setCode: setCode ?? "", boosterPacks: packs, tokens: [], export: export)
	} else if setCode?.lowercased() == "plc" {
		let cards = processPlanarChaosCards(cards: cards)
		let packs: [[MTGCard]] = (1...count).map { _ in generatePlanarChaosPack(normalRarities: cards.normalRarities, colorshiftedRarities: cards.colorshiftedRarities) }
		
		return try boosterBag(setName: setName, setCode: setCode ?? "", boosterPacks: packs, tokens: [], export: export)
	}
	
	let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: includeBasicLands)
	
	let packs: [[MTGCard]] = (1...count).map { _ in generatePack(rarities: processed.rarities,
																 customSlotRarities: processed.customSlotRarities,
																 basicLands: processed.basicLandsSlotCards,
																 tokens: includeTokens ? tokens + processed.tokens : [],
																 showcaseRarities: processed.showcaseRarities,
																 extendedArt: processed.extendedArtCards,
																 meldResults: processed.meldResults,
																 mode: mode,
																 includeExtendedArt: includeExtendedArt,
																 masterpieceCards: processed.masterpieces,
																 foilPolicy: foilPolicy) }
	
	return try boosterBag(setName: setName, setCode: setCode ?? "", boosterPacks: packs, tokens: tokens + processed.tokens, export: export)
}

fileprivate func boosterPack(setName: String, cards: [MTGCard], tokens: [MTGCard], setCode: String?, mode: Mode, export: Bool, includeExtendedArt: Bool, foilPolicy: FoilPolicy, specialOptions: [String], includeBasicLands: Bool, includeTokens: Bool) throws -> String {
	if setCode?.lowercased() == "mb1" || setCode?.lowercased() == "fmb1" || setCode?.lowercased() == "cmb1" {
		let cards = processMysteryBoosterCards(cards)
		let pack = generateMysteryBooster(cards: cards)
		
		return try singleBoosterPack(setName: setName, setCode: setCode ?? "", boosterPack: pack, tokens: [], export: export)
	} else if setCode?.lowercased() == "plc" {
		let cards = processPlanarChaosCards(cards: cards)
		let pack = generatePlanarChaosPack(normalRarities: cards.normalRarities, colorshiftedRarities: cards.colorshiftedRarities)
		
		return try singleBoosterPack(setName: setName, setCode: setCode ?? "", boosterPack: pack, tokens: [], export: export)
	}
	
	let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: includeBasicLands)
	
	let pack = generatePack(rarities: processed.rarities,
							customSlotRarities: processed.customSlotRarities,
							basicLands: processed.basicLandsSlotCards,
							tokens: includeTokens ? tokens + processed.tokens : [],
							showcaseRarities: processed.showcaseRarities,
							extendedArt: processed.extendedArtCards,
							meldResults: processed.meldResults,
							mode: mode,
							includeExtendedArt: includeExtendedArt,
							masterpieceCards: processed.masterpieces,
							foilPolicy: foilPolicy)
	
	return try singleBoosterPack(setName: setName, setCode: setCode ?? "", boosterPack: pack, tokens: tokens + processed.tokens, export: export)
}

fileprivate func prereleaseKit(setName: String, setCode: String, cards: [MTGCard], tokens: [MTGCard], mode: Mode, export: Bool, packCount: Int? = nil, includePromoCard: Bool?, includeLands: Bool?, includeSheet: Bool?, includeSpindown: Bool?, boosterCount: Int?, includeExtendedArt: Bool, foilPolicy: FoilPolicy, specialOptions: [String]) throws -> String {
	let boosterCount = boosterCount ?? 6
	let packCount = packCount ?? 1
	let prereleasePacks: [String] = try (0 ..< (packCount)).map { _ in
		if setCode.lowercased() == "mb1" || setCode.lowercased() == "fmb1" || setCode.lowercased() == "cmb1" {
			throw PackError.unsupported
		} else if setCode.lowercased() == "plc" {
			let cards = processPlanarChaosCards(cards: cards)
			let packs = (1...boosterCount).map { _ in generatePlanarChaosPack(normalRarities: cards.normalRarities, colorshiftedRarities: cards.colorshiftedRarities) }
			
			let promoCard = try MTGCard(Swiftfall.getCard(id: "c287d593-cfd0-46b6-bde0-0c04a83d828b"))
			
			let basicLands: [MTGCard] = Swiftfall
			.getCards(query: "set:tsp type:'basic land'", unique: true)
			.compactMap { $0?.data }
			.joined()
			.compactMap(MTGCard.init)
			
			return try prereleasePack(setName: setName, setCode: setCode, boosterPacks: packs, promoCard: promoCard, tokens: [], basicLands: basicLands, includePromoCard: includePromoCard, includeLands: includeLands, includeSheet: includeSheet, includeSpindown: includeSpindown, export: export)
		}
		
		let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: true)
		
		let packs: [[MTGCard]] = (1...boosterCount).map { _ in generatePack(rarities: processed.rarities,
																 customSlotRarities: processed.customSlotRarities,
																 basicLands: processed.basicLandsSlotCards,
																 tokens: tokens + processed.tokens,
																 showcaseRarities: processed.showcaseRarities,
																 extendedArt: processed.extendedArtCards,
																 meldResults: processed.meldResults,
																 mode: mode,
																 includeExtendedArt: includeExtendedArt,
																 masterpieceCards: processed.masterpieces,
																 foilPolicy: foilPolicy) }
		
		let promoCard: MTGCard = try {
			let promos = Swiftfall.getCards(query: "set:p\(setCode) is:prerelease").compactMap { $0?.data }.joined().map(MTGCard.init)
			let promosRarities: [MTGCard.Rarity: [MTGCard]] = .init(grouping: promos, by: \.rarity)
			
			let promoRarity: MTGCard.Rarity = (1...8).randomElement()! == 8 ? .mythic : .rare
			
			if let promo = promosRarities[promoRarity]?.randomElement() ?? promosRarities[.rare]?.randomElement() {
				return promo
			} else if let card = processed.rarities[promoRarity]?.randomElement() ?? processed.rarities[.rare]?.randomElement() {
				if setCode == "iko" {
					var card = card
					let name = card.name?.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "'", with: "") ?? ""
					let imageURL = URL(string: "http://josh.birnholz.com/tts/cards/iko/iko-\(card.collectorNumber)-\(name).jpg")!
					card.imageUris?["normal"] = imageURL
					card.imageUris?["large"] = imageURL
					return card
				}
				
				if includeExtendedArt, let extendedArtVersion = processed.extendedArtCards.filter({ $0.name == card.name }).randomElement() ?? processed.showcaseRarities[card.rarity]?.filter({ $0.name == card.name }).randomElement() {
					return extendedArtVersion
				} else {
					return card
				}
			} else {
				throw PackError.noValidPromo
			}
			}()
		
		
		return try prereleasePack(setName: setName, setCode: setCode, boosterPacks: packs, promoCard: promoCard, tokens: tokens + processed.tokens, basicLands: processed.basicLands, includePromoCard: includePromoCard, includeLands: includeLands, includeSheet: includeSheet, includeSpindown: includeSpindown, export: false)
	}
	
	if let first = prereleasePacks.first, packCount == 1 {
		if !export {
			return first
		}
		return """
			{
			  "SaveName": "",
			  "GameMode": "",
			  "Gravity": 0.5,
			  "PlayArea": 0.5,
			  "Date": "",
			  "Table": "",
			  "Sky": "",
			  "Note": "",
			  "Rules": "",
			  "XmlUI": "",
			  "LuaScript": "",
			  "LuaScriptState": "",
			  "ObjectStates": [
				\(first)
			  ],
			  "TabStates": {},
			  "VersionNumber": ""
			}
		"""
	}
	
	// put in a bag
	
	let objectState = """
		{
		  "Name": "Bag",
		  "Transform": {
			"posX": -3.06584024,
			"posY": 0.7009516,
			"posZ": 1.23003662,
			"rotX": 1.61583137E-06,
			"rotY": -8.71582743E-05,
			"rotZ": -2.39790438E-06,
			"scaleX": 1.39999974,
			"scaleY": 1.39999974,
			"scaleZ": 1.39999974
		  },
		  "Nickname": "\(setName) Prerelease Packs",
		  "Description": "",
		  "GMNotes": "",
		  "ColorDiffuse": {
			"r": 0.7058823,
			"g": 0.366520882,
			"b": 0.0
		  },
		  "Locked": false,
		  "Grid": true,
		  "Snap": true,
		  "IgnoreFoW": false,
		  "Autoraise": true,
		  "Sticky": true,
		  "Tooltip": true,
		  "GridProjection": false,
		  "HideWhenFaceDown": false,
		  "Hands": false,
		  "MaterialIndex": -1,
		  "MeshIndex": -1,
		  "XmlUI": "",
		  "LuaScript": "",
		  "LuaScriptState": "",
		  "ContainedObjects": [
			\(prereleasePacks.joined(separator: ",\n"))
		  ],
		  "GUID": "929456"
		}
		"""
		
		if !export {
			return objectState
		}
		
		return """
		{
		  "SaveName": "",
		  "GameMode": "",
		  "Gravity": 0.5,
		  "PlayArea": 0.5,
		  "Date": "",
		  "Table": "",
		  "Sky": "",
		  "Note": "",
		  "Rules": "",
		  "XmlUI": "",
		  "LuaScript": "",
		  "LuaScriptState": "",
		  "ObjectStates": [
			\(objectState)
		  ],
		  "TabStates": {},
		  "VersionNumber": ""
		}
	"""
}

func deck(decklist: String, export: Bool, cardBack: URL? = nil) throws -> String {
	let groups = DeckParser.parse(deckList: decklist).filter { !$0.cardCounts.isEmpty }
	let identifiers = Array(Set(groups.map { $0.cardCounts }.joined().map { $0.identifier }))
	
	guard !identifiers.isEmpty else {
		throw PackError.emptyInput
	}
	
//	let fetchedCardGroups: [[Swiftfall.Card]] = identifiers.chunked(by: 20).map { identifiers in
//		let query = identifiers.compactMap(\.query).map { "(\($0))" }.joined(separator: " or ") + " prefer:newest game:paper"
//		let fetchedCards: [Swiftfall.Card] = Array(Swiftfall.getCards(query: query, unique: true).compactMap { $0?.data }.joined())
//		return fetchedCards
//	}
//	let cards: [Swiftfall.Card] = Array(fetchedCardGroups.joined())
	let collections = identifiers.chunked(by: 75).compactMap { try? Swiftfall.getCollection(identifiers: $0) }
	var cards = Array(collections.map(\.data).joined())
	var notFound: [MTGCardIdentifier] = Array(collections.compactMap(\.notFound).joined())
	
	if !notFound.isEmpty {
		let retriedNotFoundCardGroups: [[Swiftfall.Card]] = notFound.chunked(by: 20).map { identifiers in
			let query = identifiers.compactMap(\.query).map { "(\($0))" }.joined(separator: " or ") + " prefer:newest game:paper"
			let fetchedCards: [Swiftfall.Card] = Array(Swiftfall.getCards(query: query, unique: true).compactMap { $0?.data }.joined())
			return fetchedCards
		}
		let retriedNotFoundCards = retriedNotFoundCardGroups.joined()

		notFound = notFound.filter { identifier in
			if let card = retriedNotFoundCards[identifier] {
				cards.append(card)
				return false
			}
			return true
		}
	}
	
	guard !identifiers.isEmpty else {
		throw PackError.noCards
	}
	
//	var notFound: [MTGCardIdentifier] = []
	var tokens: [MTGCard] = []
	
	let packs: [[MTGCard]] = groups.map { group in
		return group.cardCounts.reduce(into: [MTGCard]()) { (deck, cardCount) in
			guard let card = cards[cardCount.identifier] else {
				notFound.append(cardCount.identifier)
				return
			}
			if card.layout == "token" || card.layout == "emblem" {
				tokens.append(contentsOf: Array(repeating: MTGCard(card), count: cardCount.count))
			} else {
				deck.append(contentsOf: Array(repeating: MTGCard(card), count: cardCount.count))
			}
		}
	}
	
	guard notFound.isEmpty else {
		throw PackError.noCardFound(String(describing: notFound.map { String(describing: $0) }.joined(separator: ", ")))
	}
	let tokenIdentifiers = Set(cards.compactMap { $0.allParts?.compactMap { $0.component == "token" ? $0.id : nil } }.joined()).map { MTGCardIdentifier.id($0) }
	
	if !tokenIdentifiers.isEmpty {
		do {
			let collection = try Swiftfall.getCollection(identifiers: tokenIdentifiers)
			tokens.append(contentsOf: collection.data.map(MTGCard.init).filter { card in card.oracleID != nil && !tokens.contains(where: { manualToken in manualToken.oracleID == card.oracleID }) })
			
			let cards: [UUID?: [MTGCard]] = .init(grouping: tokens, by: \.oracleID)
			
			tokens = cards.compactMap { oracleID, cards in
				let cards = cards.sorted {
					($0.releaseDate ?? Date()) > ($1.releaseDate ?? Date())
				}
				
				return cards.first
			}
		} catch {
			
		}
	}
	
	tokens = tokens.sorted {
		($0.name ?? "") < ($1.name ?? "")
	}
	
  	if groups.count == 1 {
		var pack = Array(packs.joined())
		
		if let token = tokens.first {
			pack.insert(token, at: 0)
		}
		
		return try singleBoosterPack(setName: "", setCode: "", boosterPack: pack, tokens: tokens, inPack: false, export: export, cardBack: cardBack)
	} else {
		var names = groups.reversed().map(\.name)
		var packs = Array(packs.reversed())
		if let token = tokens.first {
			packs.insert([token], at: 0)
			names.insert("Token", at: 0)
		}
		
		return try boosterBag(setName: "", setCode: "", boosterPacks: packs, names: names, tokens: tokens, inPack: false, export: export, cardBack: cardBack)
	}
	
}

extension Collection where Element == Swiftfall.Card {
	subscript(_ identifier: MTGCardIdentifier) -> Swiftfall.Card? {
		let foundCard = first { (card) -> Bool in
			switch identifier {
			case .id(let id):
				return card.id == id
			case .mtgoID(let id):
				return card.mtgoId == id
			case .multiverseID(let id):
				return card.multiverseIds.contains(id)
			case .oracleID(let id):
				return card.oracleId == id
			case .illustrationID(let id):
				return card.illustrationId == id.uuidString
			case .name(let name):
				let name = name.lowercased()
				return card.name?.lowercased().hasPrefix(name) == true || card.cardFaces?.contains(where: { $0.name?.lowercased().hasPrefix(name) == true }) == true
			case .nameSet(name: let name, set: let set):
				let name = name.lowercased()
				return card.name?.lowercased().hasPrefix(name) == true || card.cardFaces?.contains(where: { $0.name?.lowercased().hasPrefix(name) == true }) == true && card.set.lowercased() == set.lowercased()
			case .collectorNumberSet(collectorNumber: let collectorNumber, set: let set):
				return card.collectorNumber.lowercased() == collectorNumber.lowercased() && card.set.lowercased() == set.lowercased()
			}
		}
		
		if let result = foundCard {
			return result
		} else if case .nameSet(let name, let set) = identifier, set.lowercased() == "dar" {
			return self[.nameSet(name: name, set: "dom")]
		} else if case .collectorNumberSet(let collectorNumber, let set) = identifier, set.lowercased() == "dar" {
			return self[.collectorNumberSet(collectorNumber: collectorNumber, set: "dom")]
		} else {
			return nil
		}
	}
}

extension MTGCardIdentifier {
	var query: String? {
		switch self {
		case .name(let name):
			return "\"\(name)\""
		case .nameSet(name: let name, set: let set):
			return "\"\(name)\" set:\(set)"
		case .collectorNumberSet(collectorNumber: let collectorNumber, set: let set):
			return "number:\(collectorNumber) set:\(set)"
		default:
			return nil
		}
	}
}
