//
//  DraftmancerCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 9/12/24.
//
import Foundation

//struct DraftmancerCard: Codable {
//  var name: String
//  var rarity: String
//  var manaCost: String
//  var type: String
//  var subtypes: [String]?
//  var image: URL
//  var set: String
//  var collectorNumber: String?
//}

public struct DraftmancerCard: Codable {
  public struct Face: Codable, Hashable, Equatable {
    var name: String
    var imageUris: [String: URL]
    var type: String
    var subtypes: [String]?
    var oracleText: String?
    var power: String?
    var toughness: String?
    var loyalty: String?
  }
  
  public enum DraftEffect: String, Codable {
    case FaceUp              // Reveal the card to other players and mark the card as face up. Important note: Necessary for most 'UsableEffects" to function correctly!.
    case Reveal              // Reveal the card to other players
    case NotePassingPlayer   // Note the previous player's name on the card.
    case NoteDraftedCards    // Note the number of cards drafted this round, including this card.
    case ChooseColors        // Note colors chosen by your neighbors and you.
    case AetherSearcher      // Reveal and note the next drafted card.
    case CanalDredger        // The last card of each booster is passed to you.
    case ArchdemonOfPaliano  // Pick the next 3 cards randomly.
    
    // Optional on pick effects:
    case LoreSeeker          // "You may add a booster pack to the draft".
    
    // Usable effects (when the card is already in the player's pool):
    case RemoveDraftCard     // Remove the picked card(s) from the draft and associate them with the card.
    case CogworkLibrarian    // Replace this card in a pack for an additional pick.
    case AgentOfAcquisitions // Pick the whole booster, skip until next round.
    case LeovoldsOperative   // Pick an additional card, skip the next booster.
    case NoteCardName        // Note the picked card's name on the card.
    case NoteCreatureName    // Note the picked creature's name on the card.
    case NoteCreatureTypes   // Note the picked creature's types on the card.
  }
  
  var name: String
  var manaCost: String
  var type: String
  var imageUris: [String: URL]?
  var colors: [String]?
  var printedNames: [String: URL]?
  var image: URL?
  var set: String?
  var collectorNumber: String?
  var rarity: String?
  var subtypes: [String]?
  var rating: Int?
  var layout: String?
  var back: Face?
  var relatedCards: [Face]?
  var draftEffects: [DraftEffect]?
  
  var power: String?
  var toughness: String?
  var oracleText: String?
  var loyalty: String?
  
