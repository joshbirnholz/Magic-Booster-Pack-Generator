//
//  Card.swift
//  CardService
//
//  Created by Josh Birnholz on 3/9/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public struct MTGCard: Codable, Equatable, Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.scryfallID)
	}
	
	public enum BorderColor: String, Codable {
		case black
		case borderless
		case gold
		case silver
		case white
		
		#if canImport(UIKit)
		public var uiColor: UIColor {
			switch self {
			case .gold: return #colorLiteral(red: 0.6444242001, green: 0.5267884135, blue: 0.2910364866, alpha: 1)
			case .silver: return #colorLiteral(red: 0.6396835446, green: 0.6834098697, blue: 0.7172803283, alpha: 1)
			case .white: return .white
			case .black: return .black
			case .borderless: return .black
			}
		}
		#endif
	}
	
	public struct Face: Codable, Equatable, Hashable {
		public var typeLine: String?
		public var power: String?
		public var toughness: String?
		public var oracleText: String?
		public var flavorText: String?
		public var name: String?
		public var loyalty: String?
		public var manaCost: String?
		public var colors: [MTGColor]?
		public var watermark: String?
		
		var imageUris: [String: URL]?
	}
	
	public struct RelatedCard: Codable, Equatable, Hashable {
		public enum Component: String, Codable {
			case token
			case meldPart = "meld_part"
			case meldResult = "meld_result"
			case comboPiece = "combo_piece"
		}
		public var scryfallID: UUID?
		public var component: Component?
		public var name: String
		public var typeLine: String?
		public var url: URL?
	}
	
	public enum Language: String, Codable, Equatable, Hashable {
		case english = "en"
		case spanish = "es"
		case french = "fr"
		case german = "de"
		case italian = "it"
		case portuguese = "pt"
		case japanese = "ja"
		case korean = "ko"
		case russian = "ru"
		case simplifiedChinese = "zhs"
		case traditionalChinese = "zht"
		case hebrew = "he"
		case latin = "la"
		case ancientGreek = "grc"
		case arabic = "ar"
		case sanskrit = "sa"
		case phyrexian = "ph"
	}
	
	public enum Rarity: String, Codable, Equatable, Hashable, CaseIterable, Comparable {
		public static func < (lhs: MTGCard.Rarity, rhs: MTGCard.Rarity) -> Bool {
			return lhs.compareValue < rhs.compareValue
		}
		
		case common
		case uncommon
		case rare
		case mythic
		case special
		case bonus
		
		private var compareValue: Int {
			switch self {
			case .common: return 0
			case .uncommon: return 1
			case .rare: return 2
			case .mythic: return 3
			case .special: return 4
			case .bonus: return 5
			}
		}
	}
	
	public var scryfallID: UUID?
	public var oracleID: UUID?
	public var typeLine: String?
	public var power: String?
	public var toughness: String?
	public var oracleText: String?
	public var flavorText: String?
	public var name: String?
	public var loyalty: String?
	public var cardFaces: [Face]?
	public var convertedManaCost: Double?
	public var layout: String
	public var frame: String
	public var frameEffects: [String]?
	public var manaCost: String?
	public var scryfallURL: URL?
	public var borderColor: BorderColor?
	public var isFullArt: Bool
	public var allParts: [RelatedCard]?
	public var collectorNumber: String
	public var set: String
	public var colors: [MTGColor]?
	public var producedMana: [MTGColor]?
	public var colorIdentity: [MTGColor]?
	public var keywords: [String]?
	
	public var printedName: String?
	public var printedText: String?
	public var printedTypeLine: String?
	public var artist: String?
	public var watermark: String?
	
	public var rarity: Rarity
	public var scryfallCardBackID: UUID?
	
	public var isFoilAvailable: Bool
	public var isNonFoilAvailable: Bool
	public var isPromo: Bool
	public var isFoundInBoosters: Bool
	
	public var promoTypes: [String]?
	
	public var language: Language
	public var releaseDate: Date?
	
	var imageUris: [String: URL]?
	
	var faceURL: URL? {
		guard let scryfallID = scryfallID?.uuidString.lowercased() else {
			return nil
		}

		return URL(string: "https://api.scryfall.com/cards/\(scryfallID)?format=image&version=normal")
	}
	
	var backURL: URL? {
		guard let scryfallID = scryfallID?.uuidString.lowercased() else {
			return nil
		}

		return URL(string: "https://api.scryfall.com/cards/\(scryfallID)?format=image&version=normal&face=back")
	}
	
}

public extension MTGCard {
	var isBasicLand: Bool {
		(typeLine?.lowercased().contains("basic") == true) && (typeLine?.lowercased().contains("land") == true)
	}
	
	var isLand: Bool {
		typeLine?.lowercased().contains("land") == true
	}
	
	var isFoil: Bool {
		if !isNonFoilAvailable { return true }
		return false
//		return isFoilAvailable && collectorNumber.hasSuffix("★")
	}
	
	var isShowcase: Bool {
		frameEffects?.contains("showcase") == true
	}
}

extension MTGCard: CustomDebugStringConvertible {
	public var debugDescription: String {
		"[\(set.uppercased())#\(collectorNumber)] \(name ?? "")"
	}
}

//func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
//	debugPrint(items, separator, terminator)
//}
