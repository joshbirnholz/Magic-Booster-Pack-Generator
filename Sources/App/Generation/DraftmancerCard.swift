//
//  DraftmancerCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 9/12/24.
//
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Vapor)
import Vapor
#endif
import XMLCoder

public struct DraftmancerCard: Codable, Sendable {
  enum Rarity: String, Codable, Comparable {
    case common, uncommon, rare, mythic, special
    
    private var intValue: Int {
      switch self {
      case .common:
        return 0
      case .uncommon:
        return 1
      case .rare:
        return 2
      case .mythic:
        return 3
      case .special:
        return 4
      }
    }
    
    static func <(lhs: Rarity, rhs: Rarity) -> Bool {
      return lhs.intValue < rhs.intValue
    }
  }
  
  init(name: String, flavorName: String? = nil, manaCost: String, type: String, imageUris: [String : URL]? = nil, colors: [String]? = nil, artist: String? = nil, printedNames: [String : URL]? = nil, image: URL? = nil, set: String? = nil, collectorNumber: String? = nil, rarity: Rarity? = nil, subtypes: [String]? = nil, rating: Int? = nil, layout: String? = nil, back: DraftmancerCard.Face? = nil, relatedCards: [DraftmancerCard.Face]? = nil, relatedCardIdentifiers: [MTGCardIdentifier]? = nil, draftEffects: [DraftmancerCard.DraftEffect]? = nil, power: String? = nil, toughness: String? = nil, oracleText: String? = nil, flavorText: String? = nil, loyalty: String? = nil, keywords: [String]? = nil) {
    self.name = name
    self.flavorName = flavorName
    self.manaCost = manaCost
    self.type = type
    self.imageUris = imageUris
    self.artist = artist
    self.colors = colors
    self.printedNames = printedNames
    self.image = image
    self.set = set
    self.collectorNumber = collectorNumber
    self.rarity = rarity
    self.subtypes = subtypes
    self.rating = rating
    self.layout = layout
    self.back = back
    self.relatedCards = relatedCards
    self.relatedCardIdentifiers = relatedCardIdentifiers
    self.draftEffects = draftEffects
    self.power = power
    self.toughness = toughness
    self.oracleText = oracleText
    self.flavorText = flavorText
    self.loyalty = loyalty
    self.keywords = keywords
  }
  
  public struct Face: Codable, Hashable, Equatable, Sendable {
    var name: String
    var flavorName: String?
    var imageUris: [String: URL]?
    var image: URL?
    var type: String
    var subtypes: [String]?
    var oracleText: String?
    var flavorText: String?
    var power: String?
    var toughness: String?
    var loyalty: String?
    var keywords: [String]?
    
    init(name: String, flavorName: String? = nil, imageUris: [String : URL]? = nil, image: URL? = nil, type: String, subtypes: [String]? = nil, oracleText: String? = nil, flavorText: String? = nil, power: String? = nil, toughness: String? = nil, loyalty: String? = nil, keywords: [String]? = nil) {
      self.name = name
      self.flavorName = name
      self.imageUris = imageUris
      self.image = image
      self.type = type
      self.subtypes = subtypes
      self.oracleText = oracleText
      self.flavorText = flavorText
      self.power = power
      self.toughness = toughness
      self.loyalty = loyalty
      self.keywords = keywords
    }
    
    public init(from decoder: Decoder) throws {
      let container: KeyedDecodingContainer<DraftmancerCard.Face.CodingKeys> = try decoder.container(keyedBy: DraftmancerCard.Face.CodingKeys.self)
      self.name = try container.decode(String.self, forKey: DraftmancerCard.Face.CodingKeys.name)
      self.flavorName = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.flavorName)
      
      if let image = try container.decodeIfPresent(URL.self, forKey: .image) {
        self.image = image
        self.imageUris = ["en":image]
      } else {
        self.imageUris = try container.decodeIfPresent([String: URL].self, forKey: .imageUris)
      }
      
