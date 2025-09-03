//
//  MTGCard+Swiftfall.swift
//  Cockatrice to Scryfall
//
//  Created by Josh Birnholz on 3/27/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation

fileprivate let dateFormatter: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyy-MM-dd"
	return formatter
}()

public func newImageURIs(cardID: UUID, back: Bool = false) -> [String: URL] {
	var imageURIs: [String: URL] = [:]
	
	for version in ["small", "normal", "large", "png", "art_crop", "border_crop"] {
		var components = URLComponents()
		components.scheme = "https"
		components.host = "api.scryfall.com"
		components.path = "/cards/\(cardID.uuidString.lowercased())"
		
		var items: [URLQueryItem] = [
			URLQueryItem(name: "format", value: "image"),
			URLQueryItem(name: "version", value: version)
		]
		
		if back {
			items.append(URLQueryItem(name: "face", value: "back"))
		}
		
		components.queryItems = items
		
		imageURIs[version] = components.url
	}
	
	return imageURIs
}

fileprivate func layoutIsDFC(_ layout: String) -> Bool {
	let dfcLayouts: [String] = [
		"transform", "double_faced_token", "modal_dfc"
	]
	
	return dfcLayouts.contains(layout.lowercased())
}


extension MTGCard {
	init(_ scryfallCard: Swiftfall.Card) {
		let faces: [MTGCard.Face]? = scryfallCard.cardFaces?.enumerated().map { arg -> MTGCard.Face in
			let (index, face) = arg
			var imageURIs = face.imageUris
			// This code constructs API links to new images. Should work, but may hit an API rate limit?
//			if layoutIsDFC(scryfallCard.layout) {
//				if index == 0 {
//					imageURIs = newImageURIs(cardID: scryfallCard.id)
//				} else if index == 1 {
//					imageURIs = newImageURIs(cardID: scryfallCard.id, back: true)
//				}
//			}
			
			return MTGCard.Face(typeLine: face.typeLine,
						 power: face.power,
						 toughness: face.toughness,
						 oracleText: face.oracleText,
						 flavorText: face.flavorText,
             name: face.name,
             printedName: face.printedName, flavorName: face.flavorName,
             loyalty: face.loyalty,
						 manaCost: face.manaCost,
						 colors: face.colors?.compactMap(MTGColor.init(rawValue:)),
						 watermark: face.watermark,
						 imageUris: imageURIs)
		}
		
		let relatedCards: [MTGCard.RelatedCard]? = scryfallCard.allParts?.compactMap { part in
			MTGCard.RelatedCard(scryfallID: part.id,
								component: part.component.flatMap(MTGCard.RelatedCard.Component.init(rawValue:)),
								name: part.name,
								typeLine: part.typeLine,
								url: URL(string: part.uri)!)
		}
		
		let date = dateFormatter.date(from: scryfallCard.releasedAt)
		
		self.init(scryfallID: scryfallCard.id,
				  oracleID: scryfallCard.oracleId,
				  typeLine: scryfallCard.typeLine,
				  power: scryfallCard.power,
				  toughness: scryfallCard.toughness,
				  oracleText: scryfallCard.oracleText,
				  flavorText: scryfallCard.flavorText,
				  name: scryfallCard.name,
          flavorName: scryfallCard.flavorName,
				  loyalty: scryfallCard.loyalty,
				  cardFaces: faces,
				  convertedManaCost: scryfallCard.cmc,
				  layout: scryfallCard.layout,
				  frame: scryfallCard.frame,
				  frameEffects: scryfallCard.frameEffects,
				  manaCost: scryfallCard.manaCost,
				  scryfallURL: URL(string: scryfallCard.scryfallUri),
				  borderColor: BorderColor(rawValue: scryfallCard.borderColor),
				  isFullArt: scryfallCard.fullArt,
				  allParts: relatedCards,
				  collectorNumber: scryfallCard.collectorNumber,
				  set: scryfallCard.set,
				  colors: scryfallCard.colors?.compactMap(MTGColor.init(rawValue:)),
				  producedMana: scryfallCard.producedMana?.compactMap(MTGColor.init(rawValue:)),
				  colorIdentity: scryfallCard.colorIdentity?.compactMap(MTGColor.init(rawValue:)),
				  keywords: scryfallCard.keywords,
				  printedName: scryfallCard.printedName,
				  printedText: scryfallCard.printedText,
				  printedTypeLine: scryfallCard.printedTypeLine,
				  artist: scryfallCard.artist,
				  watermark: scryfallCard.watermark,
				  rarity: MTGCard.Rarity(rawValue: scryfallCard.rarity) ?? .common,
				  scryfallCardBackID: scryfallCard.cardBackId,
				  isFoilAvailable: scryfallCard.foil,
				  isNonFoilAvailable: scryfallCard.nonfoil,
				  isPromo: scryfallCard.promo,
				  isFoundInBoosters: scryfallCard.booster,
				  finishes: scryfallCard.finishes,
				  promoTypes: scryfallCard.promoTypes,
				  language: Language(rawValue: scryfallCard.lang.rawValue)!,
          releaseDate: date,
          isTextless: scryfallCard.textless,
				  imageUris: scryfallCard.imageUris,
          games: scryfallCard.games)
//				  imageUris: scryfallCard.imageUris != nil ? newImageURIs(cardID: scryfallCard.id) : nil)
	}
}
