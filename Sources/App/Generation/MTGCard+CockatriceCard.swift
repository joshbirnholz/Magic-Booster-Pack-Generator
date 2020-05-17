//
//  MTGCard+CockatriceCard.swift
//  Cockatrice to Scryfall
//
//  Created by Josh Birnholz on 3/27/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation

extension MTGCard {
	init(card: CockatriceCardDatabase.Card, collectorNumber: String) {
		let powerToughness = card.pt?.components(separatedBy: "/")
		let manaCost: String? = card.manacost?.map { "{\($0)}" }.joined()
		let relatedCards: [MTGCard.RelatedCard]? = nil
		let colors: [MTGColor]? = card.color.components(separatedBy: "").compactMap(MTGColor.init(rawValue:))
		let imageName = "\(card.name.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "(", with: "%28").replacingOccurrences(of: ")", with: "%29"))"
		let imageURL = URL(string: "http://www.planesculptors.net/upload/18/4671/\(imageName).png")!
		let artCropURL = URL(string: "http://josh.birnholz.com/cardart/\(card.set.shortName.lowercased())/\(imageName).jpg")!
		let imageUris: [String: URL]? = ["normal": imageURL, "large": imageURL, "small": imageURL, "png": imageURL, "art_crop": artCropURL]
		
		self.init(scryfallID: UUID(),
				  oracleID: nil,
				  typeLine: card.type,
				  power: powerToughness?.first,
				  toughness: powerToughness?.last,
				  oracleText: card.text?.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: ""),
				  flavorText: nil,
				  name: card.name,
				  loyalty: card.loyalty,
				  cardFaces: nil,
				  convertedManaCost: card.cmc.flatMap(Double.init),
				  layout: card.token ? "token" : "normal",
				  frame: "2015",
				  frameEffects: nil,
				  manaCost: manaCost,
				  scryfallURL: nil,
				  borderColor: .black,
				  isFullArt: false,
				  allParts: relatedCards,
				  collectorNumber: collectorNumber,
				  set: card.set.shortName,
				  colors: colors,
				  printedName: card.name,
				  printedText: card.text,
				  printedTypeLine: card.type,
				  artist: nil,
				  watermark: nil,
				  rarity: MTGCard.Rarity(rawValue: card.set.rarity ?? MTGCard.Rarity.common.rawValue) ?? .common,
				  scryfallCardBackID: UUID(uuidString: "0AEEBAF5-8C7D-4636-9E82-8C27447861F7")!,
				  isFoilAvailable: false,
				  isNonFoilAvailable: true,
				  isPromo: false,
				  isFoundInBoosters: true,
				  language: .english,
				  releaseDate: nil,
				  imageUris: imageUris)
	}
}