      self.type = try container.decode(String.self, forKey: DraftmancerCard.Face.CodingKeys.type)
      self.subtypes = try container.decodeIfPresent([String].self, forKey: DraftmancerCard.Face.CodingKeys.subtypes)
      self.oracleText = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.oracleText)
      self.flavorText = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.flavorText)
      self.power = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.power)
      self.toughness = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.toughness)
      self.loyalty = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.loyalty)
      self.keywords = try container.decodeIfPresent([String].self, forKey: DraftmancerCard.Face.CodingKeys.keywords)
    }
  }
  
  public enum DraftEffect: String, Codable, Sendable {
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
  var flavorName: String?
  var manaCost: String
  var type: String
  var imageUris: [String: URL]?
  var colors: [String]?
  var artist: String?
  var printedNames: [String: URL]?
  var image: URL?
  var set: String?
  var collectorNumber: String?
  var rarity: Rarity?
  var subtypes: [String]?
  var rating: Int?
  var layout: String?
  var frame: String?
  var back: Face?
  var relatedCards: [Face]?
  var relatedCardIdentifiers: [MTGCardIdentifier]?
  var draftEffects: [DraftEffect]?
  
  var power: String?
  var toughness: String?
  var oracleText: String?
  var flavorText: String?
  var loyalty: String?
  var keywords: [String]?
  
  init(mtgCard: MTGCard) async {
    self.name = mtgCard.name ?? ""
    self.flavorName = mtgCard.flavorName
    self.manaCost = mtgCard.manaCost ?? ""
    var types = (mtgCard.typeLine ?? "").components(separatedBy: " — ")
    self.type = types.removeFirst()
    self.subtypes = types.first?.components(separatedBy: " ")
    self.set = mtgCard.set
    self.collectorNumber = mtgCard.collectorNumber
    self.rarity = .init(rawValue: mtgCard.rarity.rawValue.lowercased())
    self.layout = mtgCard.layout
    
    if (mtgCard.layout.lowercased().contains("transform") || mtgCard.layout.lowercased().contains("dfc") || mtgCard.layout.lowercased().contains("double_sided")), let faces = mtgCard.cardFaces, faces.count == 2, let back = faces.last {
      var types = (back.typeLine ?? "").components(separatedBy: " — ")
      let backType = types.removeFirst()
      let backSubtypes = types.first?.components(separatedBy: " ")
      
      let backImageUris: [String: URL] = {
        if let url = back.imageUris?["large"] {
          return ["en": url]
        } else {
          return [:]
        }
      }()
      
      self.back = .init(
        name: back.name ?? "",
        flavorName: back.flavorName,
        imageUris: backImageUris,
        image: nil,
        type: backType,
        subtypes: backSubtypes,
        oracleText: back.oracleText,
        flavorText: back.flavorText,
        power: back.power,
        toughness: back.toughness,
        loyalty: back.loyalty,
        keywords: nil
      )
      
      if let url = faces.first?.imageUris?["large"] {
        self.imageUris = ["en": url]
      } else {
        self.imageUris = [:]
      }
    } else {
      self.back = nil
      
      if let url = mtgCard.imageUris?["large"] {
        self.imageUris = ["en": url]
      } else {
        self.imageUris = [:]
      }
    }
    
    self.relatedCards = await mtgCard.allParts?.asyncCompactMap {
      guard
        $0.name != mtgCard.name,
        let id = $0.scryfallID,
        let card = try? await Swiftfall.getCard(id: id.uuidString)
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
    
    self.colors = mtgCard.colors?.compactMap { $0.rawValue }
    self.printedNames = nil
    self.rating = nil
    
    self.relatedCardIdentifiers = nil
    
    self.power = mtgCard.power
    self.toughness = mtgCard.toughness
    self.loyalty = mtgCard.loyalty
    self.oracleText = mtgCard.oracleText
    self.flavorText = mtgCard.flavorText
    self.keywords = mtgCard.keywords
    self.artist = mtgCard.artist
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.name, forKey: .name)
    try container.encodeIfPresent(self.flavorName, forKey: .flavorName)
    try container.encode(self.manaCost, forKey: .manaCost)
    try container.encode(self.type, forKey: .type)
    try container.encode(self.subtypes, forKey: .subtypes)
    
    if let imageUris = imageUris {
      try container.encode(imageUris, forKey: .imageUris)
    } else {
      try container.encodeIfPresent(self.image, forKey: .image)
    }
    
    try container.encodeIfPresent(self.artist, forKey: .artist)
    try container.encodeIfPresent(self.colors, forKey: .colors)
    try container.encodeIfPresent(self.printedNames, forKey: .printedNames)
    try container.encodeIfPresent(self.set, forKey: .set)
    try container.encodeIfPresent(self.collectorNumber, forKey: .collectorNumber)
    try container.encodeIfPresent(self.rarity, forKey: .rarity)
    
    try container.encodeIfPresent(self.rating, forKey: .rating)
    try container.encodeIfPresent(self.layout, forKey: .layout)
    try container.encodeIfPresent(self.back, forKey: .back)
    
    if let relatedCardIdentifiers = self.relatedCardIdentifiers, !relatedCardIdentifiers.isEmpty {
      try container.encode(relatedCardIdentifiers.map(String.init), forKey: .relatedCards)
    } else if let relatedCards = self.relatedCards, !relatedCards.isEmpty {
      try container.encode(relatedCards, forKey: .relatedCards)
    }
    
    try container.encodeIfPresent(self.draftEffects, forKey: .draftEffects)
    
    try container.encodeIfPresent(self.power, forKey: .power)
    try container.encodeIfPresent(self.toughness, forKey: .toughness)
    try container.encodeIfPresent(self.oracleText, forKey: .oracleText)
    try container.encodeIfPresent(self.flavorText, forKey: .flavorText)
    try container.encodeIfPresent(self.loyalty, forKey: .loyalty)
    try container.encodeIfPresent(self.keywords, forKey: .keywords)
    
    try container.encodeIfPresent(self.frame, forKey: .frame)
  }
  
  enum CodingKeys: CodingKey {
    case name
    case flavorName
    case manaCost
    case type
    case imageUris
    case artist
    case colors
    case printedNames
    case image
    case set
    case collectorNumber
    case rarity
    case subtypes
    case rating
    case layout
    case back
    case relatedCards
    case relatedCardIdentifiers
    case draftEffects
    case power
    case toughness
    case oracleText
    case flavorText
    case loyalty
    case keywords
    case frame
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
    self.flavorName = try container.decodeIfPresent(String.self, forKey: .flavorName)
    self.manaCost = try container.decode(String.self, forKey: .manaCost)
    self.type = try container.decode(String.self, forKey: .type)
    self.imageUris = try container.decodeIfPresent([String : URL].self, forKey: .imageUris)
    self.colors = try container.decodeIfPresent([String].self, forKey: .colors)
    self.printedNames = try container.decodeIfPresent([String : URL].self, forKey: .printedNames)
    self.image = try container.decodeIfPresent(URL.self, forKey: .image)
    self.set = try container.decodeIfPresent(String.self, forKey: .set)
    self.collectorNumber = try container.decodeIfPresent(String.self, forKey: .collectorNumber)
    self.rarity = try container.decodeIfPresent(Rarity.self, forKey: .rarity)
    self.subtypes = try container.decodeIfPresent([String].self, forKey: .subtypes)
    self.rating = try container.decodeIfPresent(Int.self, forKey: .rating)
    self.layout = try container.decodeIfPresent(String.self, forKey: .layout)
    self.back = try container.decodeIfPresent(DraftmancerCard.Face.self, forKey: .back)
    self.artist = try container.decodeIfPresent(String.self, forKey: .artist)
    self.frame = try container.decodeIfPresent(String.self, forKey: .frame)
    
    if let relatedCardIdentifiers = try? container.decodeIfPresent([String].self, forKey: .relatedCards) {
      self.relatedCardIdentifiers = relatedCardIdentifiers.compactMap { string in
        let groups = DeckParser.parse(deckList: "1 \(string)", autofix: false)
        return groups.first?.cardCounts.first?.identifier
      }
      
      self.relatedCards = nil
    } else {
      self.relatedCards = try container.decodeIfPresent([DraftmancerCard.Face].self, forKey: .relatedCards)
    }
    
    self.draftEffects = try container.decodeIfPresent([DraftmancerCard.DraftEffect].self, forKey: .draftEffects)
    self.power = try container.decodeIfPresent(String.self, forKey: .power)
    self.toughness = try container.decodeIfPresent(String.self, forKey: .toughness)
    self.oracleText = try container.decodeIfPresent(String.self, forKey: .oracleText)
    self.flavorText = try container.decodeIfPresent(String.self, forKey: .flavorText)
    self.loyalty = try container.decodeIfPresent(String.self, forKey: .loyalty)
    self.keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
  }
}

