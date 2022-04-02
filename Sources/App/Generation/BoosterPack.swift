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
	case invalidJumpStartName
	case invalidURL
	case privateDeck
	case noCardFound(String)
	case couldNotLoadCards(String)
	case missingSet
	
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
		case .invalidJumpStartName:
			return 10
		case .invalidURL:
			return 11
		case .privateDeck:
			return 12
		case .couldNotLoadCards(_):
			return 13
		case .missingSet:
			return 14
		}
	}
}

public enum Input: Int, CaseIterable {
	case scryfallSetCode
//		case scryfallSetJSON
	case mtgCardJSON
	case cardlist
	
	var title: String {
		switch self {
		case .mtgCardJSON: return "MTG Card JSON"
//			case .scryfallSetJSON: return "Scryfall Set JSON"
		case .scryfallSetCode: return "Scryfall Set"
		case .cardlist: return "Deck List"
		}
	}
}

public enum Output: Int, CaseIterable {
	case boosterPack
	case boosterBox
	case commanderBoxingLeagueBox
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
		case .commanderBoxingLeagueBox:
			return "Commander Boxing League Booster Box"
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
		case .commanderBoxingLeagueBox:
			return "Generate a booster box pre-sorted for Commander boxing league."
		}
	}
	
}

enum Mode {
	/// 1 basic land, 1 rare (or a mythic 1/8 of the time), 3 uncommons, the rest common
	case `default`
	/// Same as default, but gauarantees a planeswalker in every pack
	case warOfTheSpark
	/// Gauarantees a legendary card in every pack
	case dominaria
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
	/// 1/15 packs contain rare/mythic showcase or borderless card. If that fails, 2/7 packs contain common/uncommon showcase or borderless card. Foil showcase/borderless show up 1/35 packs.
	case m21
	/// Gauranteed modal double-faced card.
	case zendikarRising
	/// 1 Double-faced U/R/M, plus 1 double-card C.
	case mid
	
	/// 2 rares in each pack, 2 guaranteed foils.
	case doubleMasters
	
	case zendikarExpeditions
	case amonkhetInvocations
	case kaladeshInventions
	
	/// Basic land is replaced with a foil of any rarity, OR, except 1/53 packs, a Power Nine card
	case vintageMasters
	
	case commanderLegends
	case originalShowcase
	case timeSpiralRemastered
	case strixhaven
	case mh2
	
	// Add 1 DFC U/C, normal slots for U/C are all single-faced.
	case neo
}

extension MTGCard {
	func partner<S: Sequence>(from cards: S) -> MTGCard? where S.Element == MTGCard {
		guard hasPartner else { return nil }
		guard let allParts = allParts else { return nil }
		guard let part = allParts.first(where: { $0.component == .comboPiece }) else { return nil }
		return cards.first(where: { $0.scryfallID == part.scryfallID })
	}
	
	var hasPartner: Bool {
		return keywords.contains("Partner with")
	}
}

enum FoilPolicy {
	/// Foil cards appear 1 in 67 cards, or 22.5% chance in any one booster pack
	case pre2020
	/// Foil cards appear 1 in 45 cards, or 33.4% chance in any one booster pack
	case modern
	/// Foil cards appear in all packs (100% chance)
	case guaranteed
	
	fileprivate var limit: Int {
		switch self {
		case .pre2020: return 225
		case .modern: return 334
		case .guaranteed: return 1000
		}
	}
}

enum MythicPolicy {
	/// Mythic Rares appear 1 in 8 packs
	case previous
	/// Mythic Rares appear 1 in 7.4 packs
	case postM21
}

// MARK: - Generate Booster Pack

extension Dictionary where Key == MTGCard.Rarity, Value == [MTGCard] {
	func filtered(for seed: Seed?) -> [MTGCard.Rarity: [MTGCard]] {
		guard let seed = seed else { return self }
		
		return mapValues { cards in
			return cards.filter { seed.contains($0) }
		}
	}
	
	init(groupingByRarity cards: [MTGCard], filteredFor seed: Seed? = nil) {
		self.init(grouping: cards, by: \.rarity)
		self = self.filtered(for: seed)
	}
}

extension Array where Element == MTGCard {
	func filtered(for seed: Seed?) -> [MTGCard] {
		guard let seed = seed else { return self }
		
		return filter { seed.contains($0) }
	}
}