  init(mtgCard: MTGCard) {
    self.name = mtgCard.name ?? ""
    self.manaCost = mtgCard.manaCost ?? ""
    var types = (mtgCard.typeLine ?? "").components(separatedBy: " — ")
    self.type = types.removeFirst()
    self.subtypes = types.first?.components(separatedBy: " ")
    self.set = mtgCard.set
    self.collectorNumber = mtgCard.collectorNumber
    self.rarity = nil
    self.layout = mtgCard.layout
    self.back = nil
    self.relatedCards = mtgCard.allParts?.compactMap {
      guard
        $0.name != mtgCard.name,
        let id = $0.scryfallID,
        let card = try? Swiftfall.getCard(id: id.uuidString)
      else { return nil }
      
      let mtgCard = MTGCard(card)
      var types = (mtgCard.typeLine ?? "").components(separatedBy: " — ")
      let type = types.removeFirst()
      let subtypes = types.first?.components(separatedBy: " ")
      let imageUris: [String: URL] = {
        if let url = mtgCard.imageUris?["large"] {
          return ["en": url]
        } else {
          return [:]
        }
      }()
      
      return Face(
        name: mtgCard.name ?? "",
        imageUris: imageUris,
        type: type,
        subtypes: subtypes
      )
    }
    self.draftEffects = nil
    
    if let url = mtgCard.imageUris?["large"] {
      self.imageUris = ["en": url]
    } else {
      self.imageUris = [:]
    }
    
    self.colors = mtgCard.colors?.compactMap { $0.rawValue }
    self.printedNames = nil
    self.rating = nil
    
    self.power = mtgCard.power
    self.toughness = mtgCard.toughness
    self.loyalty = mtgCard.loyalty
    self.oracleText = mtgCard.oracleText
  }
  
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.name, forKey: .name)
    try container.encode(self.manaCost, forKey: .manaCost)
    try container.encode(self.type, forKey: .type)
    
    if let imageUris {
      try container.encode(imageUris, forKey: .imageUris)
    } else {
      try container.encodeIfPresent(self.image, forKey: .image)
    }
    
    try container.encodeIfPresent(self.colors, forKey: .colors)
    try container.encodeIfPresent(self.printedNames, forKey: .printedNames)
    try container.encodeIfPresent(self.set, forKey: .set)
    try container.encodeIfPresent(self.collectorNumber, forKey: .collectorNumber)
    try container.encodeIfPresent(self.rarity, forKey: .rarity)
    try container.encodeIfPresent(self.subtypes, forKey: .subtypes)
    try container.encodeIfPresent(self.rating, forKey: .rating)
    try container.encodeIfPresent(self.layout, forKey: .layout)
    try container.encodeIfPresent(self.back, forKey: .back)
    try container.encodeIfPresent(self.relatedCards, forKey: .relatedCards)
    try container.encodeIfPresent(self.draftEffects, forKey: .draftEffects)
    
    try container.encodeIfPresent(self.power, forKey: .power)
    try container.encodeIfPresent(self.toughness, forKey: .toughness)
    try container.encodeIfPresent(self.oracleText, forKey: .oracleText)
    try container.encodeIfPresent(self.layout, forKey: .loyalty)
  }
}

extension DraftmancerCard {
  var mtgCard: MTGCard? {
    var typeLine = type
    if let subtypes {
      typeLine += " – \(subtypes.joined(separator: " "))"
    }
    guard let rarity = self.rarity.flatMap(MTGCard.Rarity.init(rawValue:)) else { return nil }
    
    var imageURIs = self.imageUris ?? [:]
    
    if let image, imageURIs.isEmpty {
      imageURIs["normal"] = image
      imageURIs["large"] = image
    }
    
    let relatedCards: [MTGCard.RelatedCard]? = self.relatedCards?.compactMap { face in
      guard face.type.hasPrefix("Token") else { return nil }
      
      var typeLine = face.type
      if let subtypes = face.subtypes {
        typeLine += " – \(subtypes.joined(separator: " "))"
      }
      
      return .init(
        scryfallID: nil,
        component: MTGCard.RelatedCard.Component.token,
        name: face.name,
        typeLine: typeLine,
        url: nil,
        draftmancerFace: face
      )
    }
    
    return .init(
      scryfallID: nil,
      oracleID: nil,
      typeLine: typeLine,
      power: self.power,
      toughness: self.toughness,
      oracleText: self.oracleText,
      flavorText: nil,
      name: self.name,
      loyalty: self.loyalty,
      cardFaces: nil, // Back faces and split cards not supported yet
      convertedManaCost: nil,
      layout: "",
      frame: "",
      frameEffects: nil,
      manaCost: self.manaCost,
      scryfallURL: nil,
      borderColor: nil,
      isFullArt: false,
      allParts: relatedCards,
      collectorNumber: self.collectorNumber ?? "",
      set: self.set ?? "",
      colors: self.colors?.compactMap(MTGColor.init(rawValue:)),
      producedMana: nil,
      colorIdentity: nil,
      keywords: nil,
      printedName: nil,
      printedText: nil,
      printedTypeLine: nil,
      artist: nil,
      watermark: nil,
      rarity: rarity,
      scryfallCardBackID: nil,
      isFoilAvailable: true,
      isNonFoilAvailable: true,
      isPromo: false,
      isFoundInBoosters: true,
      finishes: [.nonfoil],
      promoTypes: nil,
      language: .english,
      releaseDate: nil,
      isTextless: false,
      imageUris: imageURIs
    )
  }
}