extension DraftmancerCard {
  var mtgCard: MTGCard {
    var typeLine = type
    if let subtypes = subtypes {
      typeLine += " — \(subtypes.joined(separator: " "))"
    }
    let rarity = self.rarity.flatMap({ MTGCard.Rarity.init(rawValue: $0.rawValue.lowercased()) }) ?? .bonus
    
    var imageURIs = self.imageUris ?? [:]
    
    if let image = image ?? imageURIs["en"] {
      imageURIs["small"] = image
      imageURIs["normal"] = image
      imageURIs["large"] = image
      
      if image.absoluteString.contains(".png") {
        imageURIs["png"] = image
      }
    }
    
    let relatedCards: [MTGCard.RelatedCard]? = {
      if let relatedCards = self.relatedCards {
        return relatedCards.compactMap { face -> MTGCard.RelatedCard? in
          var typeLine = face.type
          if let subtypes = face.subtypes {
            typeLine += " — \(subtypes.joined(separator: " "))"
          }
          
          return .init(
            scryfallID: nil,
            component: MTGCard.RelatedCard.Component.token,
            name: name,
            typeLine: typeLine,
            url: nil,
            draftmancerIdentifier: nil,
            draftmancerFace: face
          )
        }
      } else {
        return self.relatedCardIdentifiers?.compactMap { identifier -> MTGCard.RelatedCard? in
          return .init(
            scryfallID: nil,
            component: MTGCard.RelatedCard.Component.token,
            name: name,
            typeLine: nil,
            url: nil,
            draftmancerIdentifier: identifier
          )
          
        }
      }
    }()
    
    if let back, let layout, layout.lowercased().contains("transform") || layout.lowercased().contains("dfc") || layout.lowercased().contains("double_sided") {
      var backImageUris: [String: URL]?
      
      if let image = back.image ?? back.imageUris?["en"] {
        backImageUris = [
          "small": image,
          "normal": image,
          "large": image
        ]
        
        if image.absoluteString.contains(".png") {
          backImageUris?["png"] = image
        }
      }
      
      var backTypeLine = back.type
      if let subtypes = back.subtypes {
        backTypeLine += " — \(subtypes.joined(separator: " "))"
      }
      
      let backFace = MTGCard.Face(
        typeLine: backTypeLine,
        power: back.power,
        toughness: back.toughness,
        oracleText: oracleText,
        flavorText: nil,
        name: back.name,
        flavorName: back.flavorName,
        loyalty: back.loyalty,
        manaCost: nil,
        colors: nil,
        watermark: nil,
        imageUris: backImageUris
      )
      
      let frontFace = MTGCard.Face.init(
        typeLine: typeLine,
        power: self.power,
        toughness: self.toughness,
        oracleText: self.oracleText,
        flavorText: nil,
        name: self.name,
        flavorName: self.flavorName,
        loyalty: self.loyalty,
        manaCost: self.manaCost,
        colors: self.colors?.compactMap(MTGColor.init(rawValue:)),
        watermark: nil,
        imageUris: imageURIs
      )
      
      return .init(
        scryfallID: UUID(),
        oracleID: nil,
        typeLine: "\(typeLine) // \(backTypeLine)",
        power: nil,
        toughness: nil,
        oracleText: "\(self.oracleText ?? "")\n//\n\(back.oracleText ?? "")",
        flavorText: self.flavorText,
        name: "\(name) // \(back.name)",
        flavorName: nil,
        loyalty: nil,
        cardFaces: [frontFace, backFace],
        convertedManaCost: nil,
        layout: self.layout ?? (self.type.lowercased().contains("token") ? "token" : self.type.lowercased().contains("emblem") ? "emblem" : "normal"),
        frame: self.frame ?? "2015",
        frameEffects: nil,
        manaCost: self.manaCost,
        scryfallURL: nil,
        borderColor: nil,
        isFullArt: false,
        allParts: relatedCards,
        collectorNumber: self.collectorNumber ?? "",
        set: self.set ?? "",
        colors: nil,
        producedMana: nil,
        colorIdentity: nil,
        keywords: self.keywords,
        printedName: nil,
        printedText: nil,
        printedTypeLine: nil,
        artist: self.artist,
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
        imageUris: nil
      )
    } else {
      return .init(
        scryfallID: UUID(),
        oracleID: nil,
        typeLine: typeLine,
        power: self.power,
        toughness: self.toughness,
        oracleText: self.oracleText,
        flavorText: self.flavorText,
        name: self.name,
        flavorName: self.flavorName,
        loyalty: self.loyalty,
        cardFaces: nil, // Back faces and split cards not supported yet
        convertedManaCost: nil,
        layout: self.layout ?? (self.type.lowercased().contains("token") ? "token" : self.type.lowercased().contains("emblem") ? "emblem" : "normal"),
        frame: self.frame ?? "2015",
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
        keywords: self.keywords,
        printedName: nil,
        printedText: nil,
        printedTypeLine: nil,
        artist: self.artist,
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
}

struct DraftmancerSection {
  let name: String
  let contents: String
}

func allDraftmancerSections(in string: String) -> [DraftmancerSection] {
  let matches = string.matches(forRegex: #"^\[(.+)\]"#, options: .anchorsMatchLines)
  return matches.compactMap { $0.groups.first?.value }.compactMap {
    guard let contents = draftMancerStringSection($0, from: string) else { return nil }
    return .init(name: $0, contents: contents)
  }
}

func draftMancerStringSection(_ section: String, from string: String) -> String? {
  let matches = string.matches(forRegex: #"^\[(.+)\]"#, options: .anchorsMatchLines)
  guard let index = matches.firstIndex(where: { $0.groups.first?.value == section }) else {
    return nil
  }
  let section = matches[index]
  
  if let nextSection = matches.indices.contains(index+1) ? matches[index+1] : nil {
    return String(string[section.fullMatch.range.upperBound ..< nextSection.fullMatch.range.lowerBound])
  } else {
    return String(string[section.fullMatch.range.upperBound...])
  }
}

struct DraftmancerSet: Encodable, Sendable {
  var cards: [DraftmancerCard]
  var name: String
  var displayReversed: Bool = false
  
  enum CodingKeys: String, CodingKey {
    case cards
    case name
    case string
    case isDraftable
    case displayReversed
  }
  
  var isDraftable: Bool {
    if name == "Custom Cards" {
      return false
    }
    return [DraftmancerCard.Rarity.common, .uncommon, .rare].allSatisfy { rarity in cards.contains(where: { $0.rarity == rarity }) }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encode(cards, forKey: .cards)
    try container.encode(name, forKey: .name)
    try container.encode(isDraftable, forKey: .isDraftable)
    try container.encode(string, forKey: .string)
    try container.encode(displayReversed, forKey: .displayReversed)
    
  }
}

actor DraftmancerSetCache {
  static let shared = DraftmancerSetCache()
  
  private var cachedSets: [DraftmancerSet]? = nil
  private var cachedCards: [MTGCard]? = nil
  
  // New cached lookup tables
  private var exactNameIndex: [String: MTGCard] = [:]
  private var fuzzyIndex: [String: [MTGCard]] = [:] // prefix or substring
  private var normalizedNames: [MTGCard: [String]] = [:]
  private var cardBySetAndNumber: [String: [String: MTGCard]] = [:]
  
  var sets: [DraftmancerSet]? {
    get async {
      if let cachedSets { return cachedSets }
      do {
        let sets = try await load()
        self.cachedSets = sets
        buildCaches(from: sets)
        return sets
      } catch {
        return nil
      }
    }
  }
  
  var loadedDraftmancerSets: [DraftmancerSet]? {
    get async { await sets }
  }
  
  var loadedDraftmancerCards: [MTGCard]? {
    get async {
      if let cachedCards { return cachedCards }
      
      guard let sets = await sets else { return nil }
      let all = Array(sets.map { $0.cards.compactMap(\.mtgCard) }.joined())
      self.cachedCards = all
      return all
    }
  }
  
  func cardNamed(fuzzy name: String) async -> MTGCard? {
    let normalized = name.lowercased()
    
    // First try exact match
    if let exact = exactNameIndex[normalized] {
      return exact
    }
    
    // Then fuzzy match via prefix index
    if let matches = fuzzyIndex[normalized] {
      return matches.count == 1 ? matches.first : nil
    }
    
    return nil
  }
  
  func cardsMatchingNameQuery(_ query: String) async throws -> [MTGCard] {
    let normalized = query.lowercased()
    return fuzzyIndex[normalized] ?? []
  }
  
  func cardNamed(exact name: String) async -> MTGCard? {
    exactNameIndex[name.lowercased()]
  }
  
  func cardWithSetAndNumber(setCode: String, collectorNumber: String) async -> MTGCard? {
    let setKey = setCode.lowercased()
    let numKey = collectorNumber.lowercased()
    
    return cardBySetAndNumber[setKey]?[numKey]
  }
  
  private func buildCaches(from sets: [DraftmancerSet]) {
    let cards = Array(sets.map { $0.cards.compactMap(\.mtgCard) }.joined())
    cachedCards = cards
    
    for card in cards {
      let set = card.set.lowercased()
      let number = card.collectorNumber.lowercased()
      let names = collectNames(for: card)
      
      cardBySetAndNumber[set, default: [:]][number] = card
      
      // Cache normalized list
      normalizedNames[card] = names
      
      for name in names {
        // Store exact match (favor first)
        exactNameIndex[name, default: card] = card
        
        // Store fuzzy index by prefix
        for prefixLength in 1...name.count {
          let prefix = String(name.prefix(prefixLength))
          fuzzyIndex[prefix, default: []].append(card)
        }
      }
    }
  }
  
  private func collectNames(for card: MTGCard) -> [String] {
    var names: [String] = [card.name, card.flavorName].compactMap { $0?.lowercased() }
    names += card.cardFaces?.compactMap { $0.name?.lowercased() } ?? []
    names += card.cardFaces?.compactMap { $0.flavorName?.lowercased() } ?? []
    return names
  }
  
  private func load() async throws -> [DraftmancerSet] {
    print("Loading custom cards…")
    let startDate = Date()
    
    do {
      let urls = try urlsForResources(withExtension: "txt", subdirectory: "Draftmancer")
      
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      
      var draftmancerSets: [DraftmancerSet] = try await withThrowingTaskGroup(of: DraftmancerSet?.self) { group in
        for url in urls {
          group.addTask {
            do {
              return try await self.loadDraftmancerSetFromURL(url: url, decoder: decoder)
            } catch {
              print("‼️ Error loading cards from \(url.deletingPathExtension().lastPathComponent):", error)
              return nil
            }
          }
        }
        
        if let loadedCockatriceDatabases {
          for database in loadedCockatriceDatabases {
            group.addTask {
              return DraftmancerSet.init(cockatriceDatabase: database)
            }
          }
        }
        
//        if let loadedManifestoSets {
//          for set in loadedManifestoSets {
//            group.addTask {
//              return DraftmancerSet.init(manifestoSet: $0)
//            }
//          }
//        }
        
        group.addTask {
          let cubeURL = URL(string: "https://capitalich.github.io/lists/all-cards.json")!
          do {
            let data = try await URLSession.shared.data(from: cubeURL).0
            let adventureTimeCube = try decoder.decode(MSESet.self, from: data)
            var set = DraftmancerSet(mseSet: adventureTimeCube)
            set.name = "Adventure Time Cube"
            return set
            print("Loaded ATC from GitHub")
          } catch {
//            print("Error loading ATC from GitHub:", error)
//            let fromMSE: [DraftmancerSet] = loadedMSESets?.map {
//              DraftmancerSet(mseSet: $0)
//            } ?? []
//            
//            return fromMSE
            return nil
          }
        }
        
        var results: [DraftmancerSet] = []
        for try await result in group {
          if let set = result {
            results.append(set)
          }
        }
        
        return results
      }
      
      // Fill in missing sets and collector numbers
      var usedCollectorNumbersForSets: [String: Set<Int>] = [:]
      draftmancerSets = draftmancerSets.map {
        var set = $0
        
        set.cards = (set.name == "Custom Cards" ? set.cards.reversed() : set.cards).map { card in
          var card = card
          
          // Set cards with missing sets to "CUSTOM"
          if card.set == nil {
            card.set = "CUSTOM"
          }
          
          if !card.manaCost.contains("{") {
            card.manaCost = addBracketsToManaCost(card.manaCost)
          }
          
          // Record used collector numbers
          
          if usedCollectorNumbersForSets[card.set!] == nil {
            usedCollectorNumbersForSets[card.set!] = []
          }
          
          if let collectorNumber = card.collectorNumber.flatMap(Int.init) {
            usedCollectorNumbersForSets[card.set!]?.insert(collectorNumber)
          }
          
          return card
        }
        
        set.cards = set.cards.map { card in
          var card = card
          
          // Add missing collector numbers
          if card.collectorNumber == nil {
            let max = usedCollectorNumbersForSets[card.set!]?.max() ?? 0
            card.collectorNumber = "\(max+1)"
            usedCollectorNumbersForSets[card.set!]?.insert(max+1)
          }
          
          return card
        }
        
        let cardsGroupedBySet: [String: [DraftmancerCard]] = .init(grouping: set.cards) { card in
          card.set!
        }
        
        // Sort cards in collector number order, grouped by set code, regardless of how they were originally defined.
        // Shorter set codes come first, wchich would put tokens (eg "THLW") come after.
        set.cards = Array(cardsGroupedBySet.keys.sorted(on: \.count).map { setCode in
          return cardsGroupedBySet[setCode]!.sorted { $0.collectorNumber!.localizedStandardCompare($1.collectorNumber!) == .orderedAscending }
        }.joined())
        
        
        if set.name == "Custom Cards" {
          set.displayReversed = true
        }
        
        return set
      }
      
      let secondsSinceStart = Date().timeIntervalSince(startDate)
      print("Finished loading \(draftmancerSets.map(\.cards.count).reduce(0, +)) custom cards in \(secondsSinceStart)s")
      
      return draftmancerSets.sorted { $0.name < $1.name }
    } catch {
      print("Error loading Draftmancer sets:", error)
      throw error
    }
  }
  
  func loadDraftmancerSetFromURL(url: URL, decoder: JSONDecoder) async throws -> DraftmancerSet? {
    let rawData = try Data(contentsOf: url)
    guard let rawString = String(data: rawData, encoding: .utf8) else {
      print("‼️ Error loading string from data for \(url.deletingPathExtension().lastPathComponent):")
      return nil
    }
    let string = draftMancerStringSection("CustomCards", from: rawString)
    guard let data = string?.data(using: .utf8) else {
      print("‼️ Error getting data from string for \(url.deletingPathExtension().lastPathComponent):")
      return nil
    }
    
    struct QuickCard: Decodable {
      let name: String
      let flavorName: String?
      let flavorNameBack: String?
      let flavorText: String?
      let flavorTextBack: String?
      let front: URL
      let back: URL?
      let set: String?
      let rarity: DraftmancerCard.Rarity?
      let collectorNumber: String?
    }
    
    enum DraftmancerDecodable: Decodable {
      case full(DraftmancerCard)
      case quick(QuickCard)
      
      init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let quick = try? container.decode(QuickCard.self) {
          self = .quick(quick)
        } else {
          let full = try container.decode(DraftmancerCard.self)
          self = .full(full)
        }
      }
      
      func card(from collection: [Swiftfall.Card]) async -> DraftmancerCard? {
        switch self {
        case .full(let card):
          return card
        case .quick(let quick):
          do {
            let card: Swiftfall.Card = try await {
              if let card = collection[.name(quick.name)] {
                return card
              } else {
                return try await Swiftfall.getCard(exact: quick.name)
              }
            }()
            var mtgCard = MTGCard(card)
            
            if let back = quick.back, mtgCard.cardFaces?.count == 2 {
              let newFronts = mtgCard.cardFaces?[0].imageUris?.mapValues { _ in quick.front }
              mtgCard.cardFaces?[0].imageUris = newFronts
              mtgCard.cardFaces?[0].flavorText = quick.flavorText ?? nil
              mtgCard.cardFaces?[0].flavorName = quick.flavorName ?? nil
              
              let newBacks = mtgCard.cardFaces?[1].imageUris?.mapValues { _ in back }
              mtgCard.cardFaces?[1].imageUris = newBacks
              
              mtgCard.cardFaces?[1].flavorName = quick.flavorNameBack ?? nil
              mtgCard.cardFaces?[1].flavorText = quick.flavorTextBack ?? nil
            } else {
              mtgCard.imageUris = mtgCard.imageUris?.mapValues { _ in quick.front }
            }
            
            var draftmancerCard = await DraftmancerCard(mtgCard: mtgCard)
            draftmancerCard.collectorNumber = quick.collectorNumber
            draftmancerCard.flavorName = quick.flavorName ?? nil
            draftmancerCard.flavorText = quick.flavorText ?? nil
            draftmancerCard.back?.flavorName = quick.flavorNameBack ?? nil
            draftmancerCard.set = quick.set
            draftmancerCard.artist = nil
            
            if let rarity = quick.rarity {
              draftmancerCard.rarity = rarity
            }
            
            return draftmancerCard
          } catch {
            print("Error loading card for \(quick.name): \(error)")
            return nil
          }
        }
      }
    }
    
    let cards = try decoder.decode([DraftmancerDecodable].self, from: data)
    let name = url.deletingPathExtension().lastPathComponent
    
    print("✅ Loaded \(cards.count) Draftmancer cards from \(name)")
    
    let idsToFetch: [[MTGCardIdentifier]] = cards.compactMap {
      guard case .quick(let quick) = $0 else { return nil }
      return .name(quick.name)
    }.chunked(by: 75)
    var collection: [Swiftfall.Card] = []
    for chunk in idsToFetch where !chunk.isEmpty {
      do {
        let fetched = try await Swiftfall.getCollection(identifiers: chunk).data
        collection.append(contentsOf: fetched)
      } catch {
        print(error)
      }
    }
    
    return await DraftmancerSet(
      cards: cards.asyncCompactMap { await $0.card(from: collection) },
      name: name
    )
  }
}

private func addBracketsToManaCost(_ manaCost: String) -> String {
  var result = ""
  var buffer = ""
  var insideBrackets = false
  
  // Iterate over each character in the string
  var index = manaCost.startIndex
  while index < manaCost.endIndex {
      let char = manaCost[index]
      
      if char == "{" {
          insideBrackets = true
          buffer.append(char)
      } else if char == "}" {
          insideBrackets = false
          buffer.append(char)
          result.append(buffer)
          buffer = ""
      } else if insideBrackets {
          buffer.append(char)
      } else {
          // Check for custom symbol "Vp"
          let nextIndex = manaCost.index(after: index)
          if char == "V", nextIndex < manaCost.endIndex, manaCost[nextIndex] == "p" {
              result.append("{Vp}")
              // Skip the next character ('p') as it is part of the "Vp" symbol
              index = manaCost.index(after: nextIndex)
              continue
          }
          
          // If we encounter a slash, it's part of a hybrid symbol
          if char == "/" && !buffer.isEmpty {
              buffer.append(char)
              index = manaCost.index(after: index)
              continue
          }

          // Check if this is part of a hybrid symbol (e.g., W/U)
          if nextIndex < manaCost.endIndex && manaCost[nextIndex] == "/" {
              buffer.append(char)
          } else {
              if !buffer.isEmpty {
                  buffer.append(char)
                  result.append("{\(buffer)}")
                  buffer = ""
              } else {
                  result.append("{\(char)}")
              }
          }
      }
      
      index = manaCost.index(after: index)
  }

  // Append any remaining buffer (for complex costs like "W/U")
  if !buffer.isEmpty {
      result.append("{\(buffer)}")
  }

  return result
}

func getBuiltinDraftmancerCards(_ req: Request) async throws -> Vapor.Response {
  var headers = HTTPHeaders()
  headers.add(name: .contentType, value: "application/json")
  
  guard let responses = await DraftmancerSetCache.shared.sets else {
    return .init(
      status: .internalServerError, headers: headers
    )
  }
  
  let data = try Swiftfall.encoder.encode(responses)
  let string = String.init(data: data, encoding: .utf8) ?? ""
  
  return .init(
    status: .ok, headers: headers, body: .init(string: string)
  )
}

func getBuiltinDraftmancerCardsAsScryfall(_ req: Request) async throws -> Response {
  let query: String = try req.query.get(at: "q")
  let order = (try? req.query.get(Swiftfall.SearchOrder.self, at: "order")) ?? .name
  var direction = (try? req.query.get(Swiftfall.SearchOrderDirection.self, at: "direction")) ?? .auto
  let unique = try? req.query.get(Swiftfall.Unique.self, at: "unique")
  
  let headers: HTTPHeaders = [
    "Content-Type": "application/json",
    "access-control-allow-headers": "Origin",
    "access-control-allow-origin": "*"
  ]
  
  let tokenizer = ScryfallTokenizer()
  guard let token = tokenizer.scryfallToken(for: query, ignoreUnrecognized: true) else {
    throw Abort(.internalServerError, headers: headers, reason: "Unable to parse query.")
  }
  
  guard var allCards = await DraftmancerSetCache.shared.loadedDraftmancerCards else {
    return .init(
      status: .internalServerError, headers: headers
    )
  }
  
  allCards = allCards.filter { card in
    token.matches(card)
  }
  
  guard !allCards.isEmpty else {
    throw Abort(.notFound, headers: headers, reason: "Your query didn’t match any cards.")
  }
  
  if direction == .auto {
    direction = .autoDirection(for: order)
  }
  
  func isOrderedBefore<T: Comparable>(_ lhs: T?, rhs: T?) -> Bool {
    guard let lhs else { return false }
    guard let rhs else { return true }
    
    return direction == .ascending ? lhs < rhs : lhs > rhs
  }
  
  allCards = allCards.sorted(by: { first, second in
    switch order {
    case .name:
      return isOrderedBefore(first.name, rhs: second.name)
    case .set:
      return  isOrderedBefore(first.set, rhs: second.set)
    case .released:
      return isOrderedBefore(first.releaseDate, rhs: second.releaseDate)
    case .rarity:
      return isOrderedBefore(first.rarity, rhs: second.rarity)
    case .color:
      return false // Not yet implemented
    case .usd:
      return false
    case .tix:
      return false
    case .eur:
      return false
    case .cmc:
      return isOrderedBefore(first.convertedManaCost ?? 0, rhs: second.convertedManaCost ?? 0)
    case .power:
      let result = (first.power ?? "0").compare(second.power ?? "0", options: .numeric)
      return result == (direction == .ascending ? .orderedAscending : .orderedDescending)
    case .toughness:
      let result = (first.toughness ?? "0").compare(second.toughness ?? "0", options: .numeric)
      return result == (direction == .ascending ? .orderedAscending : .orderedDescending)
    case .artist:
      return isOrderedBefore(first.artist, rhs: second.artist)
    case .edhrec:
      return false // Not yet implemented
    case .review:
      return false // Not yet implemented
    case .spoiled:
      return false // Not yet implemented
    }
  })
  
  let scryfallCards = allCards.map { Swiftfall.Card.init($0) }
  let list = Swiftfall.CardList.init(data: scryfallCards, hasMore: false, nextPage: nil, totalCards: scryfallCards.count)
  
  let data = try Swiftfall.encoder.encode(list)
  let string = String.init(data: data, encoding: .utf8) ?? ""
  
  return .init(
    status: .ok, headers: headers, body: .init(string: string)
  )
}

func draftMancerAutocomplete(_ req: Request) async throws -> Response {
  let query: String = try req.query.get(at: "q")
  let headers: HTTPHeaders = [
    "Content-Type": "application/json",
    "access-control-allow-headers": "Origin",
    "access-control-allow-origin": "*"
  ]
  
  guard var allCards = await DraftmancerSetCache.shared.loadedDraftmancerCards else {
    return .init(
      status: .internalServerError, headers: headers
    )
  }
  
  allCards = query.count < 2 ? [] : Array(allCards.filter {
    $0.nameHasPrefix(query) || $0.name?.contains(query) == true
  }.sorted(by: { first, second in
    let firstHasPrefix = first.nameHasPrefix(query)
    let secondHasPrefix = second.nameHasPrefix(query)
    
    if firstHasPrefix != secondHasPrefix {
      return firstHasPrefix
    } else {
      return first.name ?? "" < second.name ?? ""
    }
  }))
  
  let names = OrderedSet(allCards.compactMap { $0.name }).prefix(20)
  
  let catalog = Swiftfall.Catalog(
    uri: nil,
    totalValues: allCards.count,
    totalItems: nil,
    data: Array(names)
  )
  
  let data = try Swiftfall.encoder.encode(catalog)
  
  return .init(headers: headers, body: .init(data: data))
}

func getAllBuiltinDraftmancerCardsAsScryfall(_ req: Request) async throws -> Response {
  let headers: HTTPHeaders = [
    "Content-Type": "application/json",
    "access-control-allow-headers": "Origin",
    "access-control-allow-origin": "*"
  ]
  
  guard let cards = await DraftmancerSetCache.shared.loadedDraftmancerCards else {
    return .init(
      status: .internalServerError, headers: headers
    )
  }
  
  let scryfallCards = cards.map { Swiftfall.Card.init($0) }
  let list = Swiftfall.CardList.init(data: scryfallCards, hasMore: false, nextPage: nil, totalCards: scryfallCards.count)
  
  let data = try Swiftfall.encoder.encode(list)
  let string = String.init(data: data, encoding: .utf8) ?? ""
  
  return .init(
    status: .ok, headers: headers, body: .init(string: string)
  )
}

func getAllBuiltinDraftmancerCardsAsCollection(_ req: Request) async throws -> Response {
  let headers: HTTPHeaders = [
    "Content-Type": "application/json",
    "access-control-allow-headers": "Origin",
    "access-control-allow-origin": "*"
  ]
  
  guard
    let bodyString = req.body.string,
    let dict = try? Swiftfall.decoder.decode([String: [MTGCardIdentifier]].self, from: bodyString.data(using: .utf8)!),
    let identifiers = dict["identifiers"]
  else {
    return .init(status: .badRequest, headers: headers)
  }
  
  guard identifiers.count <= 75 else {
    return .init(status: .badRequest, headers: headers)
  }
  
  guard let cards = await DraftmancerSetCache.shared.loadedDraftmancerCards else {
    return .init(
      status: .internalServerError, headers: headers
    )
  }
  
  var cardData: [MTGCard] = []
  var notFound: [MTGCardIdentifier] = []
  
  for identifier in identifiers {
    if let found = cards.first(where: { $0.isIdentified(by: identifier) }) {
      cardData.append(found)
    } else {
      notFound.append(identifier)
    }
  }
  
  let scryfallCards = cardData.map { Swiftfall.Card.init($0) }
  let list = Swiftfall.CardList.init(
    data: scryfallCards,
    hasMore: false,
    nextPage: nil,
    totalCards: nil,
    notFound: notFound
  )
  
  let data = try Swiftfall.encoder.encode(list)
  let string = String.init(data: data, encoding: .utf8) ?? ""
  
  return .init(
    status: .ok, headers: headers, body: .init(string: string)
  )
}

func getBuiltinDraftmancerSetsAsScryfall(_ req: Request) async throws -> Response {
  let headers: HTTPHeaders = [
    "Content-Type": "application/json",
    "access-control-allow-headers": "Origin",
    "access-control-allow-origin": "*"
  ]
  
  guard var sets = await DraftmancerSetCache.shared.loadedDraftmancerSets else {
    return .init(
      status: .internalServerError, headers: headers
    )
  }
  
  func makeScryfallSet(_ set: DraftmancerSet) -> Swiftfall.ScryfallSet {
    let code = set.cards.first?.set
    let uri = ""
    let scryfallUri = ""
    let searchUri: URL? = URL(string: "https://tts-magic-booster.fly.dev/custom/cards?set=\(code ?? "")")
    let releasedAt: Date? = nil
    return Swiftfall.ScryfallSet(code: code, mtgo: nil, name: set.name, uri: uri, scryfallUri: scryfallUri, searchUri: searchUri, releasedAt: Date(), setType: "expansion", cardCount: set.cards.count, digital: false, foilOnly: false, blockCode: nil, block: nil, printedSize: nil, iconSvgUri: nil)
  }
  
  if let setCode = req.parameters.get("set")?.lowercased() {
    if let set = sets.first(where: { $0.cards.contains(where: { $0.set?.lowercased() == setCode }) }) {
      let set = makeScryfallSet(set)
      
      let data = try Swiftfall.encoder.encode(set)
      return .init(headers: headers, body: .init(data: data))
    } else {
      throw Abort(.notFound, headers: headers)
    }
  }
  
  let scryfallSets = sets.map(makeScryfallSet(_:))
  
  let list = Swiftfall.SetList(data: scryfallSets, hasMore: false)
  
  let data = try Swiftfall.encoder.encode(list)
  
  return .init(headers: headers, body: .init(data: data))
}

// MARK: Cockatrice

struct CockatriceCardDatabase: Codable {
  let version: String
  
  struct Sets: Codable {
    let set: [Set]
  }
  
  struct Cards: Codable {
    var card: [Card]
  }
  
  struct Set: Codable {
    let name: String
    let longname: String
    let settype: String
  }
  
  struct Card: Codable {
    struct Set: Codable, DynamicNodeDecoding {
      let rarity: String?
      let imageURL: String?
      let value: String
      
      enum CodingKeys: String, CodingKey {
        case rarity
        case value = ""
        case imageURL = "picURL"
      }
      
      static func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding {
        guard let key = key as? CodingKeys else { return .elementOrAttribute }
        switch key {
        case .rarity, .imageURL: return .attribute
        case .value: return .element
        }
      }
    }
    
    var name: String
    var set: Set
    var rarity: String? { return set.rarity }
    var imageURL: String? { return set.imageURL }
    private let color: String
    var colors: [String] { return color.compactMap( { MTGColor(rawValue: String($0)) }).map(\.rawValue).filter { $0.count == 1 } }
    var manaCost: String?
    var cmc: Double?
    var type: String
    private let pt: String?
    var power: String? { return pt?.components(separatedBy: "/").first }
    var toughness: String? { return pt?.components(separatedBy: "/").last }
    var loyalty: String?
    var text: String
    private let token: Int?
    var isToken: Bool { token == 1 }
    var reverseRelated: [String]
    
    enum CodingKeys: String, CodingKey {
      case name
      case set
      case color
      case manaCost = "manacost"
      case cmc
      case type
      case pt
      case loyalty
      case text
      case token
      case reverseRelated = "reverse-related"
    }
  }
  
  var sets: Sets
  var cards: Cards
}

extension DraftmancerCard {
  init(cockatriceCard: CockatriceCardDatabase.Card) {
    let typeLine = cockatriceCard.type.components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    let type = typeLine.first ?? ""
    var subtypes: [String]?
    if typeLine.count > 1 {
      subtypes = typeLine.last?.components(separatedBy: " ")
    }
    
    self.init(
      name: cockatriceCard.name,
      manaCost: cockatriceCard.manaCost ?? "",
      type: type,
      imageUris: nil,
      colors: cockatriceCard.colors,
      printedNames: nil,
      image: cockatriceCard.imageURL.flatMap { URL(string: "http://josh.birnholz.com/tts/cards/\(cockatriceCard.set.value.uppercased())\($0)") } ?? URL(string: "http://josh.birnholz.com/tts/cards/\(cockatriceCard.set.value.uppercased())/\(cockatriceCard.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cockatriceCard.name).full.jpg"),
      set: cockatriceCard.set.value,
      collectorNumber: nil,
      rarity: cockatriceCard.rarity.flatMap(DraftmancerCard.Rarity.init(rawValue:)) ?? .common,
      subtypes: subtypes,
      rating: nil,
      layout: cockatriceCard.isToken ? "token" : "normal",
      back: nil,
      relatedCards: nil,
      relatedCardIdentifiers: nil,
      draftEffects: nil,
      power: cockatriceCard.power,
      toughness: cockatriceCard.toughness,
      oracleText: cockatriceCard.text,
      loyalty: cockatriceCard.loyalty,
      keywords: nil
    )
  }
}

extension DraftmancerSet {
  init(cockatriceDatabase: CockatriceCardDatabase) {
    var cards: [DraftmancerCard] = cockatriceDatabase.cards.card.map { cockatriceCard in
      var draftmancerCard = DraftmancerCard(cockatriceCard: cockatriceCard)
      
      let originalSet = draftmancerCard.set ?? ""
      
      if cockatriceCard.isToken {
        draftmancerCard.set = "T" + originalSet
      }
      
      // Remove set code name prefixes for basic lands and tokens
      if (cockatriceCard.isToken || cockatriceCard.type.lowercased().contains("basic")) && cockatriceCard.name.hasPrefix("\(originalSet) ") {
        draftmancerCard.name = String(draftmancerCard.name[draftmancerCard.name.index(draftmancerCard.name.startIndex, offsetBy: originalSet.count+1)...])
      }
      
      return draftmancerCard
    }
    
    for var cockatriceCard in cockatriceDatabase.cards.card {
      for relationship in cockatriceCard.reverseRelated {
        guard let index = cards.firstIndex(where: { $0.name == relationship }) else { continue }
        
        // Also remove set code name prefixes here to keep the reverse relationship intact
        if (cockatriceCard.isToken || cockatriceCard.type.lowercased().contains("basic")) && cockatriceCard.name.hasPrefix("\(cockatriceCard.set.value) ") {
          cockatriceCard.name = String(cockatriceCard.name[cockatriceCard.name.index(cockatriceCard.name.startIndex, offsetBy: cockatriceCard.set.value.count+1)...])
        }
        
        var card: DraftmancerCard {
          get {
            cards[index]
          }
          set {
            cards[index] = newValue
          }
        }
        
        var setCode = cockatriceCard.set.value
        if cockatriceCard.isToken {
          setCode = "T" + (setCode)
        }
        
        var relatedCardIdentifiers = card.relatedCardIdentifiers ?? []
        
        relatedCardIdentifiers.append(.nameSet(name: cockatriceCard.name, set: setCode))
        
        card.relatedCardIdentifiers = relatedCardIdentifiers
      }
    }
    
    enum Slot: Int, CaseIterable {
      case colorless, white, blue, black, red, green, multicolored, artifact, land, basic, other
      
      func containsCard(_ card: DraftmancerCard) -> Bool {
        let colors = card.colors ?? []
        let type = card.type.lowercased()
        
        switch self {
        case .colorless:
          return colors.isEmpty && !type.contains("artifact") && !type.contains("land")
        case .white:
          return colors == ["W"]
        case .blue:
          return colors == ["U"]
        case .black:
          return colors == ["B"]
        case .red:
          return colors == ["R"]
        case .green:
          return colors == ["G"]
        case .multicolored:
          return colors.count > 1
        case .artifact:
          return colors.isEmpty && type.contains("artifact")
        case .land:
          return colors.isEmpty && type.contains("land") && !type.contains("basic")
        case .basic:
          return type.contains("basic")
        case .other:
          return false
        }
      }
    }
    
    enum BasicLandOrder: String {
      case plains, island, swamp, mountain, forest
      
      var number: Int {
        switch self {
        case .plains:
          return 0
        case .island:
          return 1
        case .swamp:
          return 2
        case .mountain:
          return 3
        case .forest:
          return 4
        }
      }
    }
    
    var finalCards: [DraftmancerCard] = []
    
    let cardsGroupedBySet: [String: [DraftmancerCard]] = {
      var dictionary: [String: [DraftmancerCard]] = [:]
      
      for card in cards {
        var array: [DraftmancerCard] = dictionary[card.set!] ?? []
        array.append(card)
        dictionary[card.set!] = array
      }
      
      return dictionary
    }()
    
    for set in cardsGroupedBySet.keys.sorted(on: \.count) {
      let cards = cardsGroupedBySet[set]!
      
      let cardsGroupedBySlot: [Slot: [DraftmancerCard]] = .init(grouping: cards) { card in
        Slot.allCases.first(where: { $0.containsCard(card) }) ?? .other
      }
      
      for slot in Slot.allCases {
        let sortedCards: [DraftmancerCard] = {
          if slot == .basic {
            return (cardsGroupedBySlot[slot] ?? []).sorted { first, second in
              guard
                let firstType = first.subtypes?.last?.lowercased(),
                let secondType = second.subtypes?.last?.lowercased(),
                let firstOrder = BasicLandOrder(rawValue: firstType),
                let secondOrder = BasicLandOrder(rawValue: secondType) else {
                return first.name < second.name
              }
              return firstOrder.number < secondOrder.number
            }
          } else {
            return (cardsGroupedBySlot[slot] ?? []).sorted(on: \.name)
          }
        }()
        finalCards.append(contentsOf: sortedCards)
      }      
    }
    
//    cards = Array(cardsGroupedBySet.map({ (set: String, cards: [DraftmancerCard]) in
//      let cards = cards.sorted(on: \.name)
//      let cardsGroupedBySlot: [Slot: [DraftmancerCard]] = .init(grouping: cards) { card in
//        Slot.allCases.first(where: { $0.containsCard(card) }) ?? Slot.allCases.last!
//      }
//      return cardsGroupedBySet.sorted(on: \.key).map(\.value).joined()
//    }).joined())
    
    self.init(cards: finalCards, name: cockatriceDatabase.sets.set.map(\.longname).joined(separator: "/"))
  }
}

extension DraftmancerSet {
  var string: String? {
    enum Slot: String, CaseIterable, Hashable, Equatable {
      case common
      case uncommon
      case rare
      case mythic
      case special
      case land
      case tokens
      
      var name: String {
        rawValue.capitalized
      }
    }
    
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    guard let data = try? encoder.encode(cards), let string = String(data: data, encoding: .utf8) else {
      return nil
    }
    
    var draftmancerString = ""
    
    draftmancerString += "[CustomCards]\n"
    draftmancerString += string
    
    guard isDraftable else {
      // If the set isn't draftable, just include all the cards in one slot so they can be viewed on Draftmancer, at least.
      var cards = cards
      let tokens = cards.separateAll(where: { $0.layout == "token" || $0.type.lowercased().contains("token") })
      let basics = cards.separateAll(where: { $0.type.lowercased().contains("basic") })
      
      draftmancerString += "\n[DefaultSlot]\n"
      for card in cards {
        draftmancerString += [card.name, card.set.flatMap { "(\($0.uppercased()))" }, card.collectorNumber].compactMap{ $0 }.joined(separator: " ") + "\n"
      }
      
      if !basics.isEmpty {
        draftmancerString += "\n[Basic Lands]\n"
        for card in basics {
          draftmancerString += [card.name, card.set.flatMap { "(\($0.uppercased()))" }, card.collectorNumber].compactMap{ $0 }.joined(separator: " ") + "\n"
        }
      }
      
      if !tokens.isEmpty {
        draftmancerString += "\n[Tokens]\n"
        for card in tokens {
          draftmancerString += [card.name, card.set.flatMap { "(\($0.uppercased()))" }, card.collectorNumber].compactMap{ $0 }.joined(separator: " ") + "\n"
        }
      }
      
      if !basics.isEmpty || !tokens.isEmpty {
        let settings = """
        [Settings]
        {
          "layouts": {
            "Default": {
              "weight": 1,
              "slots": [
                { "name": "DefaultSlot", "count": 15 },
              ]
            }
          }
        }
        
        """
        draftmancerString = settings + draftmancerString
      }
      
      return draftmancerString
    }
    
    struct Settings: Encodable {
      struct Layout: Encodable, Equatable {
        var weight: Int
        var slots: [String: Int]
      }
      
      var withReplacement: Bool
      var layouts: [String: Layout]
    }
    
    let slots: [Slot?: [DraftmancerCard]] = .init(grouping: cards, by: {
      if $0.type.contains("Basic") {
        return .land
      } else if $0.layout == "token" || $0.layout == "emblem" {
        return .tokens
      } else if let rarity = $0.rarity {
        return Slot(rawValue: rarity.rawValue.lowercased())
      } else {
        return nil
      }
    })
    
    let url = urlForResource(name, withExtension: "txt", subdirectory: "Draftmancer")
    if let rawData = try? Data(contentsOf: url), let allSections = String(data: rawData, encoding: .utf8).flatMap(allDraftmancerSections(in:)), allSections.count > 1 {
      // Set has specified settings/slots already, use them directoy
      for section in allSections where section.name != "CustomCards" {
        draftmancerString += "\n[\(section.name)]\n" + section.contents.trimmingCharacters(in: .newlines)
      }
      
      return draftmancerString
    } else {
      // Create new default settings
      draftmancerString += "\n[Settings]\n"
      
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      
      let baseLayout: Settings.Layout = {
        var layout: Settings.Layout = .init(weight: 7, slots: [:])
        var count = 14
        
        //      if slots[.special] != nil {
        //        layout.slots[Slot.special.name] = 1
        //        count -= 1
        //      }
        if slots[.rare] != nil {
          layout.slots[Slot.rare.name] = 1
          count -= 1
        }
        if slots[.uncommon] != nil {
          layout.slots[Slot.uncommon.name] = 3
          count -= 3
        }
        if slots[.land] != nil {
          layout.slots[Slot.land.name] = 1
        }
        layout.slots[Slot.common.name] = count
        return layout
      }()
      
      var layouts = ["Rare": baseLayout]
      
      if slots[.mythic] != nil {
        var mythicLayout = baseLayout
        mythicLayout.slots[Slot.mythic.name] = 1
        mythicLayout.slots[Slot.rare.name] = nil
        mythicLayout.weight = 1
        
        layouts["Mythic"] = mythicLayout
      }
      
      let standardRareLayout = Settings.Layout(weight: 7, slots: [Slot.common.name: 10, Slot.uncommon.name: 3, Slot.rare.name: 1, Slot.land.name: 1])
      let standardMythicLayout = Settings.Layout(weight: 1, slots: [Slot.common.name: 10, Slot.uncommon.name: 3, Slot.mythic.name: 1, Slot.land.name: 1])
      
      let standardMythicString = layouts.contains(where: { $0 == "Mythic" && $1 == standardMythicLayout }) ? """
            "Mythic" : {
              "slots" : {
                "Land" : 1,
                "Mythic" : 1,
                "Uncommon" : 3,
                "Common" : 10
              },
              "weight" : 1
            },
            
      """ : ""
      
      if layouts == ["Rare": standardRareLayout, "Mythic": standardMythicLayout] || layouts == ["Rare": standardRareLayout] {
        // If the standard slots are being used, then encode it manually to keep order
        draftmancerString += """
        {
          "layouts" : {
            \(standardMythicString)"Rare" : {
              "slots" : {
                "Land" : 1,
                "Rare" : 1,
                "Uncommon" : 3,
                "Common" : 10
              },
              "weight" : 7
            }
          },
          "withReplacement" : true
        }
        
        """
      } else {
        let settings = Settings(
          withReplacement: true,
          layouts: layouts
        )
        
        draftmancerString += String(data: try! encoder.encode(settings), encoding: .utf8)! + "\n"
      }
      
      for slot in Slot.allCases {
        guard let cards = slots[slot] else { continue }
        
        draftmancerString += "[\(slot.name)]\n"
        for card in cards {
          draftmancerString += [card.name, card.set.flatMap { "(\($0.uppercased()))" }, card.collectorNumber].compactMap{ $0 }.joined(separator: " ") + "\n"
        }
      }
      
      return draftmancerString
    }
  }
}

let loadedCockatriceDatabases: [CockatriceCardDatabase]? = {
  guard let urls = try? urlsForResources(withExtension: "xml", subdirectory: "Cockatrice") else { return nil }
  
  let decoder = XMLDecoder()
  
  return urls.compactMap { url in
    do {
      guard let data = try? Data(contentsOf: url) else { return nil }
      let database = try decoder.decode(CockatriceCardDatabase.self, from: data)
      
      print("✅ Loaded Cockatrice database \(database.sets.set.map(\.name).joined(separator: ", ")) (\(database.cards.card.count)) cards")
      return database
    } catch {
      print("‼️ Error loading Cockatrice cards:", error)
      return nil
    }
  }
}()

// MARK: MSE

struct MSESet: Codable {
  let cards: [MSECard]
  var name: String?
}

struct MSECard: Codable {
  let cardName: String
  let color: String?
  let rarity: String
  let type: String
  let number: Int
  let colorIdentity: String
  let cost: String?
  let rulesText: String?
  let flavorText: String?
  let pt: String?
  let specialText: String?
  let shape: String
  let set: String
  let loyalty: String?
  let artist: String
  let notes: String?
  let imageType: String
  
  // Back face or Adventure side
  let cardName2: String?
  let color2: String?
  let type2: String?
  let cost2: String?
  let rulesText2: String?
  let flavorText2: String?
  let pt2: String?
  let specialText2: String?
  let loyalty2: String?
  let artist2: String?
}

func fixManaCost(_ cost: String) -> String {
  let pattern = #"(?<=\{)([A-Z]{2})(?=\})"#
  guard let regex = try? NSRegularExpression(pattern: pattern) else { return cost }

  let nsrange = NSRange(cost.startIndex..<cost.endIndex, in: cost)
  var fixed = cost

  // Work from end to start to avoid messing up ranges after replacements
  for match in regex.matches(in: cost, options: [], range: nsrange).reversed() {
    guard let range = Range(match.range(at: 1), in: cost) else { continue }
    let symbol = cost[range]

    // Skip if symbol is numeric (e.g. "10", "20", etc.)
    if Int(symbol) != nil { continue }

    // Insert slash between the characters (e.g. "CW" -> "C/W")
    let fixedSymbol = "\(symbol.prefix(1))/\(symbol.suffix(1))"
    fixed.replaceSubrange(range, with: fixedSymbol)
  }

  return fixed
}

extension DraftmancerCard {
  init?(mseCard card: MSECard) {
    guard let cost = card.cost else { return nil }
    
    let fixedCost = fixManaCost(cost)
    
    let isDFC = card.shape.contains("transform")
    
    let typeParts = card.type.components(separatedBy: " — ")
    let type = typeParts.first ?? card.type
    let subtypes = typeParts.count > 1 ? typeParts[1].components(separatedBy: " ") : nil
    
    let rarity: Rarity? = {
      switch card.rarity.lowercased() {
      case "common": return .common
      case "uncommon": return .uncommon
      case "rare": return .rare
      case "mythic": return .mythic
      case "special": return .special
      case "cube": return .special
      default: return nil
      }
    }()
    
    func imageURL(isBack: Bool = false) -> URL? {
      guard let name = card.cardName.trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let set = card.set.uppercased().addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
      else { return nil }
      
      var string = "https://capitalich.github.io/sets/\(set)-files/img/\(card.number)"
      
      if card.shape == "token" {
        string += "t"
      }
      
      string += "_\(name)"
      
      if isDFC {
        string += (isBack ? "_back" : "_front")
      }
      
      string += ".png"
      
      return URL(string: string)
    }
    
    guard let frontURL = imageURL() else { return nil }
    
    let (power, toughness): (String?, String?) = card.pt.flatMap {
      guard $0.contains("/") else { return (nil, nil) }
      let components = $0.components(separatedBy: "/")
      return (components[0], components[1])
    } ?? (nil, nil)
    
    let (power2, toughness2): (String?, String?) = card.pt2.flatMap {
      guard $0.contains("/") else { return (nil, nil) }
      let components = $0.components(separatedBy: "/")
      return (components[0], components[1])
    } ?? (nil, nil)
    
    self.init(
      name: card.cardName.trimmingCharacters(in: .whitespacesAndNewlines),
      flavorName: nil,
      manaCost: fixedCost,
      type: type,
      imageUris: ["en": frontURL],
      colors: card.color.flatMap { Array($0).map(String.init) },
      artist: card.artist,
      printedNames: nil,
      image: imageURL(),
      set: (card.shape == "token" || type.lowercased().contains("token")) ? "T\(card.set)" : card.set,
      collectorNumber: String(card.number),
      rarity: rarity,
      subtypes: subtypes,
      rating: nil,
      layout: card.shape,
      back: isDFC ? DraftmancerCard.Face(
        name: card.cardName2?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
        image: imageURL(isBack: true),
        type: card.type2 ?? "",
        oracleText: card.rulesText2?.replacingOccurrences(of: "[i]", with: "").replacingOccurrences(of: "[/i]", with: "").optionalIfEmpty(),
        flavorText: card.flavorText2?.replacingOccurrences(of: "[i]", with: "").replacingOccurrences(of: "[/i]", with: "").optionalIfEmpty(),
        power: power2,
        toughness: toughness2,
        loyalty: card.loyalty2,
        keywords: []
      ) : nil,
      relatedCards: nil,
      relatedCardIdentifiers: nil,
      draftEffects: nil,
      power: power,
      toughness: toughness,
      oracleText: card.rulesText?.replacingOccurrences(of: "[i]", with: "").replacingOccurrences(of: "[/i]", with: "").optionalIfEmpty(),
      flavorText: card.flavorText?.replacingOccurrences(of: "[i]", with: "").replacingOccurrences(of: "[/i]", with: "").optionalIfEmpty(),
      loyalty: card.loyalty,
      keywords: []
    )
  }
}

let loadedMSESets: [MSESet]? = {
  guard let urls = try? urlsForResources(withExtension: "json", subdirectory: "MSE Set Hub") else { return nil }
  
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  
  return urls.compactMap { url in
    do {
      guard let data = try? Data(contentsOf: url) else { return nil }
      var set = try decoder.decode(MSESet.self, from: data)
      set.name = url.deletingPathExtension().lastPathComponent
      
      print("✅ Loaded \(set.cards.count) MSE cards from \(url.lastPathComponent)")
      return set
    } catch {
      print("‼️ Error loading Cockatrice cards:", error)
      return nil
    }
  }
}()

extension DraftmancerSet {
  init(mseSet: MSESet) {
    let cards: [DraftmancerCard] = mseSet.cards.compactMap { card in
      guard let c = DraftmancerCard(mseCard: card) else {
        print("Couldn't load Draftmancer card for \(card.cardName)")
        return nil
      }
      return c
    }
    
    self.init(
      cards: cards,
      name: mseSet.name ?? ""
    )
  }
}

extension String {
  func optionalIfEmpty() -> String? {
    if self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return nil
    } else {
      return self
    }
  }
}
