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

extension MTGCard {
	init(_ scryfallCard: Swiftfall.Card) {
		let faces = scryfallCard.cardFaces?.map { face in
			MTGCard.Face(typeLine: face.typeLine,
						 power: face.power,
						 toughness: face.toughness,
						 oracleText: face.oracleText,
						 flavorText: face.flavorText,
						 name: face.name,
						 loyalty: face.loyalty,
						 manaCost: face.manaCost,
						 colors: face.colors?.compactMap(MTGColor.init(rawValue:)),
						 imageUris: face.imageUris)
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
				  language: Language(rawValue: scryfallCard.lang.rawValue)!,
				  releaseDate: date,
				  imageUris: scryfallCard.imageUris?.compactMapValues(URL.init(string:)))
	}
}