func generatePack(rarities: [MTGCard.Rarity: [MTGCard]], customSlotRarities: [MTGCard.Rarity: [MTGCard]], basicLands: [MTGCard], tokens: [MTGCard], showcaseRarities: [MTGCard.Rarity: [MTGCard]], borderless: [MTGCard], extendedArt: [MTGCard], meldResults: [MTGCard], mode: Mode, includeExtendedArt: Bool, masterpieceCards: [MTGCard], foilPolicy: FoilPolicy, mythicPolicy: MythicPolicy, seed: Seed? = nil) -> CardCollection {
	let customSlotRarities = customSlotRarities.filtered(for: seed)
	let basicLands = basicLands.filtered(for: seed)
	let borderless = borderless.filtered(for: seed)
	let extendedArt = extendedArt.filtered(for: seed)
	let masterpieceCards = masterpieceCards.filtered(for: seed)
	
	var pack = CardCollection()
	
	let guaranteedPlaneswalkerSlot = mode == .warOfTheSpark ? (0...3).randomElement()! : nil
	
	var allRarities: [MTGCard.Rarity: [MTGCard]] = [:]
	
	let landRarities: [MTGCard.Rarity: [MTGCard]]? = {
		// todo: maybe change this to check if basicLands contains where { $0.typeline.contains("basic") == false }
		guard Set(basicLands.map(\.rarity)).count > 1 else {
			return nil
		}
		
		return .init(groupingByRarity: basicLands, filteredFor: seed)
	}()
	
	var borderlessPlaneswalkers = borderless
	
	let showcaseRarities: [MTGCard.Rarity: [MTGCard]] = {
		var showcaseRarities = showcaseRarities
		
		if mode == .m21 {
			var mythics = showcaseRarities[.mythic] ?? []
			
			// M21 has four alt-art normal and four alt-art showcase versions of Teferi, Master of Time. Remove all but one of them in each slot, so he isn't 4x as likely to appear in the mythic slot.
			if let teferi = mythics.separateAll(where: { $0.name == "Teferi, Master of Time" && $0.borderColor != .borderless }).randomElement() {
				mythics.append(teferi)
			}
			
			showcaseRarities[.mythic] = mythics
			
		}
		
		// Add borderless non-planeswalkers to showcases. This makes borderless planeswalkers appear 1 in 3-4 boxes, but non-Planeswalkers appear as often as other showcase cards of their rarity.
		for rarity in MTGCard.Rarity.allCases {
			let borderlessNonPlaneswalkers = borderlessPlaneswalkers.separateAll(where: { $0.rarity == rarity && $0.typeLine.contains("Planeswalker") == false })
			var otherShowcases = showcaseRarities[rarity] ?? []
			otherShowcases.append(contentsOf: borderlessNonPlaneswalkers)
			showcaseRarities[rarity] = otherShowcases
		}
		
		return showcaseRarities.filtered(for: seed)
	}()
	
	let rarities: [MTGCard.Rarity: [MTGCard]] = {
		var rarities = rarities
		
		if mode == .m21 {
			var mythics = rarities[.mythic] ?? []
			
			// M21 has four alt-art normal and four alt-art showcase versions of Teferi, Master of Time. Remove all but one of them in each slot, so he isn't 4x as likely to appear in the mythic slot.
			if let teferi = mythics.separateAll(where: { $0.name == "Teferi, Master of Time" }).randomElement() {
				mythics.append(teferi)
			}
			
			rarities[.mythic] = mythics
		}
		
		allRarities = rarities.filtered(for: seed)
		
		if mode == .strixhaven {
			for (rarity, customSlotCards) in customSlotRarities {
				var cards = allRarities[rarity] ?? []
				cards.append(contentsOf: customSlotCards)
				allRarities[rarity] = cards
			}
			// TODO: foil archive cards
		}
		
		if mode == .zendikarRising {
			for rarity in MTGCard.Rarity.allCases {
				rarities[rarity] = rarities[rarity]?.filter { $0.layout != "modal_dfc" }
			}
		}
		
		return rarities.filtered(for: seed)
	}()
	
	var includeMythic: Bool {
		switch mythicPolicy {
		case .previous:
			return (1...8).randomElement()! == 8
		case .postM21:
			return (1...100).randomElement()! >= 74
		}
	}
	
	let shouldIncludeShowcaseCommonOrUncommon: Bool = {
		if mode == .originalShowcase {
			return (1...9).randomElement() == 1
		} else {
			return (1...3).randomElement() == 1
		}
	}()
	
	let shouldIncludeShowcaseRareOrMythic: Bool = {
		if mode == .originalShowcase {
			return (1...27).randomElement() == 1
		} else {
			return (1...29).randomElement()! <= 2
		}
	}()
	
//	let includedShowcaseRarity: ShowcaseRarity? = {
//		guard showcaseRarities.values.joined().contains(where: \.isFoundInBoosters) else { return nil }
//
//		if mode == .ikoria || mode == .zendikarRising {
//			if (1...29).randomElement()! <= 2 {
//				return .rareMythic
//			} else if (1...3).randomElement() == 1 {
//				return .commonUncommon
//			} else {
//				return nil
//			}
//		} else if mode == .m21 {
//			if (1...15).randomElement() == 1 {
//				return .rareMythic
//			} else if (1...7).randomElement()! <= 2 {
//				return .commonUncommon
//			} else {
//				return nil
//			}
//		}
//
//		return (1...9).randomElement() == 9 ? .random : nil
//	}()
	
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
	var includedFoilRarity: MTGCard.Rarity? {
		guard (1...1000).randomElement()! <= foilPolicy.limit else { return nil }
		
		let rarityValue = (1...1000).randomElement()!
		switch rarityValue {
		case 1...500: return .common
		case 1...833: return .uncommon
		case 1...979: return .rare
		default: return .mythic
		}
	}
	
	// used for STX mystical archive and MH2 new-to-modern reprint
	var includedStrixhavenArchiveRarity: MTGCard.Rarity? {
		guard mode == .strixhaven || mode == .mh2 else { return nil }
		
		let value = (1...1000).randomElement()!
		switch value {
		case 1...66: return .mythic
		case 1...264: return .rare
		default: return .uncommon
		}
	}
	
	var shouldIncludeTimeshiftedFoil: Bool {
		return mode == .timeSpiralRemastered && (1...27).randomElement() == 1
	}
	
	let zendikarRisingGuaranteedDFCRarity: MTGCard.Rarity? = {
		guard mode == .zendikarRising else { return nil }
		
//		let rarityValue = (1...1000).randomElement()!
//		switch rarityValue {
//		case 1...500: return .uncommon // There are no common modal DFCs
//		case 1...833: return .uncommon
//		case 1...979: return .rare
//		default: return .mythic
//		}
		var rarities: [MTGCard.Rarity] = []
		rarities.append(contentsOf: Array(repeating: .mythic, count: 5))
		rarities.append(contentsOf: Array(repeating: .rare, count: 11))
		rarities.append(contentsOf: Array(repeating: .uncommon, count: 20))
		return rarities.randomElement()
	}()
	
	var uniqueCardCount: Int { Set(pack.mtgCards.compactMap { $0.name }).count }
	var allColorsCount: Int { Set(pack.mtgCards.compactMap { $0.colors }.joined()).count }
//	var showcaseOkay: Bool {
//		guard let showcaseRarity = includedShowcaseRarity, !showcaseRarities.values.joined().isEmpty else {
//			return true
//		}
//
//		// If the pack should contain a showcase, and there are showcase cards in the set,
//		// ensure that the pack actually does contain a showcase card.
//		return pack.mtgCards.filter { $0.typeLine?.contains("Basic") != true }.contains(where: { $0.frameEffects?.contains("showcase") == true && showcaseRarity.allowedRarities.contains($0.rarity) })
//	}
	var legendaryOkay: Bool {
		guard mode == .dominaria else { return true }
		return pack.mtgCards.contains { $0.typeLine?.lowercased().contains("legendary") == true && $0.typeLine?.lowercased().contains("creature") == true }
	}
	var futureSightOkay: Bool {
		guard mode == .futureSight else { return true }
		let futureCount = pack.mtgCards.reduce(into: 0) { (count, card) in
			if card.frame == "future" {
				count += 1
			}
		}
		return (5...10).contains(futureCount)
	}
	var correctColorCount: Int {
		if let seed = seed {
			return seed.colors.count
		} else {
			return 5
		}
	}
	var colorsOkay: Bool {
		return allColorsCount == correctColorCount
	}
	
	var midDFCOkay: Bool {
		guard mode == .mid else {
			return true
		}
		
		let containedDoubleFacedCards = pack.cards.filter { $0.card.layout == "transform" && !$0.isFoil }
		guard containedDoubleFacedCards.count == 2 else {
			return false
		}
		
		let commonCount = containedDoubleFacedCards.filter { $0.card.rarity == .common }.count
		let uncommonRareMythicCount = containedDoubleFacedCards.filter { $0.card.rarity == .uncommon || $0.card.rarity == .rare || $0.card.rarity == .mythic }.count
		
		guard commonCount == 1 && uncommonRareMythicCount == 1
			else {
			return false
		}
		return true
	}
	
	let landRarity: MTGCard.Rarity = {
		if mode == .strixhaven || mode == .mh2 {
			return includedStrixhavenArchiveRarity ?? .common
		}
		
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
	let landCount: Int = {
		if mode == .twoLands {
			return 2
		} else if mode == .doubleMasters {
			return 0
		} else {
			return 1
		}
	}()
	
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
		
		if mode == .vintageMasters || mode == .doubleMasters {
			nonTokenCount += 1
		}
		
		return nonTokenCount
	}()
	
	let shouldIncludeShowcaseLand = mode == .m21 && (1...7).randomElement() == 1 && basicLands.contains(where: { $0.isShowcase })
	
//	let shouldIncludeFoilBorderless = mode == .m21 && (1...35).randomElement() == 35 && !borderless.isEmpty
	
	let shouldIncludeBorderlessPlaneswalker: Bool = {
		guard !borderlessPlaneswalkers.isEmpty else { return false }
		return (1...126).randomElement() == 1
	}()
	
	let rareOrMythicShouldBeDoubleFaced: Bool = {
		guard mode == .mid else { return false }
		let doubleFacedRaresAndMythics: [MTGCard] = (rarities[.rare] ?? []) + (rarities[.mythic] ?? [])
		return doubleFacedRaresAndMythics.randomElement()?.layout == "transform"
	}()
	
	repeat {
		pack.removeAll()
		
		let lands: ArraySlice<MTGCard> = {
			if let seed = seed, seed.packtype == .grnRna, let guildgates = rarities[.common]?.filter({ $0.name == "\(seed.name) Guildgate" }) {
				return guildgates.choose(landCount)
			} else if let seed = seed, seed.packtype == .stx, let campuses = rarities[.common]?.filter({ $0.name == "\(seed.name) Campus" }) {
				return campuses.choose(landCount)
			}
			
			var lands = landRarities?[landRarity] ?? basicLands
			if shouldIncludeShowcaseLand {
				lands = lands.filter { $0.isShowcase }
			}
			return lands.choose(landCount)
		}()
		pack.insert(contentsOf: lands, at: 0)
		
		if shouldIncludeTimeshiftedFoil, let card = basicLands.randomElement() {
			pack.insert(card, at: 0, isFoil: true)
		}
		
		var foilCommonCount = 0
		
		if mode == .vintageMasters, (1...53).randomElement() == 53, let powerNine = customSlotRarities.values.joined().randomElement() {
			// 1 in 53 packs of vintage masters contain a power nine card. All other packs contain a foil.
			pack.insert(powerNine, at: 0)
		} else if includeMasterpiece, let masterpiece = masterpieceCards.randomElement() {
			pack.insert(masterpiece, at: 0, isFoil: true)
		} else if let rarity = includedFoilRarity, let foil = [(allRarities[rarity] ?? []), (customSlotRarities[rarity] ?? [])].joined().filter(\.isFoilAvailable).randomElement() {
			if includeExtendedArt, let extendedArtVersion = extendedArt.filter({ $0.name == foil.name }).randomElement() {
				pack.insert(extendedArtVersion, at: 0, isFoil: true)
			} else if rarity != .common || foilPolicy == .guaranteed {
				pack.insert(foil, at: 0, isFoil: true)
			} else {
				foilCommonCount += 1
			}
		}
		
		// Add a second foil to double masters packs.
		if mode == .doubleMasters, let rarity = includedFoilRarity, let foil = [(allRarities[rarity] ?? []), (customSlotRarities[rarity] ?? [])].joined().filter(\.isFoilAvailable).randomElement() {
			if includeExtendedArt, let extendedArtVersion = extendedArt.filter({ $0.name == foil.name }).randomElement() {
				pack.insert(extendedArtVersion, at: 0, isFoil: true)
			} else if rarity != .common || foilPolicy == .guaranteed {
				pack.insert(foil, at: 0, isFoil: true)
			} else {
				foilCommonCount += 1
			}
		}
		
		if shouldIncludeBorderlessPlaneswalker,
			let borderlessCard = borderlessPlaneswalkers.randomElement() {
			pack.insert(borderlessCard, at: 0)
		}
		
		let rareSlotRarities: [MTGCard.Rarity : [MTGCard]] = {
			if guaranteedPlaneswalkerSlot == 3 {
				return customSlotRarities
			}
			
			if let seed = seed {
				return rarities.mapValues { cards in
					return cards.filter { card in
						(card.cardFaces?.first?.watermark ?? card.watermark)?.lowercased() == seed.name.lowercased() || seed.matchesExactly(card)
					}
				}
			}
			
			return rarities
		}()
		
		func addRareOrMythic() {
			if zendikarRisingGuaranteedDFCRarity == .rare || zendikarRisingGuaranteedDFCRarity == .mythic {
				return
			}
			
			var showcareRareOrMythic: MTGCard? {
				var allShowcaseRaresAndMythics = Array([showcaseRarities[.rare], showcaseRarities[.mythic]].compactMap({ $0 }).joined())
				if rareOrMythicShouldBeDoubleFaced {
					allShowcaseRaresAndMythics = allShowcaseRaresAndMythics.filter { $0.layout == "transform" }
				}
				
				let availableShowcaseRareAndMythicNames = Set(allShowcaseRaresAndMythics.compactMap { $0.name })
				guard let chosenName = availableShowcaseRareAndMythicNames.randomElement() else { return nil }
				return allShowcaseRaresAndMythics.filter { $0.name == chosenName }.randomElement()
			}
			
			var rareSlotRarities = rareSlotRarities
			if rareOrMythicShouldBeDoubleFaced {
				rareSlotRarities = rareSlotRarities.mapValues { cards in
					cards.filter { $0.layout == "transform" }
				}
			}
			
			if shouldIncludeShowcaseRareOrMythic, let card = showcareRareOrMythic {
				pack.insert(card, at: 0)
				
				print("Including showcase \(card.rarity.rawValue): \(card.name ?? "")")
				
				if let partner = card.partner(from: rarities.values.joined()) {
					pack.insert(partner, at: 0)
				}
			} else if includeMythic, let mythic = rareSlotRarities[.mythic]?.randomElement() {
				pack.insert(mythic, at: 0)
				
				if let partner = mythic.partner(from: rarities.values.joined()) {
					pack.insert(partner, at: 0)
				}
			} else if let rare = rareSlotRarities[.rare]?.randomElement() {
				pack.insert(rare, at: 0)
				
				if let partner = rare.partner(from: rarities.values.joined()) {
					pack.insert(partner, at: 0)
				}
			}
		}
		
		if let rarity = zendikarRisingGuaranteedDFCRarity {
			// Add a modal double-faced card to ZNR packs.
			print("Adding a \(rarity.rawValue) DFC")
			if let dfc = allRarities[rarity]?.shuffled().first(where: { $0.layout == "modal_dfc" }) {
				pack.insert(dfc, at: 0)
			} else {
				print("Coudln't find one!")
			}
		}
		
		addRareOrMythic()
		
		// Add a second rare or mythic to double masters packs
		if mode == .doubleMasters {
			addRareOrMythic()
		}
		
		let neoDFC: MTGCard? = {
			guard mode == .neo else { return nil }
			return customSlotRarities.values.joined().randomElement()
		}()
		
		if let card = neoDFC, card.rarity == .uncommon {
			pack.insert(card, at: 0)
		}
		
		let showcaseCommonOrUncommon: MTGCard? = {
			guard shouldIncludeShowcaseCommonOrUncommon else { return nil }
			
			let allShowcaseCommonsAndUncommons = [showcaseRarities[.common], showcaseRarities[.uncommon]].compactMap { $0 }.joined()
			let availableShowcaseCommonAndUncommonNames = Set(allShowcaseCommonsAndUncommons.compactMap { $0.name }) // This makes cards with multiple showcase styles equally likely to appear. Then, a random showcase card with the chosen name is selected.
			
			guard let chosenName = availableShowcaseCommonAndUncommonNames.randomElement() else { return nil }
			return allShowcaseCommonsAndUncommons.filter { $0.name == chosenName }.randomElement()
		}()
		
		// TODO: Check actual distribution of lessons in the lesson slot. Does each lesson card appear as frequently as the others, or does the rarity matter?
		if mode == .strixhaven {
			if let seed = seed, seed.packtype == .stx {
				let mascotName: String? = {
					switch Set(seed.colors) {
					case [.blue, .red]: return "Elemental"
					case [.green, .blue]: return "Fractal"
					case [.white, .black]: return "Inkling"
					case [.black, .green]: return "Pest"
					case [.red, .white]: return "Spirit"
					default: return nil
					}
				}()
				if let name = mascotName, let mascot = customSlotRarities.values.joined().first(where: { $0.name == "\(name) Summoning" }) {
					pack.insert(mascot, at: 0)
				}
			} else if let lesson = customSlotRarities.values.joined().randomElement() {
				pack.insert(lesson, at: 0, isFoil: false)
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
			
			if pack.mtgCards.contains(where: \.hasPartner) {
				base -= 1
			}
			
			if zendikarRisingGuaranteedDFCRarity == .uncommon {
				base -= 1
			}
			
			return base
		}()
		
//		var uncommons = rarities[.uncommon]?.choose(uncommonCount) ?? []
		var uncommons: [MTGCard] = {
			var uncommons: [MTGCard] = []
			
			if let showcaseCommonOrUncommon = showcaseCommonOrUncommon, showcaseCommonOrUncommon.rarity == .uncommon {
				uncommons.append(showcaseCommonOrUncommon)
			}
			
			while uncommons.count < uncommonCount {
				var card: MTGCard
				
				var cardIsValid: Bool {
					if card.hasPartner && (pack.mtgCards.contains(where: \.hasPartner) || uncommons.contains(where: \.hasPartner)) {
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
		
		if mode == .mid {
			let doubleFaced = uncommons.separateAll { $0.layout == "transform" }
			uncommons.append(contentsOf: doubleFaced)
		}
		
		pack.insert(contentsOf: uncommons, at: 0)
		
		if let card = neoDFC, card.rarity == .common {
			pack.insert(card, at: 0)
		}
		
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
		
		if let seed = seed, seed.packtype == .grnRna, let locket = rarities[.common]?.first(where: { $0.name == "\(seed.name) Locket" }) {
			pack.insert(locket, at: 0)
		} else if let seed = seed, seed.packtype == .stx, let pledgemage = rarities[.common]?.first(where: { $0.name == "\(seed.name) Pledgemage" }) {
			pack.insert(pledgemage, at: 0)
		}
		
		let commonCount: Int = {
			var count = cardCount-pack.count
			if !tokens.isEmpty {
				count -= 1
			}
			if showcaseCommonOrUncommon?.rarity == .common {
				count -= 1
			}
			return count
		}()
		var commons: [MTGCard] = []
		if let showcaseCommonOrUncommon = showcaseCommonOrUncommon, showcaseCommonOrUncommon.rarity == .common {
			commons.append(showcaseCommonOrUncommon)
		}
		if let chosenCommons = rarities[.common]?.choose(commonCount) {
			commons.append(contentsOf: chosenCommons)
		}
		
		commons.shuffle()
		
		if mode == .mid {
			let doubleFaced = commons.separateAll { $0.layout == "transform" }
			commons.append(contentsOf: doubleFaced)
		}
		
		pack.insert(contentsOf: commons, at: 0)
		
		if foilCommonCount > 0 {
			let foilCardIndices: [Int] = pack.cards.enumerated().compactMap {
				guard $0.element.card.rarity == .common && $0.element.card.isFoilAvailable else {
					return nil
				}
				return $0.offset
			}
			for index in foilCardIndices.choose(foilCommonCount) {
				pack.cards[index].isFoil = true
			}
		}
		
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
				let cardsToLookAt: [MTGCard] = pack.mtgCards + pack.mtgCards.compactMap { card in
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
				
				pack.append(token)
			}
		}
		
//		if shouldIncludeShowcaseCommonOrUncommon {
//			let showcaseCards: [(Int, MTGCard)] = pack.mtgCards.filter({ $0.frameEffects?.contains("extendedart") != true }).enumerated().compactMap { (index, card) in
//				guard let showcaseCard = [MTGCard.Rarity.common, .uncommon].compactMap({ showcaseRarities[$0] }).joined().filter({ $0.name == card.name }).randomElement() else { return nil }
//
//				guard [MTGCard.Rarity.common, .uncommon].contains(showcaseCard.rarity) else {
//					return nil
//				}
//
//				return (index, showcaseCard)
//			}
//
//			if let (index, showcaseCard) = showcaseCards.filter({ mode != .m21 ? $0.1.typeLine?.contains("Planeswalker") != true : true }).randomElement() {
//				pack.replace(at: index, with: showcaseCard)
//			}
//		}
		
		// TODO: Move gauranteed legendary to the back of the pack for Dominaria. (Currently it just checks if at least one card in the pack is legendary.)
		
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
		
		if !colorsOkay {
			problems.append("Pack doesn't have correct number of colors")
		}
		if uniqueCardCount != cardCount {
			problems.append("Unique card count is wrong; Should be \(cardCount), was \(uniqueCardCount)")
		}
		if !futureSightOkay {
			problems.append("Future sight isn't satisfied")
		}
//		if !showcaseOkay {
//			problems.append("No showcase card")
//		}
		if !legendaryOkay {
			problems.append("No legendary card")
		}
		
		if !midDFCOkay {
			problems.append("MID DFC is wrong")
		}
		
		if !problems.isEmpty {
			print(problems.joined(separator: ", "))
		}
		
	} while !colorsOkay || uniqueCardCount != cardCount || !futureSightOkay /* || !showcaseOkay */ || !legendaryOkay || !midDFCOkay
	
	print("Using pack")
	
	return pack
}

struct CommanderLegendsProcessed: Hashable, Equatable {
	var rarities: [MTGCard.Rarity: [MTGCard]] = [:]
	var legendRarities: [MTGCard.Rarity: [MTGCard]] = [:]
	var borderlessPlaneswalkers: [MTGCard] = []
	var etchedFoils: [MTGCard] = []
	var extendedArt: [MTGCard] = []
	var tokens: [MTGCard] = []
	var prismaticPiper: MTGCard?
}

func processCommanderLegendsCards(_ cards: [MTGCard], tokens: [MTGCard]) -> CommanderLegendsProcessed {
	var processed = CommanderLegendsProcessed()
	
	var cards = cards
	
	if let piperID = UUID(uuidString: "a69e6d8f-f742-4508-a83a-38ae84be228c"),
	   let index = cards.firstIndex(where: { $0.scryfallID == piperID }) {
		processed.prismaticPiper = cards.remove(at: index)
	}
	
	processed.etchedFoils = cards.separateAll(where: { $0.frameEffects.contains("etched") })
	processed.extendedArt = cards.separateAll(where: { $0.frameEffects.contains("extendedart") })
	processed.borderlessPlaneswalkers = cards.separateAll(where: { $0.borderColor == .borderless })
	
	cards.removeAll(where: { !$0.isFoundInBoosters })
	
	let legends = cards.separateAll {
		guard let typeLine = $0.typeLine?.lowercased() else { return false }
		return typeLine.contains("legendary") && (typeLine.contains("creature") || typeLine.contains("planeswalker"))
	}
	
	processed.rarities = .init(grouping: cards, by: \.rarity)
	processed.legendRarities = .init(grouping: legends, by: \.rarity)
	
	processed.tokens = tokens
	
	return processed
}

struct CardCollection {
	struct CardSelection {
		var card: MTGCard
		var isFoil: Bool
		
		init(_ card: MTGCard, isFoil: Bool = false) {
			self.card = card
			self.isFoil = isFoil
		}
	}
	
	var cards: [CardSelection] = []
	
	var mtgCards: [MTGCard] {
		cards.map(\.card)
	}
	
	mutating func insert(_ card: MTGCard, at index: Int, isFoil: Bool = false) {
		let selection = CardSelection(card, isFoil: isFoil)
		cards.insert(selection, at: index)
	}
	
	mutating func insert<S: Sequence>(contentsOf collection: S, at index: Int, cardsAreFoil: Bool = false) where S.Element == MTGCard {
		let selections = collection.map { CardSelection($0, isFoil: cardsAreFoil) }
		cards.insert(contentsOf: selections, at: index)
	}
	
	mutating func append(_ card: MTGCard, isFoil: Bool = false) {
		let selection = CardSelection(card, isFoil: isFoil)
		cards.append(selection)
	}
	
	mutating func append<S: Sequence>(contentsOf collection: S, cardsAreFoil: Bool = false) where S.Element == MTGCard {
		let selections = collection.map { CardSelection($0, isFoil: cardsAreFoil) }
		cards.append(contentsOf: selections)
	}
	
	mutating func removeAll() {
		cards.removeAll()
	}
	
	@discardableResult mutating func remove(at index: Int) -> MTGCard  {
		let selection = cards.remove(at: index)
		return selection.card
	}
	
	var count: Int {
		cards.count
	}
	
	mutating func reverse() {
		cards.reverse()
	}
	
	subscript(_ index: Int) -> MTGCard {
		cards[index].card
	}
	
	mutating func replace(at index: Int, with card: MTGCard, isFoil: Bool = false) {
		let selection = CardSelection(card, isFoil: isFoil)
		cards[index] = selection
	}
}

func generateCommanderLegendsPack(_ processed: CommanderLegendsProcessed) -> CardCollection {
	var pack = CardCollection()
	
	let selectedLegendRarities: [MTGCard.Rarity: Int] = {
		let raritiesAndWeights: [[MTGCard.Rarity: Int]: Double] = [
			[.uncommon: 2]: 76,
			[.uncommon: 1, .rare: 1]: 46,
			[.rare: 2]: 8,
			[.uncommon: 1, .mythic: 1]: 5,
			[.rare: 1, .mythic: 1]: 2
		]
		var result = raritiesAndWeights.keys.first!
		let sum = raritiesAndWeights.values.reduce(0, +)
		var value = Double.random(in: 1..<sum)
		for (rarities, weight) in raritiesAndWeights {
			value -= weight
			result = rarities
			if value <= 0 {
				break
			}
		}
		return result
	}()
	
	let shouldIncludeMythic = (1...100).randomElement()! >= 74
	let foilRarities: [MTGCard.Rarity: [MTGCard]] = {
		let foilEtchedReprints = processed.etchedFoils.filter {
			guard let number = Int($0.collectorNumber) else {
				return false
			}
			
			return number <= 546
		}
		var rarities: [MTGCard.Rarity: [MTGCard]] = [:]
		
		for rarity in MTGCard.Rarity.allCases {
			var cards: [MTGCard] = []
			cards.append(contentsOf: processed.rarities[rarity] ?? [])
			cards.append(contentsOf: processed.legendRarities[rarity] ?? [])
			
			// Fix for correct rarities.
			// Half of all legendary creature foils in packs should be etched, so, add the regular cards, and reprint etched legends, a second time to make up for it.
			cards.append(contentsOf: processed.rarities[rarity] ?? [])
			
			if rarity == .mythic {
				cards.append(contentsOf: foilEtchedReprints)
				cards.append(contentsOf: processed.borderlessPlaneswalkers)
			}
			
			rarities[rarity] = cards
		}
		
		return rarities
	}()
	let includedFoilRarity: MTGCard.Rarity = {
		let rarityValue = (1...1000).randomElement()!
		switch rarityValue {
		case 1...500: return .common
		case 1...833: return .uncommon
		case 1...979: return .rare
		default: return .mythic
		}
	}()
	let shouldIncludePrismaticPiper = (1...6).randomElement() == 6
	var packOkay: Bool {
		var problems: [String] = []
		
		let cardCount = 20
		var uniqueCardCount: Int { Set(pack.mtgCards.compactMap { $0.name }).count }
		var allColorsCount: Int { Set(pack.mtgCards.compactMap { $0.colors }.joined()).count }
		
		if allColorsCount != 5 {
			problems.append("Pack doesn't have 5 colors")
		}
		if uniqueCardCount != cardCount {
			problems.append("Unique card is wrong; Should be \(cardCount), was \(uniqueCardCount)")
		}
		
		if !problems.isEmpty {
			print(problems.joined(separator: ", "))
		}
		
		return problems.isEmpty
	}
	
	// Generate
	
	repeat {
		pack.removeAll()
		
		if shouldIncludePrismaticPiper, let piper = processed.prismaticPiper {
			pack.insert(piper, at: 0)
		}
		
		let commons = processed.rarities[.common]?.choose(13-pack.count) ?? []
		pack.insert(contentsOf: commons, at: 0)
		
		let uncommons = processed.rarities[.uncommon]?.choose(3) ?? []
		pack.insert(contentsOf: uncommons, at: 0)
		
		if let rare = processed.rarities[shouldIncludeMythic ? .mythic : .rare]?.randomElement() {
			pack.insert(rare, at: 0)
		}
		
		for (rarity, count) in selectedLegendRarities {
			let cards = processed.legendRarities[rarity]?.choose(count) ?? []
			pack.insert(contentsOf: cards, at: 0)
		}
		
		if .random(),
		   let planeswalkerIndex = pack.mtgCards.firstIndex(where: { cardInPack in processed.borderlessPlaneswalkers.contains(where: { borderlessCard in borderlessCard.oracleID == cardInPack.oracleID }) }),
		   let borderlessPlaneswalker = processed.borderlessPlaneswalkers.first(where: { $0.oracleID == pack[planeswalkerIndex].oracleID }) {
			pack.replace(at: planeswalkerIndex, with: borderlessPlaneswalker)
		}
		
		if let foil = foilRarities[includedFoilRarity]?.randomElement() {
			// New legendary creature foils have a 50% chance to be etched foil.
			// If a new legendary creature is chosen, 50% chance to add its etched foil version instead.
			if .random(), !foil.frameEffects.contains("etched"), let etchedVersion = processed.etchedFoils.first(where: { $0.oracleID == foil.oracleID }) {
				pack.insert(etchedVersion, at: 0, isFoil: true)
			} else if let extendedArt = processed.extendedArt.first(where: { $0.name == foil.name }) {
				pack.insert(extendedArt, at: 0, isFoil: true)
			} else {
				pack.insert(foil, at: 0, isFoil: true)
			}
		}
		
	} while !packOkay
	
	pack.reverse()
	
	// Add token
	
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
	
	guard !processed.tokens.isEmpty else {
		return pack
	}
	
	var availableTokens: [MTGCard] = []
	
	let uniqueTokens: [MTGCard] = {
		var uniqueTokens: [MTGCard] = []
		
		for token in processed.tokens {
			if !uniqueTokens.contains(where: { tokensAreEqual(token, $0) }) {
				uniqueTokens.append(token)
			}
		}
		
		return uniqueTokens
	}()
	
	for token in uniqueTokens {
		let cardsToLookAt: [MTGCard] = pack.mtgCards
		
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
		availableTokens = processed.tokens
	}
	
	if var token = availableTokens.randomElement() {
		token = processed.tokens.shuffled().first(where: { tokensAreEqual(token, $0) })!
		
		pack.append(token)
	}
	
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

func generateMysteryBooster(cards: [MysterBoosterSlot: [MTGCard]]) -> CardCollection {
	var pack = CardCollection()
	
	var uniqueCardCount: Int { Set(pack.mtgCards.compactMap { $0.name }).count }
	var allColorsCount: Int { Set(pack.mtgCards.compactMap { $0.colors }.joined()).count }
	
	repeat {
		pack.removeAll()
		
		for color: MTGColor in [.white, .blue, .black, .red, .green] {
			let colorCommonUncommons = cards[.monocolorCommonUncommon(color)]?.choose(2) ?? []
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
			pack.append(foil, isFoil: true)
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

func generatePlanarChaosPack(normalRarities: [MTGCard.Rarity: [MTGCard]], colorshiftedRarities: [MTGCard.Rarity: [MTGCard]]) -> CardCollection {
	var pack = CardCollection()
	
	var uniqueCardCount: Int { Set(pack.mtgCards.compactMap { $0.name }).count }
	var allColorsCount: Int { Set(pack.mtgCards.compactMap { $0.colors }.joined()).count }
	
	repeat {
		pack.removeAll()
		
		if let commons = normalRarities[.common]?.choose(8) {
			pack.append(contentsOf: commons)
		}
		
		if let uncommons = normalRarities[.uncommon]?.choose(2) {
			pack.append(contentsOf: uncommons)
		}
		
		if let rare = normalRarities[.rare]?.randomElement() {
			pack.append(rare)
		}
		
		if let colorshiftedCommons = colorshiftedRarities[.common]?.choose(3) {
			pack.append(contentsOf: colorshiftedCommons)
		}
		
		if let colorshiftedUncommons = colorshiftedRarities[.uncommon], let colorshiftedRares = colorshiftedRarities[.rare] {
			let all = colorshiftedUncommons + colorshiftedRares
			if let colorshiftedUncommonOrRare = all.randomElement() {
				pack.append(colorshiftedUncommonOrRare)
			}
		}
	} while allColorsCount != 5 || uniqueCardCount != 15
	
	return pack
}



struct DoubleFeatureProcessed: Hashable, Equatable {
	var midRarities: [MTGCard.Rarity: [MTGCard]] = [:]
	var vowRarities: [MTGCard.Rarity: [MTGCard]] = [:]
}

func processDoubleFeatureCards(_ cards: [MTGCard]) -> DoubleFeatureProcessed {
	var vowCards = cards
	vowCards.removeAll { $0.isPromo }
	let midCards = vowCards.separateAll { card in
		guard let number = Int(card.collectorNumber) else { return false }
		return (1...267).contains(number)
	}
	
	return DoubleFeatureProcessed(
		midRarities: .init(grouping: midCards, by: \.rarity),
		vowRarities: .init(grouping: vowCards, by: \.rarity)
	)
}

func generateDoubleFeaturePack(_ processed: DoubleFeatureProcessed) -> CardCollection {
	var pack = CardCollection()
	
	var uniqueCardCount: Int { Set(pack.mtgCards.compactMap { $0.name }).count }
	var allColorsCount: Int { Set(pack.mtgCards.compactMap { $0.colors }.joined()).count }
	
	repeat {
		pack.removeAll()
		
		pack.append(contentsOf: processed.midRarities[.common]?.choose(4) ?? [])
		pack.append(contentsOf: processed.vowRarities[.common]?.choose(4) ?? [])
		
		pack.append(contentsOf: processed.midRarities[.uncommon]?.choose(2) ?? [])
		pack.append(contentsOf: processed.vowRarities[.uncommon]?.choose(2) ?? [])
		
		if (1...100).randomElement()! >= 74 {
			pack.append(contentsOf: processed.midRarities[.mythic]?.choose(1) ?? [])
		} else {
			pack.append(contentsOf: processed.midRarities[.rare]?.choose(1) ?? [])
		}
		
		if (1...100).randomElement()! >= 74 {
			pack.append(contentsOf: processed.vowRarities[.mythic]?.choose(1) ?? [])
		} else {
			pack.append(contentsOf: processed.vowRarities[.rare]?.choose(1) ?? [])
		}
		
		let includedFoilRarity: MTGCard.Rarity = {
			let rarityValue = (1...1000).randomElement()!
			switch rarityValue {
			case 1...500: return .common
			case 1...833: return .uncommon
			case 1...979: return .rare
			default: return .mythic
			}
		}()
		
		if let foilCard = ((processed.midRarities[includedFoilRarity] ?? []) + (processed.vowRarities[includedFoilRarity] ?? [])).randomElement() {
			pack.append(foilCard, isFoil: true)
		}
	} while allColorsCount != 5 || uniqueCardCount != 15
	
	return pack
}

let jumpstartDeckListURLs: [URL] = try! {
	#if canImport(Vapor)
	let directory = DirectoryConfiguration.detect()
	let jumpstartDirectory = "Sources/App/Generation/JumpStart"
	let jumpstartDirectoryURL = URL(fileURLWithPath: directory.workingDirectory)
		.appendingPathComponent(jumpstartDirectory, isDirectory: true)
	return try FileManager.default.contentsOfDirectory(at: jumpstartDirectoryURL, includingPropertiesForKeys: nil)
	#else
	guard let urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "JumpStart") else {
		throw PackError.unsupported
	}
	return urls
	#endif
}()

let superJumpDeckListURLs: [URL] = try! {
	#if canImport(Vapor)
	let directory = DirectoryConfiguration.detect()
	let jumpstartDirectory = "Sources/App/Generation/SuperJump"
	let jumpstartDirectoryURL = URL(fileURLWithPath: directory.workingDirectory)
		.appendingPathComponent(jumpstartDirectory, isDirectory: true)
	return try FileManager.default.contentsOfDirectory(at: jumpstartDirectoryURL, includingPropertiesForKeys: nil)
	#else
	guard let urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "SuperJump") else {
		throw PackError.unsupported
	}
	return urls
	#endif
}()

func jumpstartDeckList() throws -> String {
	guard let deckListURL = jumpstartDeckListURLs.randomElement() else {
		throw PackError.unsupported
	}
	
	return try String(contentsOf: deckListURL)
}

func superjumpDeckList() throws -> String {
	guard let deckListURL = superJumpDeckListURLs.randomElement() else {
		throw PackError.unsupported
	}
	
	return try String(contentsOf: deckListURL)
}

func generateJumpStartPack() throws -> CardCollection {
	guard let deckListURL = jumpstartDeckListURLs.randomElement() else {
		throw PackError.unsupported
	}
	
	let name = String(deckListURL.lastPathComponent.prefix(while: { !$0.isNumber && $0 != "." }).trimmingCharacters(in: .whitespacesAndNewlines))
	
	let faceCardIdentifier: MTGCardIdentifier = .nameSet(name: name, set: "fjmp")
	
	let contents = try String(contentsOf: deckListURL)
	let cardCounts = DeckParser.parse(deckList: contents, autofix: true).first?.cardCounts ?? []
	let identifiers: [MTGCardIdentifier] = [faceCardIdentifier] + cardCounts.map(\.identifier)
	let cards = try Swiftfall.getCollection(identifiers: identifiers).data
	
	var collection = CardCollection()
	if let faceCard = cards.first(where: { $0.set.lowercased() == "fjmp" }) {
		let mtgCard = MTGCard(faceCard)
		collection.append(mtgCard)
	}
	
	for cardCount in cardCounts.reversed() {
		guard let card = cards[cardCount.identifier] else { continue }
		let mtgCard = MTGCard(card)
		for _ in 0 ..< cardCount.count {
			collection.append(mtgCard)
		}
	}
	
	return collection
}

func generateSuperJumpPack() throws -> CardCollection {
	guard let deckListURL = superJumpDeckListURLs.randomElement() else {
		throw PackError.unsupported
	}
	
	let name = deckListURL.deletingPathExtension().lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
	print(name)
	
	let contents = try String(contentsOf: deckListURL)
	let cardCounts = DeckParser.parse(deckList: contents, autofix: true).first?.cardCounts ?? []
	let identifiers: [MTGCardIdentifier] = /*[faceCardIdentifier] + */cardCounts.map(\.identifier)
	let cards = try Swiftfall.getCollection(identifiers: identifiers).data
	
	let frontURL = URL(string: "http://josh.birnholz.com/tts/resources/superjump/\(name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!).jpg")!
	print(frontURL)
	
	var collection = CardCollection()
	let number = superJumpDeckListURLs.firstIndex(of: deckListURL) ?? 0
	let frontCardName = name
		.replacingOccurrences(of: "6", with: "VI")
		.replacingOccurrences(of: "5", with: "V")
		.replacingOccurrences(of: "4", with: "IV")
		.replacingOccurrences(of: "3", with: "III")
		.replacingOccurrences(of: "2", with: "II")
		.replacingOccurrences(of: "1", with: "I")
	let faceCard = MTGCard(name: frontCardName, layout: "token", frame: "", isFullArt: true, collectorNumber: "\(number)", set: "fsjm", rarity: .common, scryfallCardBackID: nil, isFoilAvailable: false, isNonFoilAvailable: false, isPromo: false, isFoundInBoosters: false, language: .english, imageUris: ["normal": frontURL])
	collection.append(faceCard)
	
	for cardCount in cardCounts.reversed() {
		guard let card = cards[cardCount.identifier] else { continue }
		let mtgCard = MTGCard(card)
		for _ in 0 ..< cardCount.count {
			collection.append(mtgCard)
		}
	}
	
	return collection
}

fileprivate struct CardInfo {
	private static let defaultBack = URL(string: "https://img.scryfall.com/card_backs/image/normal/0a/0aeebaf5-8c7d-4636-9e82-8c27447861f7.jpg")!
	private static let tokenBack = URL(string: "http://josh.birnholz.com/tts/tback.jpg")!
	private static let jumpstartBack = URL(string: "http://josh.birnholz.com/tts/resources/jumpstartback.jpg")!
	
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
		  "Nickname": "\(nickname.replacingOccurrences(of: "\"", with: "\\\""))",
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
		let backID = card.scryfallCardBackID ?? UUID(uuidString: "0AEEBAF5-8C7D-4636-9E82-8C27447861F7")!
		
		let backURL: URL = URL(string: "https://c1.scryfall.com/file/scryfall-card-backs/normal/\(backID.uuidString.lowercased().prefix(2))/\(backID.uuidString.lowercased()).jpg") ?? Self.defaultBack
		
		/* if card.layout == "transform", let faces = card.cardFaces, faces.count == 2,
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
			
		} else */
		
		if (card.layout == "transform" || card.layout == "modal_dfc"), let faces = card.cardFaces, faces.count >= 2, let faceURL = faces[0].imageUris?["normal"] ?? faces[0].imageUris?["large"], let backFaceURL = faces[1].imageUris?["normal"] ?? faces[1].imageUris?["large"] {
			self.backURL = backURL
			
			let frontName = faces[0].name ?? ""
			let backName = faces[1].name ?? ""
			
			self.nickname = frontName
			self.description = "// \(backName)"
			
			var backState = CardInfo(faceURL: backFaceURL, backURL: Self.defaultBack, nickname: backName, description: "// \(frontName)", sideways: false)
			backState.state = 2
			otherStates = [backState]
			self.state = 1
			self.sideways = false
			self.backIsHidden = true
			
			self.faceURL = faceURL
		} else if let faceURL = card.imageUris?["normal"] ?? card.imageUris?["large"], card.layout == "meld", let result = card.allParts?.first(where: { $0.name != card.name && $0.component == .meldResult }), let backFaceURL = URL(string: "https://img.scryfall.com/card_backs/image/normal/\(backID.uuidString.lowercased().prefix(2))/\(backID.uuidString.lowercased()).jpg") {
			
			self.backURL = Self.defaultBack
			
			let frontName = card.name ?? ""
			let backName = result.name
			
			self.nickname = frontName
			self.description = "// \(backName)"
			
			var backState = CardInfo(faceURL: backFaceURL, backURL: Self.defaultBack, nickname: backName, description: "// \(frontName)", sideways: false)
			backState.state = 2
			otherStates = [backState]
			self.state = 1
			self.sideways = false
			self.backIsHidden = true
			
			self.faceURL = faceURL
			
		}/* else if let faceURL = card.imageUris?["normal"] ?? card.imageUris?["large"], card.layout == "meld", let result = card.allParts?.first(where: { $0.name != card.name && $0.component == .meldResult }), let backFaceURL = URL(string: "https://img.scryfall.com/card_backs/image/normal/\(backID.uuidString.lowercased().prefix(2))/\(backID.uuidString.lowercased()).jpg") {
			self.backURL = backURL
			
			let frontName = card.name ?? ""
			let backName = result.name
			
			self.nickname = frontName
			self.description = "// \(backName)"
			
			var backState = CardInfo(faceURL: backFaceURL, backURL: Self.defaultBack, nickname: backName, description: "// \(frontName)", sideways: false)
			backState.state = 2
			otherStates = [backState]
			self.state = 1
			self.sideways = false
			self.backIsHidden = true
			
			self.faceURL = faceURL
		}*/ else if let faceURL = card.imageUris?["normal"] ?? card.imageUris?["large"] ?? card.cardFaces?.first?.imageUris?["normal"] ?? card.cardFaces?.first?.imageUris?["large"]  {
			self.faceURL = faceURL
			if card.layout == "double_faced_token", let faces = card.cardFaces, faces.count >= 2, let backFaceURL = faces[1].imageUris?["normal"] ?? faces[1].imageUris?["large"] {
				self.backURL = backFaceURL
				self.nickname = "\(faces[0].name ?? "") // \(faces[1].name ?? "")"
			} else {
				self.backURL = backURL
				self.nickname = card.printedName ?? card.name ?? ""
				self.backIsHidden = true
			}
			self.description = ""
			self.otherStates = []
			self.state = 1
			self.backIsHidden = !(card.layout.contains("token") || card.layout == "emblem")
			
			self.sideways = false
			
//			if card.layout == "split" {
//				if card.keywords.contains("Aftermath") {
//					self.sideways = false
//				} else if card.set == "cmb1" || card.set == "cmb2" {
//					self.sideways = false
//				} else {
//					self.sideways = true
//				}
//			} else {
//				self.sideways = false
//			}
		} else {
			return nil
		}
		
		if card.set == "jumpstartface" || card.set == "fjmp" {
			self.backURL = Self.jumpstartBack
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
				case keyword
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
				if otherCard.keywords != card.keywords {
					differences.append(.keyword)
				}
			}
			
			if differences.isEmpty {
				return card
			} else {
				if let subtypes = card.typeLine?.components(separatedBy: " — ").last, let name = card.name, subtypes != name {
					return card
				}
				
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
				
				if differences.contains(.keyword), let keywords = card.keywords {
					if keywords.count == 1, let first = keywords.first {
						nameParts.append("with \(first)")
					} else if keywords.count == 2 {
						nameParts.append("with \(keywords.joined(separator: " and "))")
					}
				}
				
				var newCard = card
				newCard.name = nameParts.joined(separator: " ")
				return newCard
			}
		}
		
		let renamedCurrentState = allStates[currentStateIndex]
		
		self.init(offset: offset, card: renamedCurrentState)
		
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
func boosterPackJSON(setName: String, setCode: String, name: String? = nil, cards: [MTGCard], tokens: [MTGCard] = [], inPack: Bool = true, cardBack: URL? = nil, nickname: String? = nil) throws -> ObjectStateJSON {
	
//	let cardInfo = Array(cards.enumerated().compactMap(CardInfo.init(offset:card:)))
	let cardInfo: [CardInfo] = cards.reversed().enumerated().compactMap { sequence in
		if (sequence.element.layout == "token" || sequence.element.layout == "emblem" || sequence.element.typeLine == "Card") && !tokens.isEmpty {
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
	  "Nickname": "\(nickname ?? (!inPack ? packName : ""))",
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
	}
	"""
	
	// function onObjectLeaveContainer(bag, object)\n    if (bag.getGUID() == self.getGUID()) then\n        destroyObject(bag)\n    end\nend
	
	return pack
}

func singleBoosterPack(setName: String, setCode: String, boosterPack: [MTGCard], tokens: [MTGCard], inPack: Bool? = nil, export: Bool, cardBack: URL? = nil, nickname: String? = nil) throws -> String {
	let boosterPackString: String
	
	if let inPack = inPack {
		boosterPackString = try boosterPackJSON(setName: setName, setCode: setCode, cards: boosterPack, tokens: tokens, inPack: inPack, cardBack: cardBack)
	} else {
		boosterPackString = try boosterPackJSON(setName: setName, setCode: setCode, cards: boosterPack, tokens: tokens, cardBack: cardBack, nickname: nickname)
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

func bag(objectStates: [ObjectStateJSON], nickname: String) -> ObjectStateJSON {
	return """
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
	  "Nickname": "\(nickname)",
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
		\(objectStates.joined(separator: ",\n"))
	  ],
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
	}
	"""
}

func wrapObjectStateInSaveFile(_ objectState: ObjectStateJSON) -> String {
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

func boosterBag(setName: String, setCode: String, boosterPacks: [[MTGCard]], names: [String?]? = nil, tokens: [MTGCard], inPack: Bool = true, export: Bool, cardBack: URL? = nil) throws -> String {
	
	let names: [String?] = names ?? Array(repeating: String?.none, count: boosterPacks.count)
	let packs = zip(boosterPacks, names)
	let boosterPacks: [ObjectStateJSON] = try packs.map { cards, name in
		if cards.count == 1, let card = cards.first {
			return try singleCard(card, tokens: tokens, facedown: false, export: false)
		} else {
			return try boosterPackJSON(setName: setName, setCode: setCode, name: name, cards: cards, tokens: tokens, inPack: inPack, cardBack: cardBack)
		}
	}
	
	let objectState = bag(objectStates: boosterPacks, nickname: setName)
	
	if !export {
		return objectState
	}
	
	return wrapObjectStateInSaveFile(objectState)
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())",
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
	}
  ],
  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
}
"""

func prereleasePack(setName: String, setCode: String, boosterPacks: [[MTGCard]], promoCard: MTGCard, tokens: [MTGCard], basicLands: [MTGCard], includePromoCard: Bool?, includeLands: Bool?, includeSheet: Bool?, includeSpindown: Bool?, export: Bool, seed: Seed?) throws -> String {
	let includeSheet = includeSheet ?? true
	let includeSpindown = includeSpindown ?? true
	let includeLands = includeLands ?? true
	let includePromoCard = includePromoCard ?? true
	
	var name = setName
	if let seed = seed {
		name += " — \(seed.name)"
	}
	
	let boosterPackString = try boosterPacks.enumerated().map { index, cards in
		return try boosterPackJSON(setName: index == 0 ? name : setName, setCode: setCode, cards: cards, tokens: tokens, inPack: index == 0 && seed != nil ? false : true)
	}.joined(separator: ",\n")
	let promoCardString = try singleCard(promoCard, facedown: false)
	
	var containedObjects: [String] = []
	
	if includeSpindown {
		containedObjects.append(spindownDieJSON(setCode: seed?.name.lowercased() ?? setCode))
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
	
	var boxTextureName = seed?.name.lowercased() ?? setCode
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
	  "Nickname": "\(name) Prerelease Pack",
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
	  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
	}
	"""
	
	if !export {
		return objectState
	}
	
	return wrapObjectStateInSaveFile(objectState)
}

func allLandPacksSingleJSON(setCards: (cards: [MTGCard], setCode: String)?, specialOptions: [String], export: Bool) throws -> String {
	let lands: [MTGCard] = try {
		if let (cards, setCode) = setCards {
			let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: true)
			return processed.basicLands
		} else {
			return Swiftfall
			.getCards(query: "type='basic land –' is:highres", unique: false)
			.compactMap { $0?.data }
			.joined()
			.compactMap(MTGCard.init)
		}
	}()
	
	let landPacks = try landPacksJSON(basicLands: lands).reversed()
	
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
		  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
}
"""



fileprivate func customSetJSONURL(forSetCode inputString: String) -> URL? {
	let customSets = [
		"netropolis": "net",
		"amonkhet remastered": "akr",
		"hollows of lordran": "hlw"
	]
	
	guard let customsetcode = customSets[inputString.lowercased()] ?? customSets.values.first(where: { $0 == inputString.lowercased() }) else {
		return nil
	}
	
	#if canImport(Vapor)
	let directory = DirectoryConfiguration.detect()
	let configDir = "Sources/App/Generation"
	return URL(fileURLWithPath: directory.workingDirectory)
		.appendingPathComponent(configDir, isDirectory: true)
		.appendingPathComponent("custommtg-\(customsetcode).json", isDirectory: false)
	#else
	return Bundle.main.url(forResource: "custommtg-\(customsetcode)", withExtension: "json")
	#endif
}

public func generate(input: Input, inputString: String, output: Output, export: Bool, boxCount: Int? = nil, prereleaseIncludePromoCard: Bool? = nil, prereleaseIncludeLands: Bool? = nil, prereleaseIncludeSheet: Bool? = nil, prereleaseIncludeSpindown: Bool? = nil, prereleaseBoosterCount: Int? = nil, includeExtendedArt: Bool, includeBasicLands: Bool, includeTokens: Bool, specialOptions: [String] = [], cardBack: URL? = nil, autofixDecklist: Bool, outputFormat: OutputFormat, seed: Seed? = nil) throws -> String {
	let mtgCards: [MTGCard]
	let setName: String
	let setCode: String?
	let tokens: [MTGCard]
	var foilPolicy: FoilPolicy = .modern
	var mythicPolicy: MythicPolicy = .postM21
	
	checkInput: switch input {
	case .mtgCardJSON:
		var allCards: [MTGCard]
		
		let data = inputString.data(using: .utf8)!
		let decoder = JSONDecoder()
		
		let set = try decoder.decode(MTGSet.self, from: data)
		setName = set.name
		setCode = set.code
		
		allCards = set.cards
		
		if setCode?.lowercased() == "net" {
			mythicPolicy = .previous
		}
		
		if includeTokens {
			tokens = allCards.separateAll { $0.layout == "token" || $0.typeLine?.lowercased().contains("emblem") == true || $0.typeLine?.lowercased().contains("token") == true }
		} else {
			tokens = []
		}
		
		mtgCards = allCards
//	case .scryfallSetCode where inputString.lowercased() == "takr":
//		let cards = Swiftfall.getCards(query: "(set:takh -cn:5 -cn:6 -cn:7 -cn:11 -cn:13 -cn:14 -cn:26 -cn:27) or (set:thou -cn:1 -cn:3 -cn:5 -cn:7 -cn:8 -cn:11 -cn:13 -cn:14) or (set:tm15 cn:10) or (set:tsoi cn:17)").compactMap { $0?.data }.joined().map(MTGCard.init)
//
//		let encoder = JSONEncoder()
//		encoder.outputFormatting = .prettyPrinted
//		let data = try encoder.encode(cards)
//		let string = String(data: data, encoding: .utf8)!
//		print(string)
//
//		return string
	case .scryfallSetCode:
		if let url = customSetJSONURL(forSetCode: inputString), let data = try? Data(contentsOf: url), let string = String(data: data, encoding: .utf8) {
			return try generate(input: .mtgCardJSON, inputString: string, output: output, export: export, boxCount: boxCount, prereleaseIncludePromoCard: prereleaseIncludePromoCard, prereleaseIncludeLands: prereleaseIncludeLands, prereleaseIncludeSheet: prereleaseIncludeSheet, prereleaseIncludeSpindown: prereleaseIncludeSpindown, prereleaseBoosterCount: prereleaseBoosterCount, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, autofixDecklist: autofixDecklist, outputFormat: outputFormat, seed: seed)
		}
		if inputString.lowercased() == "sjm" {
			mtgCards = [MTGCard.init(layout: "", frame: "", isFullArt: false, collectorNumber: "", set: "", rarity: .common, isFoilAvailable: false, isNonFoilAvailable: false, isPromo: false, isFoundInBoosters: false, language: .english)]
			setName = "SuperJump!"
			setCode = "SJM"
			tokens = []
			break
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
		
		if setCode?.lowercased() == "vma" || setCode?.lowercased() == "2xm" {
			foilPolicy = .guaranteed
		} else {
			let foilCutoff = Date(timeIntervalSince1970: 1562889600) // Sets released after this date use the modern foil policy.
			if let releaseDate = set.releasedAt, releaseDate < foilCutoff {
				foilPolicy = .pre2020
			}
		}
		
		let mythicCutoff = Date(timeIntervalSince1970: 1596088604) // Sets released after Sept. 2020, starting with Zendikar Rising, use the new mythic rare policy
		if let releaseDate = set.releasedAt, releaseDate < mythicCutoff {
			mythicPolicy = .previous
		}
	case .cardlist:
		return try deck(.arena(inputString), export: export, cardBack: cardBack, autofix: autofixDecklist, customOverrides: [])
	}
	
	guard !mtgCards.isEmpty else { throw PackError.noCards }
	
	let mode: Mode = {
		switch setCode?.lowercased() {
		case "dom": return .dominaria
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
		case "m21": return .m21
		case "2xm": return .doubleMasters
		case "znr": return .zendikarRising
		case "eld", "thb": return .originalShowcase
		case "tsr": return .timeSpiralRemastered
		case "stx": return .strixhaven
		case "mh2": return .mh2
		case "mid", "vow": return .mid
		case "neo": return .neo
		default: return .default
		}
	}()
	
	switch output {
	case .boosterBox:
		return try boosterBox(setName: setName, cards: mtgCards, tokens: tokens, setCode: setCode, mode: mode, export: export, boxCount: boxCount, includeExtendedArt: includeExtendedArt, foilPolicy: foilPolicy, mythicPolicy: mythicPolicy, specialOptions: specialOptions, includeBasicLands: includeBasicLands, includeTokens: includeTokens, outputFormat: outputFormat)
	case .commanderBoxingLeagueBox:
		return try commanderBoxingLeagueBox(setName: setName, cards: mtgCards, tokens: tokens, setCode: setCode, mode: mode, export: export, boxCount: boxCount, includeExtendedArt: includeExtendedArt, foilPolicy: foilPolicy, mythicPolicy: mythicPolicy, specialOptions: specialOptions, includeBasicLands: includeBasicLands, includeTokens: includeTokens)
	case .boosterPack:
		return try boosterPack(setName: setName, cards: mtgCards, tokens: tokens, setCode: setCode, mode: mode, export: export, includeExtendedArt: includeExtendedArt, foilPolicy: foilPolicy, mythicPolicy: mythicPolicy, specialOptions: specialOptions, includeBasicLands: includeBasicLands, includeTokens: includeTokens, outputFormat: outputFormat, seed: seed)
	case .prereleaseKit:
		return try prereleaseKit(setName: setName, setCode: setCode ?? mtgCards.first?.set ?? inputString, cards: mtgCards, tokens: tokens, mode: mode, export: export, packCount: boxCount, includePromoCard: prereleaseIncludePromoCard, includeLands: prereleaseIncludeLands, includeSheet: prereleaseIncludeSheet, includeSpindown: prereleaseIncludeSpindown, boosterCount: prereleaseBoosterCount, includeExtendedArt: includeExtendedArt, foilPolicy: foilPolicy, mythicPolicy: mythicPolicy, specialOptions: specialOptions, outputFormat: outputFormat, seed: seed)
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
	var borderlessCards: [MTGCard]
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
		case "iko", "m21", "neo":
			let basicLands = mainCards.separateAll { $0.typeLine?.lowercased().contains("basic") == true && $0.typeLine?.lowercased().contains("land") == true }
			guard includeBasicLands else { return [] }
			let dualLands = mainCards.separateAll { $0.typeLine?.lowercased().contains("land") == true && $0.oracleText?.contains("enters the battlefield tapped") == true && $0.oracleText?.contains("gain 1 life") == true }
			return basicLands + dualLands
		case "akr":
			guard includeBasicLands else { return [] }
			return Swiftfall
				.getCards(query: "set:akh,hou type:'basic land'", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "znr":
			let basicLands = mainCards.separateAll { ($0.typeLine ?? "").contains("Basic") == true && ($0.typeLine ?? "").contains("Land") == true }
			guard includeBasicLands else { return [] }
			return basicLands.filter { $0.isFullArt }
		case "khm":
			guard includeBasicLands else { return [] }
			let snowLands = mainCards.separateAll { ($0.typeLine ?? "").contains("Snow") == true && ($0.typeLine ?? "").contains("Land") == true && !($0.colorIdentity ?? []).isEmpty }
			return snowLands
		case "mir", "vis", "5ed", "por", "wth", "tmp", "sth", "exo", "p02", "usg", "ulg", "6ed", "ptk", "uds", "mmq", "nem", "pcy", "inv", "pls", "7ed", "csp", "dis", "gpt", "rav", "9ed", "lrw", "mor", "shm", "eve", "apc", "ody", "tor", "jud", "ons", "lgn", "scg", "mrd", "dst", "5dn", "chk", "bok", "sok", "plc", "2xm":
			return []
		case "tsr":
			return mainCards.separateAll(where: { $0.rarity == .special })
		case "stx":
			return Swiftfall
				.getCards(query: "set:sta lang:en", unique: true)
				.compactMap { $0?.data }
				.joined()
				.map {
					var card = MTGCard($0)
					card.isFoundInBoosters = true
					return card
				}
		case "mh2":
			return mainCards.separateAll(where: { $0.watermark == "set" })
		case "vow":
			let basicLands = mainCards.separateAll { ($0.typeLine ?? "").contains("Basic") == true && ($0.typeLine ?? "").contains("Land") == true }
			guard includeBasicLands else { return [] }
			return basicLands.filter { $0.isFullArt }
		default:
			let basicLands = mainCards.separateAll { ($0.typeLine ?? "").contains("Basic") == true && ($0.typeLine ?? "").contains("Land") == true }
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
		case "znr":
			return basicLandSlotCards.filter { $0.isFullArt }
		case "khm":
			return cards.filter { $0.typeLine.contains("Basic") && !$0.typeLine.contains("Snow") }
		case "tsr":
			return Swiftfall
				.getCards(query: "set:tsp t:basic", unique: true)
				.compactMap { $0?.data }
				.joined()
				.compactMap(MTGCard.init)
		case "stx", "mh2":
			let basicLands = mainCards.separateAll { ($0.typeLine ?? "").contains("Basic") == true && ($0.typeLine ?? "").contains("Land") == true }
			guard includeBasicLands else { return [] }
			return basicLands
		case "mid", "vow":
			// Use regular, non-Eternal Night basic lands that aren't found in boosters for MID.
			return cards.filter { $0.typeLine?.lowercased().contains("basic") == true && $0.promoTypes.contains("bundle") }
		case "neo":
			// Use regular, non-ukiyo-e basic lands that aren't found in boosters for MID.
			return cards.filter { $0.typeLine?.lowercased().contains("basic") == true && !$0.isFullArt }
		case _ where Set(defaultBasicLands.compactMap { $0.name }).count == 5:
			return defaultBasicLands
		default:
			// Just get the most recent hi-res basic lands if there are none others.
			return Swiftfall
			.getCards(query: "type='basic land –' is:highres", unique: false)
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
	case "iko" where !specialOptions.contains("godzilla"):
		mainCards.removeAll { card in
			card.promoTypes.contains("godzillaseries")
		}
	case "vow":
		mainCards.removeAll { card in
			card.promoTypes.contains("draculaseries")
		}
	default:
		break
	}
	
	mainCards.removeAll { card in
		card.promoTypes.contains("buyabox")
	}
	
	func cardIsShowcase(_ card: MTGCard) -> Bool {
		if setCode?.lowercased() == "mh2" && card.frame == "1997" {
			return true
		}
		
		if (card.frameEffects?.contains("showcase") == true || card.borderColor == .borderless) {
			return card.promoTypes?.contains("boosterfun") == true || mainCards.contains(where: { $0.name == card.name && $0.isFoundInBoosters })
		} else {
			return false
		}
	}
	
	if setCode?.lowercased() != "2xm" {
		mainCards = mainCards.map { card in
			var card = card
			if cardIsShowcase(card) {
				card.isFoundInBoosters = true
			}
			return card
		}
	}
	
	if setCode == "iko" {
		mainCards.removeAll(where: { $0.name == "Zilortha, Strength Incarnate" })
	} else if setCode?.lowercased() == "khm" {
		mainCards = mainCards.map { card in
			var card = card
			if card.typeLine?.lowercased().contains("basic") == true {
				card.isFoundInBoosters = card.typeLine?.lowercased().contains("snow") == true
			}
			return card
		}
	} else if setCode?.lowercased() == "stx" {
		mainCards = mainCards.map { card in
			var card = card
			if card.typeLine?.contains("Basic") == true {
				card.isFoundInBoosters = false
			}
			return card
		}
	} else if setCode?.lowercased() == "vow" {
		mainCards = mainCards.map { card in
			var card = card
			if let num = Int(card.collectorNumber), (278...328).contains(num) {
				card.isFoundInBoosters = true
			}
			return card
		}
	}
	
	let borderless: [MTGCard] = mainCards.separateAll { $0.borderColor == .borderless }
	let showcases: [MTGCard.Rarity: [MTGCard]] = .init(grouping: mainCards.separateAll(where: cardIsShowcase), by: \.rarity)
	
	let extendedArt = mainCards.separateAll { $0.frameEffects?.contains("extendedart") == true }
	
	let tokensAndEmblems = mainCards.separateAll {
		$0.typeLine?.lowercased().contains("token") == true || $0.typeLine?.lowercased().contains("emblem") == true
	}
	
	mainCards = mainCards.filter { $0.isFoundInBoosters && $0.language == .english && !$0.isPromo }
	
	guard mainCards.contains(where: { $0.isFoundInBoosters }) else {
		throw PackError.notInBoosters
	}
	
	let meldResults: [MTGCard] = mainCards.separateAll { card in
		guard card.layout == "meld", let parts = card.allParts else { return false }
		return parts.contains(where: { $0.component == .meldResult && $0.scryfallID == card.scryfallID }) == true
	}
	
	let customSlotRarities: [MTGCard.Rarity: [MTGCard]] = {
		switch setCode?.lowercased() {
		case "isd", "dka", "soi", "emn":
			return .init(grouping: mainCards.separateAll(where: { $0.layout == "transform" || $0.layout == "meld" }), by: \.rarity)
		case "war":
			return .init(grouping: mainCards.separateAll(where: { $0.typeLine?.lowercased().contains("planeswalker") == true }), by: \.rarity)
		case "vma":
			return .init(grouping: mainCards.separateAll { (1...9).contains(Int($0.collectorNumber) ?? 0) }, by: \.rarity)
		case "stx":
			return .init(grouping: mainCards.separateAll(where: { $0.typeLine?.lowercased().contains("lesson") == true /* && $0.rarity != .uncommon */ }), by: \.rarity)
		case "neo":
			return .init(grouping: mainCards.separateAll(where: { ($0.rarity == .uncommon || $0.rarity == .common) && $0.layout == "transform" }), by: \.rarity)
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
						  borderlessCards: borderless,
						  extendedArtCards: extendedArt,
						  masterpieces: masterpieces,
						  basicLands: basicLands)
}

struct CardLine: CustomStringConvertible {
	var count: Int
	var name: String
	var set: String
	var isFoil: Bool
	var isPinned: Bool
	var collectorNumber: String
	
	var description: String {
//		var desc = "\(count) \(name) (\(set)) \(collectorNumber)"
		var desc = "\(count) [\(set)#\(collectorNumber)] \(name)"
		
		var commentFlags: [String] = []
		
		if isPinned {
			commentFlags.append("!Pinned")
		}
		if isFoil {
			commentFlags.append("!Foil")
		}
		
		if !commentFlags.isEmpty {
			desc += " #"
			desc += commentFlags.joined(separator: " ")
		}
		
		return desc
	}
}

struct DownloadOutput: Codable {
	var downloadOutput: String
	var filename: String?
}

func cardListOutput(cards: CardCollection) throws -> String {
	struct Key: Hashable {
		var oracleID: UUID
		var isFoil: Bool
	}
	
	var cardCounts: [Key: CardLine] = [:]
	
	func addCard(_ card: CardCollection.CardSelection, isPinned: Bool = false) {
		guard let id = card.card.oracleID else { return }
		let key = Key(oracleID: id, isFoil: card.isFoil)
		if var count = cardCounts[key] {
			count.count += 1
			cardCounts[key] = count
		} else {
			cardCounts[key] = CardLine(count: 1, name: card.card.name ?? "", set: card.card.set.uppercased(), isFoil: card.isFoil, isPinned: isPinned, collectorNumber: card.card.collectorNumber)
		}
	}
	
	for card in cards.cards {
		guard !card.card.layout.contains("token") && !card.card.layout.contains("emblem") else { continue }
		addCard(card)
	}
	
	let lines = cardCounts.values.sorted { $0.name < $1.name }.map(String.init).joined(separator: "\n")
	
	let data = try JSONEncoder().encode(DownloadOutput(downloadOutput: lines))
	return String(data: data, encoding: .utf8) ?? ""
}

func simpleJsonOutput(cards: CardCollection) throws -> String {
	struct SimpleJsonCard: Codable {
		struct Back: Codable {
			var name: String
			var imageURL: URL?
		}
		var name: String
		var set: String
		var collectorNumber: String
		var imageURL: URL?
		var back: Back?
		var foil: Bool
		var scryfallURI: URL?
	}
	
	let simpleJson: [SimpleJsonCard] = cards.cards.map { card in
		let back: SimpleJsonCard.Back? = {
			guard let faces = card.card.cardFaces, faces.count == 2, card.card.layout == "transform" || card.card.layout == "modal_dfc" || card.card.layout == "double_faced_token" || card.card.layout == "double_sided" else { return nil }
			let back = faces[1]
			
			return SimpleJsonCard.Back(name: back.name ?? "", imageURL: back.imageUris?["normal"] ?? back.imageUris?["large"])
		}()
		
		return SimpleJsonCard(name: card.card.name ?? "", set: card.card.set, collectorNumber: card.card.collectorNumber, imageURL: card.card.cardFaces?.first?.imageUris?["normal"] ?? card.card.cardFaces?.first?.imageUris?["large"] ?? card.card.imageUris?["normal"] ?? card.card.imageUris?["large"], back: back, foil: card.isFoil, scryfallURI: card.card.scryfallURL)
	}
	
	let data = try JSONEncoder().encode(simpleJson)
	return String(data: data, encoding: .utf8) ?? ""
}

fileprivate func boosterBox(setName: String, cards: [MTGCard], tokens: [MTGCard], setCode: String?, mode: Mode, export: Bool, boxCount: Int?, includeExtendedArt: Bool, foilPolicy: FoilPolicy, mythicPolicy: MythicPolicy, specialOptions: [String], includeBasicLands: Bool, includeTokens: Bool, outputFormat: OutputFormat) throws -> String {
	let count: Int = {
		if let boxCount = boxCount, boxCount > 0 {
			return boxCount
		}
		
		switch setCode {
		case "cns", "cn2", "med", "me2", "me3", "me4", "vma", "tpr", "mma", "mm2", "mm3", "ema", "ima", "a25", "uma", "2xm", "cmr", "jmp", "dbl", "sjm":
			return 24
		default:
			return 36
		}
	}()
	
	func output(setName: String, setCode: String, packs: [CardCollection], tokens: [MTGCard]) throws -> String {
		switch outputFormat {
		case .tts:
			return try boosterBag(setName: setName, setCode: setCode, boosterPacks: packs.map(\.mtgCards), tokens: tokens, export: export)
		case .cardlist:
			return try cardListOutput(cards: CardCollection(cards: Array(packs.map(\.cards).joined())))
		case .json:
			return try simpleJsonOutput(cards: CardCollection(cards: Array(packs.map(\.cards).joined())))
		}
	}
	
	if setCode?.lowercased() == "cmr" {
		let cards = processCommanderLegendsCards(cards, tokens: tokens)
		
		let packs: [CardCollection] = (1...count).map { _ in generateCommanderLegendsPack(cards) }
		
		return try output(setName: "Commander Legends", setCode: setCode ?? "", packs: packs, tokens: cards.tokens)
	} else if setCode?.lowercased() == "mb1" || setCode?.lowercased() == "fmb1" || setCode?.lowercased() == "cmb1" {
		let cards = processMysteryBoosterCards(cards)
		let packs: [CardCollection] = (1...count).map { _ in generateMysteryBooster(cards: cards) }
		
		return try output(setName: "Mystery Booster", setCode: setCode ?? "", packs: packs, tokens: [])
	} else if setCode?.lowercased() == "plc" {
		let cards = processPlanarChaosCards(cards: cards)
		let packs: [CardCollection] = (1...count).map { _ in generatePlanarChaosPack(normalRarities: cards.normalRarities, colorshiftedRarities: cards.colorshiftedRarities) }
		
		return try output(setName: setName, setCode: setCode ?? "", packs: packs, tokens: [])
	} else if setCode?.lowercased() == "jmp" {
		let packs: [CardCollection] = (1...count).compactMap { _ in try? generateJumpStartPack() }
		
		return try output(setName: setName, setCode: setCode ?? "", packs: packs, tokens: [])
	} else if setCode?.lowercased() == "sjm" {
		let packs: [CardCollection] = (1...count).compactMap { _ in try? generateSuperJumpPack() }
		
		return try output(setName: setName, setCode: setCode ?? "", packs: packs, tokens: [])
	}
	
	let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: includeBasicLands)
	
	let packs: [CardCollection] = (1...count).map { _ in generatePack(rarities: processed.rarities,
																 customSlotRarities: processed.customSlotRarities,
																 basicLands: processed.basicLandsSlotCards,
																 tokens: includeTokens ? tokens + processed.tokens : [],
																 showcaseRarities: processed.showcaseRarities,
																 borderless: processed.borderlessCards,
																 extendedArt: processed.extendedArtCards,
																 meldResults: processed.meldResults,
																 mode: mode,
																 includeExtendedArt: includeExtendedArt,
																 masterpieceCards: processed.masterpieces,
																 foilPolicy: foilPolicy,
																 mythicPolicy: mythicPolicy) }
	
	return try output(setName: setName, setCode: setCode ?? "", packs: packs, tokens: tokens + processed.tokens)
}

fileprivate func commanderBoxingLeagueBox(setName: String, cards: [MTGCard], tokens: [MTGCard], setCode: String?, mode: Mode, export: Bool, boxCount: Int?, includeExtendedArt: Bool, foilPolicy: FoilPolicy, mythicPolicy: MythicPolicy, specialOptions: [String], includeBasicLands: Bool, includeTokens: Bool) throws -> String {
	let count: Int = {
		if let boxCount = boxCount, boxCount > 0 {
			return boxCount
		}
		
		switch setCode {
		case "cns", "cn2", "med", "me2", "me3", "me4", "vma", "tpr", "mma", "mm2", "mm3", "ema", "ima", "a25", "uma", "2xm":
			return 24
		default:
			return 36
		}
	}()
	
	if setCode?.lowercased() == "cmr" {
		let cards = processCommanderLegendsCards(cards, tokens: tokens)
		
		let packs: [CardCollection] = (1...count).map { _ in generateCommanderLegendsPack(cards) }
		
		return try boosterBag(setName: "Commander Legends", setCode: setCode ?? "", boosterPacks: packs.map(\.mtgCards), tokens: cards.tokens, export: export)
	} else if setCode?.lowercased() == "mb1" || setCode?.lowercased() == "fmb1" || setCode?.lowercased() == "cmb1" {
		let cards = processMysteryBoosterCards(cards)
		let packs: [CardCollection] = (1...count).map { _ in generateMysteryBooster(cards: cards) }
		
		return try boosterBag(setName: "Mystery Booster", setCode: setCode ?? "", boosterPacks: packs.map(\.mtgCards), tokens: [], export: export)
	} else if setCode?.lowercased() == "plc" {
		let cards = processPlanarChaosCards(cards: cards)
		let packs: [CardCollection] = (1...count).map { _ in generatePlanarChaosPack(normalRarities: cards.normalRarities, colorshiftedRarities: cards.colorshiftedRarities) }
		
		return try boosterBag(setName: setName, setCode: setCode ?? "", boosterPacks: packs.map(\.mtgCards), tokens: [], export: export)
	}
	
	let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: includeBasicLands)
	
	var cards: [MTGCard] = Array((1...count).map { _ in generatePack(rarities: processed.rarities,
													customSlotRarities: processed.customSlotRarities,
													basicLands: processed.basicLandsSlotCards,
													tokens: includeTokens ? tokens + processed.tokens : [],
													showcaseRarities: processed.showcaseRarities,
													borderless: processed.borderlessCards,
													extendedArt: processed.extendedArtCards,
													meldResults: processed.meldResults,
													mode: mode,
													includeExtendedArt: includeExtendedArt,
													masterpieceCards: processed.masterpieces,
													foilPolicy: foilPolicy,
													mythicPolicy: mythicPolicy).mtgCards }.joined()).sorted(by: { $0.name ?? "" < $1.name ?? "" })
	
	let code = setCode ?? cards.first?.set ?? ""
	
	let tokens = try allTokensForSet(setCode: code)
	let token = try singleCompleteToken(tokens: tokens, export: false)
	
	cards.removeAll(where: { $0.typeLine?.lowercased().contains("basic") == true || $0.layout == "token" || $0.layout == "double_faced_token" })
	
	let commanders = cards.separateAll(where: { $0.typeLine?.lowercased().contains("legendary") == true && $0.typeLine?.lowercased().contains("creature") == true })
	
	let rares = cards.separateAll(where: { $0.rarity == .rare || $0.rarity == .mythic })
	
	func colors(for card: MTGCard) -> Set<MTGColor> {
		var colors: Set<MTGColor> = []
		
		if let c = card.colors {
			for color in c {
				colors.insert(color)
			}
		}
		if let faces = card.cardFaces {
			for face in faces {
				if let c = face.colors {
					for color in c {
						colors.insert(color)
					}
				}
			}
		}
		
		return colors
	}
	
	// Commons and uncommons
	let white = cards.separateAll(where: { colors(for: $0) == [.white] })
	let blue = cards.separateAll(where: { colors(for: $0) == [.blue] })
	let black = cards.separateAll(where: { colors(for: $0) == [.black] })
	let red = cards.separateAll(where: { colors(for: $0) == [.red] })
	let green = cards.separateAll(where: { colors(for: $0) == [.green] })
	let multicolor = cards.separateAll(where: { colors(for: $0).count > 1 })
	let colorless = cards
	
	let namesAndPacks = Array([
		("Commanders", commanders),
		("Rares", rares),
		("White Commons & Uncommons", white),
		("Blue Commons & Uncommons", blue),
		("Black Commons & Uncommons", black),
		("Red Commons & Uncommons", red),
		("Green Commons & Uncommons", green),
		("Multicolor Commons & Uncommons", multicolor),
		("Colorless Commons & Uncommons", colorless)
	].reversed())
	
	let packs: [ObjectStateJSON] = try namesAndPacks.compactMap { name, cards in
		guard !cards.isEmpty else { return nil }
		
		if cards.count == 1, let card = cards.first {
			return try singleCard(card, tokens: [], facedown: false, export: false)
		} else {
			return try boosterPackJSON(setName: setName, setCode: code, name: name, cards: cards, tokens: tokens, inPack: false, cardBack: nil)
		}
	}
	
	let objectState = bag(objectStates: [token] + packs, nickname: setName)
	
	if !export {
		return objectState
	}
	
	return wrapObjectStateInSaveFile(objectState)
}

fileprivate func boosterPack(setName: String, cards: [MTGCard], tokens: [MTGCard], setCode: String?, mode: Mode, export: Bool, includeExtendedArt: Bool, foilPolicy: FoilPolicy, mythicPolicy: MythicPolicy, specialOptions: [String], includeBasicLands: Bool, includeTokens: Bool, outputFormat: OutputFormat, seed: Seed? = nil) throws -> String {
	
	func output(setName: String, setCode: String, pack: CardCollection, tokens: [MTGCard]) throws -> String {
		switch outputFormat {
		case .tts:
			return try singleBoosterPack(setName: setName, setCode: setCode, boosterPack: pack.mtgCards, tokens: tokens, export: export)
		case .cardlist:
			return try cardListOutput(cards: pack)
		case .json:
			return try simpleJsonOutput(cards: pack)
		}
	}
	
	if setCode?.lowercased() == "cmr" {
		let cards = processCommanderLegendsCards(cards, tokens: tokens)
		
		let pack = generateCommanderLegendsPack(cards)
		
		return try output(setName: setName, setCode: setCode ?? "", pack: pack, tokens: cards.tokens)
	} else if setCode?.lowercased() == "mb1" || setCode?.lowercased() == "fmb1" || setCode?.lowercased() == "cmb1" {
		let cards = processMysteryBoosterCards(cards)
		let pack = generateMysteryBooster(cards: cards)
		
		return try output(setName: setName, setCode: setCode ?? "", pack: pack, tokens: [])
	} else if setCode?.lowercased() == "plc" {
		let cards = processPlanarChaosCards(cards: cards)
		let pack = generatePlanarChaosPack(normalRarities: cards.normalRarities, colorshiftedRarities: cards.colorshiftedRarities)
		
		return try output(setName: setName, setCode: setCode ?? "", pack: pack, tokens: [])
	} else if setCode?.lowercased() == "jmp" {
		let pack = try generateJumpStartPack()
		
		return try output(setName: setName, setCode: setCode ?? "", pack: pack, tokens: [])
	} else if setCode?.lowercased() == "sjm" {
		let pack = try generateSuperJumpPack()
		let frontCard = pack[0]
		let tokens = getAllTokens(for: pack.mtgCards) + [frontCard]
		
		return try output(setName: setName, setCode: setCode ?? "", pack: pack, tokens: tokens)
	} else if setCode?.lowercased() == "dbl" {
		let processed = processDoubleFeatureCards(cards)
		let pack = generateDoubleFeaturePack(processed)
		
		return try output(setName: setName, setCode: setCode ?? "", pack: pack, tokens: [])
	}
	
	let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: includeBasicLands)
	
	let pack = generatePack(rarities: processed.rarities,
							customSlotRarities: processed.customSlotRarities,
							basicLands: processed.basicLandsSlotCards,
							tokens: includeTokens ? tokens + processed.tokens : [],
							showcaseRarities: processed.showcaseRarities,
							borderless: processed.borderlessCards,
							extendedArt: processed.extendedArtCards,
							meldResults: processed.meldResults,
							mode: mode,
							includeExtendedArt: includeExtendedArt,
							masterpieceCards: processed.masterpieces,
							foilPolicy: foilPolicy,
							mythicPolicy: mythicPolicy,
							seed: seed)
	
	return try output(setName: setName, setCode: setCode ?? "", pack: pack, tokens: tokens + processed.tokens)
}

fileprivate func prereleaseKit(setName: String, setCode: String, cards: [MTGCard], tokens: [MTGCard], mode: Mode, export: Bool, packCount: Int? = nil, includePromoCard: Bool?, includeLands: Bool?, includeSheet: Bool?, includeSpindown: Bool?, boosterCount: Int?, includeExtendedArt: Bool, foilPolicy: FoilPolicy, mythicPolicy: MythicPolicy, specialOptions: [String], outputFormat: OutputFormat, seed: Seed? = nil) throws -> String {
	let boosterCount = boosterCount ?? 6
	let packCount = packCount ?? 1
	let prereleasePacks: [String] = try (0 ..< (packCount)).map { _ in
		if setCode.lowercased() == "mb1" || setCode.lowercased() == "fmb1" || setCode.lowercased() == "cmb1" || setCode.lowercased() == "jmp" || setCode.lowercased() == "sjm" {
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
			
			switch outputFormat {
			case .cardlist:
				var cards = CardCollection(cards: Array(packs.map(\.cards).joined()))
				if includePromoCard == true {
					cards.append(promoCard, isFoil: true)
				}
				return try cardListOutput(cards: cards)
			case .json:
				var cards = CardCollection(cards: Array(packs.map(\.cards).joined()))
				if includePromoCard == true {
					cards.append(promoCard, isFoil: true)
				}
				return try simpleJsonOutput(cards: cards)
			case .tts:
				return try prereleasePack(setName: setName, setCode: setCode, boosterPacks: packs.map(\.mtgCards), promoCard: promoCard, tokens: [], basicLands: basicLands, includePromoCard: includePromoCard, includeLands: includeLands, includeSheet: includeSheet, includeSpindown: includeSpindown, export: export, seed: seed)
			}
		}
		
		let processed = try process(cards: cards, setCode: setCode, specialOptions: specialOptions, includeBasicLands: true)
		
		let packs: [CardCollection] = (1...boosterCount).map { value in generatePack(
			rarities: processed.rarities,
			customSlotRarities: processed.customSlotRarities,
			basicLands: processed.basicLandsSlotCards,
			tokens: tokens + processed.tokens,
			showcaseRarities: processed.showcaseRarities,
			borderless: processed.borderlessCards,
			extendedArt: processed.extendedArtCards,
			meldResults: processed.meldResults,
			mode: mode,
			includeExtendedArt: includeExtendedArt,
			masterpieceCards: processed.masterpieces,
			foilPolicy: foilPolicy,
			mythicPolicy: mythicPolicy,
			seed: value == 1 ? seed : nil
		)}
		
		let promoCard: MTGCard = try {
			let promos = Swiftfall.getCards(query: "set:p\(setCode) is:prerelease").compactMap { $0?.data }.joined().map(MTGCard.init)
			let promosRarities: [MTGCard.Rarity: [MTGCard]] = .init(grouping: promos, by: \.rarity)
			let filtered: [MTGCard.Rarity: [MTGCard]] = promosRarities.mapValues({ cards in
				guard let seed = seed, seed.packtype == .grnRna else { return cards }
				return cards.filter { card in
					return (card.cardFaces?.first?.watermark ?? card.watermark)?.lowercased() == seed.name.lowercased() || seed.matchesExactly(card)
				}
			})
			
			let promoRarity: MTGCard.Rarity = (1...8).randomElement()! == 8 ? .mythic : .rare
			
			if let promo = filtered[promoRarity]?.randomElement() ?? filtered[.rare]?.randomElement() {
				return promo
			} else if let card = (processed.rarities[promoRarity] ?? processed.rarities[.rare])?.filter({ $0.promoTypes == nil || $0.promoTypes!.contains("boosterfun") == false }).filter({ card in
				guard let seed = seed, seed.packtype == .grnRna else { return true }
				return (card.cardFaces?.first?.watermark ?? card.watermark)?.lowercased() == seed.name.lowercased() || seed.matchesExactly(card)
			}).randomElement() {
				let currentPrereleaseSetCode = "stx"
				if setCode == currentPrereleaseSetCode {
					var card = card
					let imageURL = URL(string: "http://josh.birnholz.com/tts/cards/\(currentPrereleaseSetCode)/\(card.collectorNumber).jpg")!
					
					if (card.cardFaces?.first?.imageUris) != nil {
						// Set the image only on the front of double-faced cards.
						card.cardFaces?[0].imageUris?["normal"] = imageURL
						card.cardFaces?[0].imageUris?["large"] = imageURL
					} else {
						card.imageUris?["normal"] = imageURL
						card.imageUris?["large"] = imageURL
					}
					
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
		
		switch outputFormat {
		case .cardlist:
			var cards = CardCollection(cards: Array(packs.map(\.cards).joined()))
			if includePromoCard == true {
				cards.append(promoCard, isFoil: true)
			}
			return try cardListOutput(cards: cards)
		case .json:
			var cards = CardCollection(cards: Array(packs.map(\.cards).joined()))
			if includePromoCard == true {
				cards.append(promoCard, isFoil: true)
			}
			return try simpleJsonOutput(cards: cards)
		case .tts:
			return try prereleasePack(setName: setName, setCode: setCode, boosterPacks: packs.map(\.mtgCards), promoCard: promoCard, tokens: tokens + processed.tokens, basicLands: processed.basicLands, includePromoCard: includePromoCard, includeLands: includeLands, includeSheet: includeSheet, includeSpindown: includeSpindown, export: false, seed: seed)
		}
	}
	
	switch outputFormat {
	case .cardlist:
		return prereleasePacks.joined(separator: "\n")
	case .json:
		return "[" + prereleasePacks.joined(separator: ",\n") + "]"
	case .tts:
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
			  "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
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
}

enum Deck {
	case arena(String)
	case deckstats(String)
	case moxfield(MoxfieldDeck)
	case archidekt(ArchidektDeck)
}

public struct ArchidektDeck: Decodable {
	struct CardInfo: Decodable {
		struct Card: Decodable {
			struct Edition: Decodable {
				let editioncode: String
			}
			struct OracleCard: Decodable {
				let name: String
			}
			let edition: Edition
			let collectorNumber: String
			let oracleCard: OracleCard
		}
		let card: Card
		let quantity: Int
		let categories: [String]
		
		var cardCount: DeckParser.CardCount {
			return DeckParser.CardCount(identifier: .nameSet(name: card.oracleCard.name, set: card.edition.editioncode), count: quantity)
		}
	}
	let name: String
	let cards: [CardInfo]
}

public struct MoxfieldDeck: Decodable {
	struct CardInfo: Decodable {
		struct Card: Decodable {
			let scryfallID: UUID?
			let set: String
			let name: String
		}
		let quantity: Int
		let card: Card
		
		var cardCount: DeckParser.CardCount {
			if let id = card.scryfallID {
				return DeckParser.CardCount(identifier: .id(id), count: quantity)
			} else {
				return DeckParser.CardCount(identifier: .nameSet(name: card.name, set: card.set), count: quantity)
			}
		}
	}
	
	let id: String
	let name: String
	let mainboard: [String: CardInfo]
	let sideboard: [String: CardInfo]?
	let commanders: [String: CardInfo]?
	let maybeboard: [String: CardInfo]?
}

let fixedSetCodes: [String: String] = [
	"dar": "dom",
	"7e": "7ed",
	"8e": "8ed",
	"eo2": "e02",
	"mi": "mir",
	"ul": "ulg",
	"od": "ody",
	"wl": "wth",
	"uz": "usg"
]

fileprivate func getAllTokens(_ cards: [Swiftfall.Card], _ tokens: inout [MTGCard]) {
	let tokenIdentifiers: [MTGCardIdentifier] = {
		return Set(cards.compactMap { $0.allParts?.compactMap { $0.component == "token" ? $0.id : nil } }.joined()).map { MTGCardIdentifier.id($0) }
	}()
	
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
}

fileprivate func getAllTokens(for cards: [MTGCard]) -> [MTGCard] {
	var tokens: [MTGCard] = []
	
	let tokenIdentifiers: [MTGCardIdentifier] = {
		return Set(cards.compactMap { $0.allParts?.compactMap { $0.component == .token ? $0.scryfallID : nil } }.joined()).map { MTGCardIdentifier.id($0) }
	}()
	
	guard !tokenIdentifiers.isEmpty else {
		return tokens
	}
	
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
		
		return tokens
	} catch {
		print(error)
		return tokens
	}
}

func deck(_ deck: Deck, export: Bool, cardBack: URL? = nil, includeTokens: Bool = true, faceCards: [MTGCard] = [], autofix: Bool, outputName: String? = nil, customOverrides: [String]) throws -> String {
	enum CustomOverride {
		case identifiers(String)
		case url(name: String, imageURL: URL)
	}
	
	let customOverrides: [CustomOverride] = customOverrides.compactMap { customOverrides in
		guard !customOverrides.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
		
		if customOverrides.contains("http") {
			guard let index = customOverrides.firstIndex(of: ":") else { return nil }
			let name = String(customOverrides[..<index])
			let urlStartIndex = customOverrides.index(after: index)
			var urlString = String(customOverrides[urlStartIndex...])
			if urlString.hasPrefix(":") {
				urlString = String(urlString.dropFirst())
			}
			guard let url = URL(string: urlString) else { return nil }
			return .url(name: name, imageURL: url)
		}
		
		if !customOverrides.contains(";") {
			return .identifiers(customOverrides.replacingOccurrences(of: ",", with: ";"))
		} else {
			return .identifiers(customOverrides)
		}
	}
	
	let parsed: [DeckParser.CardGroup] = {
		var parsed: [DeckParser.CardGroup]
		switch deck {
		case .arena(let decklist):
			parsed = DeckParser.parse(deckList: decklist, autofix: autofix)
		case .deckstats(let decklist):
			parsed = DeckParser.parse(deckstatsDecklist: decklist)
		case .moxfield(let moxfieldDeck):
			parsed = DeckParser.parse(moxfieldDeck: moxfieldDeck)
		case .archidekt(let archidektDeck):
			parsed = DeckParser.parse(archidektDeck: archidektDeck)
		}
		parsed.removeAll(where: { $0.name == DeckParser.CardGroup.GroupName.maybeboard.rawValue })
		return parsed
	}()
	
	var groups: [DeckParser.CardGroup] = parsed.filter { !$0.cardCounts.isEmpty }.map {
		var cardGroup = $0
		
		cardGroup.cardCounts = cardGroup.cardCounts.map { cardCount in
			func fixDoubleFacedName(_ name: String) -> String {
				guard let index = name.range(of: "//")?.lowerBound else { return name }
				return String(name[..<index].trimmingCharacters(in: .whitespacesAndNewlines))
			}
			
			let identifier: MTGCardIdentifier = {
				let identifier = cardCount.identifier
				
				switch identifier {
				case .nameSet(name: let name, set: let set):
					let fixedName = fixDoubleFacedName(name)
					if let fixedCode = fixedSetCodes[set.lowercased()] {
						return .nameSet(name: fixedName, set: fixedCode)
					} else if set.uppercased() == "MYSTOR" || set.uppercased() == "MYS1" {
						return .name(fixedName)
					} else if autofix && !(3...6).contains(set.count) {
						return .name(fixedName)
					} else {
						return .nameSet(name: fixedName, set: set)
					}
				case .collectorNumberSet(collectorNumber: let collectorNumber, set: let set, let name):
					let fixedName = name.flatMap(fixDoubleFacedName(_:))
					if let fixedCode = fixedSetCodes[set.lowercased()] {
						return .collectorNumberSet(collectorNumber: collectorNumber, set: fixedCode, name: fixedName)
					} else if let name = fixedName, set.uppercased() == "MYSTOR" {
						return .nameSet(name: name, set: "fmb1")
					} else if let name = fixedName, set.uppercased() == "MYS1" {
						return .nameSet(name: name, set: "mb1")
					} else if let name = fixedName, autofix && !(3...6).contains(set.count) {
						return .name(name)
					} else {
						return .collectorNumberSet(collectorNumber: collectorNumber, set: set, name: fixedName)
					}
				case .name(let name):
					return .name(fixDoubleFacedName(name))
				default:
					return identifier
				}
			}()
			
			return DeckParser.CardCount(identifier: identifier, count: cardCount.count)
		}
		
		return cardGroup
	}

	var identifiers: [MTGCardIdentifier] = Array(Set(groups.map { $0.cardCounts }.joined().map { $0.identifier }))
	
	guard !identifiers.isEmpty else {
		throw PackError.emptyInput
	}
	
	let customIdentifiers = identifiers.separateAll(where: { $0.set?.lowercased() == "custom" })
	
//	let fetchedCardGroups: [[Swiftfall.Card]] = identifiers.chunked(by: 20).map { identifiers in
//		let query = identifiers.compactMap(\.query).map { "(\($0))" }.joined(separator: " or ") + " prefer:newest game:paper"
//		let fetchedCards: [Swiftfall.Card] = Array(Swiftfall.getCards(query: query, unique: true).compactMap { $0?.data }.joined())
//		return fetchedCards
//	}
//	let cards: [Swiftfall.Card] = Array(fetchedCardGroups.joined())
	let collections: [Swiftfall.CardCollectionList] = try identifiers.chunked(by: 75).compactMap {
		do {
			return try Swiftfall.getCollection(identifiers: $0)
		} catch {
			print(error)
			throw error
		}
	}
	var cards: [Swiftfall.Card] = Array(collections.map(\.data).joined())
	var notFound: [MTGCardIdentifier] = Array(collections.compactMap(\.notFound).joined())
	
	// First round of retries: Remove incorrect collector numbers
	
	retry: if !notFound.isEmpty && autofix {
		let newIdentifiers: [MTGCardIdentifier] = identifiers.map { identifier in
			if case .collectorNumberSet(collectorNumber: let collectorNumber, let set, name: let name?) = identifier {
				if notFound.contains(where: { $0.collectorNumber == collectorNumber && $0.set == set }) {
					return .nameSet(name: name, set: set)
				}
			}
			
			return identifier
		}
		
		// Change card groups to use the changed identifiers, so cards can be found by the new identifiers later.
		groups = groups.map { group in
			var group = group
			
			group.cardCounts = group.cardCounts.map { cardCount in
				guard let index = identifiers.firstIndex(of: cardCount.identifier) else { return cardCount }
				var cardCount = cardCount
				cardCount.identifier = newIdentifiers[index]
				return cardCount
			}
			
			return group
		}
		
		let retriable = newIdentifiers.filter { !identifiers.contains($0) }
		
		guard !retriable.isEmpty else { break retry }
		
		identifiers = newIdentifiers
		
		let collections: [Swiftfall.CardCollectionList] = try retriable.chunked(by: 75).compactMap {
			do {
				return try Swiftfall.getCollection(identifiers: $0)
			} catch {
				print(error)
				throw error
			}
		}
		notFound = Array(collections.compactMap(\.notFound).joined())
		
		// Move the new identifiers to the end of the identifiers array, so their new positions match up with the found cards.
		let newlyFoundIdentifiers = retriable.filter { !notFound.contains($0) }
		for identifier in newlyFoundIdentifiers {
			if let index = identifiers.firstIndex(of: identifier) {
				identifiers.remove(at: index)
				identifiers.append(identifier)
			}
		}
		
		cards += Array(collections.map(\.data).joined())
	}
	
	// Second round of retries: Remove incorrect set codes
	
	retry: if !notFound.isEmpty && autofix {
		let newIdentifiers: [MTGCardIdentifier] = identifiers.map { identifier in
			if let name = identifier.name, notFound.contains(where: { $0.name == name }) {
				return .name(name)
			}
			
			return identifier
		}
		
		// Change card groups to use the changed identifiers, so cards can be found by the new identifiers later.
		groups = groups.map { group in
			var group = group
			
			group.cardCounts = group.cardCounts.map { cardCount in
				guard let index = identifiers.firstIndex(of: cardCount.identifier) else { return cardCount }
				var cardCount = cardCount
				cardCount.identifier = newIdentifiers[index]
				return cardCount
			}
			
			return group
		}
		
		let retriable = newIdentifiers.filter { !identifiers.contains($0) }
		
		guard !retriable.isEmpty else { break retry }
		
		identifiers = newIdentifiers
		
		let collections: [Swiftfall.CardCollectionList] = try retriable.chunked(by: 75).compactMap {
			do {
				return try Swiftfall.getCollection(identifiers: $0)
			} catch {
				print(error)
				throw error
			}
		}
		
		notFound = Array(collections.compactMap(\.notFound).joined())
		
		// Move the new identifiers to the end of the identifiers array, so their new positions match up with the found cards.
		let newlyFoundIdentifiers = retriable.filter { !notFound.contains($0) }
		for identifier in newlyFoundIdentifiers {
			if let index = identifiers.firstIndex(of: identifier) {
				identifiers.remove(at: index)
				identifiers.append(identifier)
			}
		}
		
		cards += Array(collections.map(\.data).joined())
	}
	
	var mtgCards = cards.map(MTGCard.init)
	
	if autofix {
		// Set codes for arena-only sets whose images should be changed to use versions listed in a custom set file.
		let customSets: Set<String> = [
			"akr"
		]
		
		for customSetCode in customSets {
			if mtgCards.contains(where: { $0.set.lowercased() == customSetCode }) {
				if let jsonURL = customSetJSONURL(forSetCode: customSetCode), let data = try? Data(contentsOf: jsonURL), let set = try? JSONDecoder().decode(MTGSet.self, from: data) {
					mtgCards = mtgCards.map { originalCard in
						var fixedCard = originalCard
						
						if originalCard.set.lowercased() == set.code.lowercased(), let card = set.cards.first(where: { $0.oracleID == originalCard.oracleID }) {
							fixedCard.imageUris = card.imageUris
							
							if let faces = card.cardFaces {
								for (index, face) in faces.enumerated() where originalCard.cardFaces?.indices.contains(index) == true {
									fixedCard.cardFaces?[index].imageUris = face.imageUris
								}
							}
						}
						
						return fixedCard
					}
				}
			}
		}
	}
	
	// Custom card overrides
	for customOverrides in customOverrides {
		switch customOverrides {
		case .identifiers(let customOverrides):
			let customCardOverrides: [String] = customOverrides.components(separatedBy: ";")
			for override in customCardOverrides {
				let identifier: MTGCardIdentifier = {
					let trimmed = override.trimmingCharacters(in: .whitespacesAndNewlines)
					if let number = Int(trimmed) {
						return .collectorNumberSet(collectorNumber: String(number), set: "custom", name: nil)
					} else {
						return .name(trimmed)
					}
				}()
				
				guard let customCard = CustomCards.shared.card(with: identifier) else { continue }
				
				mtgCards = mtgCards.map {
					if $0.oracleID == customCard.oracleID {
						return customCard
					} else {
						return $0
					}
				}
			}
		case .url(let name, let imageURL):
			mtgCards = mtgCards.map {
				if $0.name == name {
					var card = $0
					var imageURIs = card.imageUris ?? [:]
					imageURIs["normal"] = imageURL
					imageURIs["large"] = imageURL
					card.imageUris = imageURIs
					return card
				} else {
					return $0
				}
			}
		}
		
	}
	
	for identifier in customIdentifiers {
		guard let card = CustomCards.shared.card(with: identifier) else {
			notFound.append(identifier)
			continue
		}
		identifiers.append(identifier)
		mtgCards.append(card)
	}
	
	guard notFound.isEmpty else {
		throw PackError.noCardFound(String(describing: notFound.map { String(describing: $0) }.joined(separator: ", ")))
	}
	
	guard !mtgCards.isEmpty else {
		throw PackError.noCards
	}
	
	guard mtgCards.count == identifiers.count else {
		let missingIdentifiers = identifiers.filter { cards[$0] == nil }
		
		throw PackError.couldNotLoadCards(String(describing: missingIdentifiers.map { String(describing: $0) }.joined(separator: ", ")))
	}
	
//	var notFound: [MTGCardIdentifier] = []
	var tokens: [MTGCard] = []
	
	let fileName: String? = {
		guard let commanderIdentifiers = groups.first(where: { $0.name == DeckParser.CardGroup.GroupName.command.rawValue })?.cardCounts.map(\.identifier) else {
			return nil
		}
		var commanderNames: [String] = commanderIdentifiers.compactMap { identifier in
			guard let index = identifiers.firstIndex(of: identifier) else { return nil }
			return mtgCards[index].name
		}
		
		guard !commanderNames.isEmpty else { return nil }
		
		if commanderNames.count > 1 {
			commanderNames = commanderNames.map {
				if let index = $0.firstIndex(of: ",") {
					return String($0.prefix(upTo: index))
				} else if let subrange = $0.range(of: " the") {
					return String($0.prefix(upTo: subrange.lowerBound))
				} else {
					return $0
				}
			}
		}
		
		return commanderNames
			.map { $0.replacingOccurrences(of: ",", with: "") }
			.joined(separator: " and ")
	}()
	
	addCommandersToStartOfMainDecK: if let commandersGroupIndex = groups.firstIndex(where: { $0.name == DeckParser.CardGroup.GroupName.command.rawValue }) {
		let commandersGroup = groups.remove(at: commandersGroupIndex)
		guard let mainGroupIndex = groups.firstIndex(where: { $0.name == DeckParser.CardGroup.GroupName.deck.rawValue }) else {
			groups.insert(commandersGroup, at: 0)
			break addCommandersToStartOfMainDecK
		}
		groups[mainGroupIndex].cardCounts.insert(contentsOf: commandersGroup.cardCounts, at: 0)
	}
	
	let packs: [[MTGCard]] = groups.map { group in
		return group.cardCounts.reduce(into: [MTGCard]()) { (deck, cardCount) in
			guard let index = identifiers.firstIndex(of: cardCount.identifier) else {
				return
			}
			let card = mtgCards[index]
			if card.layout == "token" || card.layout == "emblem" && includeTokens {
				tokens.append(contentsOf: Array(repeating: card, count: cardCount.count))
			} else {
				deck.append(contentsOf: Array(repeating: card, count: cardCount.count))
			}
		}
	}
	
	if includeTokens {
		getAllTokens(cards, &tokens)
	}
	
	if cards.contains(where: { $0.name == "Ophiomancer" }) {
		let customSnakeToken = MTGCard(power: "1", toughness: "1", oracleText: "Deathtouch", name: "Snake", convertedManaCost: 0, layout: "token", frame: "2015", frameEffects: nil, manaCost: nil, scryfallURL: nil, borderColor: .black, isFullArt: false, allParts: [MTGCard.RelatedCard(scryfallID: UUID(uuidString: "66d80dd1-b944-4cb2-8578-b4dbcabbbc1e"), component: .token, name: "Ophiomancer", typeLine: "Creature — Human Shaman", url: URL(string: "https://scryfall.com/card/c13/84/ophiomancer"))], collectorNumber: "1", set: "TC13", colors: [.black], keywords: ["Deathtouch"], artist: "Maria Trepalina", watermark: nil, rarity: .common, scryfallCardBackID: UUID(uuidString: "0AEEBAF5-8C7D-4636-9E82-8C27447861F7")!, isFoilAvailable: false, isNonFoilAvailable: false, isPromo: false, isFoundInBoosters: false, promoTypes: nil, language: .english, releaseDate: nil, imageUris: ["normal": URL(string: "https://i.imgur.com/Q2uGSvH.jpg")!])
		tokens.append(customSnakeToken)
	}
	
	if cards.contains(where: { $0.keywords.contains("Daybound") || $0.keywords.contains("Nightbound") || $0.oracleText?.lowercased().contains("it becomes day") == true || $0.oracleText?.lowercased().contains("it becomes night") == true }) && !tokens.contains(where: { $0.scryfallID?.uuidString == "9c0f7843-4cbb-4d0f-8887-ec823a9238da" }) {
		let dayNightToken = try Swiftfall.getCard(id: "9c0f7843-4cbb-4d0f-8887-ec823a9238da")
		tokens.append(MTGCard(dayNightToken))
	}
	
	if cards.contains(where: { $0.oracleText?.lowercased().contains("the monarch") == true }) {
		let monarchToken = try Swiftfall.getCard(id: "bf7f3fc9-35f1-4b8c-b02b-494c71f31107")
		tokens.append(MTGCard(monarchToken))
	}
	
	if cards.contains(where: { $0.oracleText?.lowercased().contains("foretell") == true }) {
		let foretellToken = try Swiftfall.getCard(id: "fb02637f-1385-4d3d-8dc0-de513db7633a")
		tokens.append(MTGCard(foretellToken))
	}
	
	if cards.contains(where: { $0.name == "Inkshield" }) {
		let inklingToken = try Swiftfall.getCard(id: "c9deae5c-80d4-4701-b425-91853b7ee03b")
		tokens.append(MTGCard(inklingToken))
	}
	
	var alreadyThere: Set<MTGCard> = []
	let uniqueTokens = tokens.compactMap { token -> MTGCard? in
		guard let id = token.scryfallID else { return token }
		guard !alreadyThere.contains(where: { $0.scryfallID == id }) else { return nil }
		alreadyThere.insert(token)
		return token
	}
	
	tokens = uniqueTokens.sorted {
		($0.name ?? "") < ($1.name ?? "")
	}
	
  	if packs.count == 1 {
		var pack = Array(packs.joined())
		
		if let token = tokens.first {
			pack.insert(token, at: 0)
		}
		
		pack.insert(contentsOf: faceCards, at: 0)
		
		let output = try singleBoosterPack(setName: "", setCode: "", boosterPack: pack, tokens: tokens, inPack: false, export: export, cardBack: cardBack/*, nickname: outputName*/)
		let data = try JSONEncoder().encode(DownloadOutput(downloadOutput: output, filename: outputName ?? fileName))
		return String(data: data, encoding: .utf8) ?? ""
	} else {
//		if let name = outputName, let index = groups.firstIndex(where: { $0.name == DeckParser.CardGroup.GroupName.deck.rawValue }) {
//			groups[index].name = name
//		}
		var names = groups.reversed().map(\.name)
		var packs = Array(packs.reversed())
		if let token = tokens.first {
			packs.insert([token], at: 0)
			names.insert("Token", at: 0)
		}
		
		if !faceCards.isEmpty {
			packs.insert(faceCards, at: 0)
			names.insert("", at: 0)
		}
		
		let output = try boosterBag(setName: outputName ?? "", setCode: "", boosterPacks: packs, names: names, tokens: tokens, inPack: false, export: export, cardBack: cardBack)
		let data = try JSONEncoder().encode(DownloadOutput(downloadOutput: output, filename: outputName ?? fileName))
		return String(data: data, encoding: .utf8) ?? ""
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
				return card.name?.lowercased() == name || card.cardFaces?.contains(where: { $0.name?.lowercased() == name }) == true
			case .nameSet(name: let name, set: let set):
				let name = name.lowercased()
				return (card.name?.lowercased() == name || card.cardFaces?.contains(where: { $0.name?.lowercased() == name }) == true) && card.set.lowercased() == set.lowercased()
			case .collectorNumberSet(collectorNumber: let collectorNumber, set: let set, _):
				return card.collectorNumber.lowercased() == collectorNumber.lowercased() && card.set.lowercased() == set.lowercased()
			}
		}
		
		if let result = foundCard {
			return result
		} else if case .nameSet(let name, let set) = identifier, set.lowercased() == "dar" {
			return self[.nameSet(name: name, set: "dom")]
		} else if case .collectorNumberSet(let collectorNumber, let set, let name) = identifier, let fixedSet = fixedSetCodes[set.lowercased()] {
			return self[.collectorNumberSet(collectorNumber: collectorNumber, set: fixedSet, name: name)]
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
		case .collectorNumberSet(collectorNumber: let collectorNumber, set: let set, _):
			return "number:\(collectorNumber) set:\(set)"
		default:
			return nil
		}
	}
}
