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

public struct DraftmancerCard: Codable {
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
  
  init(name: String, manaCost: String, type: String, imageUris: [String : URL]? = nil, colors: [String]? = nil, artist: String? = nil, printedNames: [String : URL]? = nil, image: URL? = nil, set: String? = nil, collectorNumber: String? = nil, rarity: Rarity? = nil, subtypes: [String]? = nil, rating: Int? = nil, layout: String? = nil, back: DraftmancerCard.Face? = nil, relatedCards: [DraftmancerCard.Face]? = nil, relatedCardIdentifiers: [MTGCardIdentifier]? = nil, draftEffects: [DraftmancerCard.DraftEffect]? = nil, power: String? = nil, toughness: String? = nil, oracleText: String? = nil, loyalty: String? = nil, keywords: [String]? = nil) {
    self.name = name
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
    self.loyalty = loyalty
    self.keywords = keywords
  }
  
  public struct Face: Codable, Hashable, Equatable {
    var name: String
    var imageUris: [String: URL]?
    var image: URL?
    var type: String
    var subtypes: [String]?
    var oracleText: String?
    var power: String?
    var toughness: String?
    var loyalty: String?
    var keywords: [String]?
    
    init(name: String, imageUris: [String : URL]? = nil, image: URL? = nil, type: String, subtypes: [String]? = nil, oracleText: String? = nil, power: String? = nil, toughness: String? = nil, loyalty: String? = nil, keywords: [String]? = nil) {
      self.name = name
      self.imageUris = imageUris
      self.image = image
      self.type = type
      self.subtypes = subtypes
      self.oracleText = oracleText
      self.power = power
      self.toughness = toughness
      self.loyalty = loyalty
      self.keywords = keywords
    }
    
    public init(from decoder: Decoder) throws {
      let container: KeyedDecodingContainer<DraftmancerCard.Face.CodingKeys> = try decoder.container(keyedBy: DraftmancerCard.Face.CodingKeys.self)
      self.name = try container.decode(String.self, forKey: DraftmancerCard.Face.CodingKeys.name)
      
      if let image = try container.decodeIfPresent(URL.self, forKey: .image) {
        self.image = image
        self.imageUris = ["en":image]
      } else {
        self.imageUris = try container.decodeIfPresent([String: URL].self, forKey: .imageUris)
      }
      
      self.type = try container.decode(String.self, forKey: DraftmancerCard.Face.CodingKeys.type)
      self.subtypes = try container.decodeIfPresent([String].self, forKey: DraftmancerCard.Face.CodingKeys.subtypes)
      self.oracleText = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.oracleText)
      self.power = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.power)
      self.toughness = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.toughness)
      self.loyalty = try container.decodeIfPresent(String.self, forKey: DraftmancerCard.Face.CodingKeys.loyalty)
      self.keywords = try container.decodeIfPresent([String].self, forKey: DraftmancerCard.Face.CodingKeys.keywords)
    }
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
  var artist: String?
  var printedNames: [String: URL]?
  var image: URL?
  var set: String?
  var collectorNumber: String?
  var rarity: Rarity?
  var subtypes: [String]?
  var rating: Int?
  var layout: String?
  var back: Face?
  var relatedCards: [Face]?
  var relatedCardIdentifiers: [MTGCardIdentifier]?
  var draftEffects: [DraftEffect]?
  
  var power: String?
  var toughness: String?
  var oracleText: String?
  var loyalty: String?
  var keywords: [String]?
  
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
    
    self.relatedCardIdentifiers = nil
    
    self.power = mtgCard.power
    self.toughness = mtgCard.toughness
    self.loyalty = mtgCard.loyalty
    self.oracleText = mtgCard.oracleText
    self.keywords = mtgCard.keywords
    self.artist = mtgCard.artist
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.name, forKey: .name)
    try container.encode(self.manaCost, forKey: .manaCost)
    try container.encode(self.type, forKey: .type)
    
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
    try container.encodeIfPresent(self.subtypes, forKey: .subtypes)
    try container.encodeIfPresent(self.rating, forKey: .rating)
    try container.encodeIfPresent(self.layout, forKey: .layout)
    try container.encodeIfPresent(self.back, forKey: .back)
    
    if let relatedCardIdentifiers = self.relatedCardIdentifiers {
      try container.encode(relatedCardIdentifiers.map(String.init), forKey: .relatedCards)
    } else {
      try container.encodeIfPresent(self.relatedCards, forKey: .relatedCards)
    }
    
    try container.encodeIfPresent(self.draftEffects, forKey: .draftEffects)
    
    try container.encodeIfPresent(self.power, forKey: .power)
    try container.encodeIfPresent(self.toughness, forKey: .toughness)
    try container.encodeIfPresent(self.oracleText, forKey: .oracleText)
    try container.encodeIfPresent(self.loyalty, forKey: .loyalty)
    try container.encodeIfPresent(self.keywords, forKey: .keywords)
  }
  
  enum CodingKeys: CodingKey {
    case name
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
    case loyalty
    case keywords
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.name = try container.decode(String.self, forKey: .name)
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
    self.loyalty = try container.decodeIfPresent(String.self, forKey: .loyalty)
    self.keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
  }
}

extension DraftmancerCard {
  var mtgCard: MTGCard? {
    var typeLine = type
    if let subtypes = subtypes {
      typeLine += " — \(subtypes.joined(separator: " "))"
    }
    guard let rarity = self.rarity.flatMap({ MTGCard.Rarity.init(rawValue: $0.rawValue) }) else { return nil }
    
    var imageURIs = self.imageUris ?? [:]
    
    if let image = image, imageURIs.isEmpty {
      imageURIs["normal"] = image
      imageURIs["large"] = image
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
    
    return .init(
      scryfallID: UUID(),
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
      layout: self.layout ?? (self.type.lowercased().contains("token") ? "token" : self.type.lowercased().contains("emblem") ? "emblem" : "normal"),
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
      keywords: self.keywords,
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

struct DraftmancerSet: Encodable {
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

let draftmancerSets: [DraftmancerSet]? = {
  do {
    let urls = try urlsForResources(withExtension: "txt", subdirectory: "Draftmancer")
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    var draftmancerSets: [DraftmancerSet] = urls.compactMap { url -> DraftmancerSet? in
      guard let rawData = try? Data(contentsOf: url), let rawString = String(data: rawData, encoding: .utf8) else { return nil }
      let string = draftMancerStringSection("CustomCards", from: rawString)
      guard let data = string?.data(using: .utf8) else { return nil }
      
      do {
        let cards = try decoder.decode([DraftmancerCard].self, from: data)
        
        return DraftmancerSet(
          cards: cards,
          name: url.deletingPathExtension().lastPathComponent
        )
      } catch {
        print("‼️ Error loading cards from \(url.deletingPathExtension().lastPathComponent):", error)
        return nil
      }
    }
    
    let fromCockatrice: [DraftmancerSet] = loadedCockatriceDatabases?.map {
      DraftmancerSet.init(cockatriceDatabase: $0)
    } ?? []
    
    draftmancerSets.append(contentsOf: fromCockatrice)
    
    let fromManifesto: [DraftmancerSet] = loadedManifestoSets?.map {
      DraftmancerSet.init(manifestoSet: $0)
    } ?? []
    
    draftmancerSets.append(contentsOf: fromManifesto)
    
    // Fill in missing sets and collector numbers
    var usedCollectorNumbersForSets: [String: Set<Int>] = [:]
    draftmancerSets = draftmancerSets.map {
      var set = $0
      
      set.cards = set.cards.map { card in
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
    
    return draftmancerSets.sorted { $0.name < $1.name }
  } catch {
    print("Error loading Draftmancer sets:", error)
    return nil
  }
}()

private func addBracketsToManaCost(_ manaCost: String) -> String {
  var result = ""
  var buffer = ""
  var insideBrackets = false
  
  // Iterate over each character in the string
  for (index, char) in manaCost.enumerated() {
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
      // If we encounter a slash, it's part of a hybrid symbol
      if char == "/" && index > 0 && !buffer.isEmpty {
        buffer.append(char)
        continue
      }
      
      // Check if this is part of a hybrid symbol (e.g., W/U)
      if index < manaCost.count - 1 && manaCost[manaCost.index(manaCost.startIndex, offsetBy: index + 1)] == "/" {
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
  }
  
  // Append any remaining buffer (for complex costs like "W/U")
  if !buffer.isEmpty {
    result.append("{\(buffer)}")
  }
  
  return result
}

func getBuiltinDraftmancerCards(_ req: Request) throws -> NIOCore.EventLoopFuture<Vapor.Response> {
  return req.eventLoop.makeCompletedFuture {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "application/json")
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.keyEncodingStrategy = .convertToSnakeCase
    
    guard let responses = draftmancerSets else {
      return .init(
        status: .internalServerError, headers: headers
      )
    }
    
    let data = try encoder.encode(responses)
    let string = String.init(data: data, encoding: .utf8) ?? ""
    
    return .init(
      status: .ok, headers: headers, body: .init(string: string)
    )
  }
}

let loadedDraftmancerCards: [MTGCard]? = {
  guard var sets = draftmancerSets else { return nil }
  
  return Array(sets.map { $0.cards.compactMap(\.mtgCard) }.joined())
}()

// MARK: Cockatrice

struct CockatriceCardDatabase: Codable {
  let version: String
  
  struct Sets: Codable {
    let set: [Set]
  }
  
  struct Cards: Codable {
    let card: [Card]
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
    
    let name: String
    let set: Set
    var rarity: String? { return set.rarity }
    var imageURL: String? { return set.imageURL }
    private let color: String
    var colors: [String] { return color.compactMap( { MTGColor(rawValue: String($0)) }).map(\.rawValue).filter { $0.count == 1 } }
    let manaCost: String?
    let cmc: Double?
    let type: String
    private let pt: String?
    var power: String? { return pt?.components(separatedBy: "/").first }
    var toughness: String? { return pt?.components(separatedBy: "/").last }
    let loyalty: String?
    let text: String
    private let token: Int?
    var isToken: Bool { token == 1 }
    let reverseRelated: [String]
    
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
  
  let sets: Sets
  let cards: Cards
}

extension DraftmancerCard {
  init(cockatriceCard: CockatriceCardDatabase.Card) {
    let typeLine = cockatriceCard.type.components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    let type = typeLine.first ?? ""
    var subtypes: [String]?
    if typeLine.count > 1 {
      subtypes = typeLine.last?.components(separatedBy: " ")
    }
    
    var name = cockatriceCard.name
    
    if cockatriceCard.isToken && name.hasPrefix("\(cockatriceCard.set.value) ") {
      name = String(name[name.index(name.startIndex, offsetBy: cockatriceCard.set.value.count+1)...])
    }
    
    self.init(
      name: name,
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
      
      if cockatriceCard.isToken {
        draftmancerCard.set = "T" + (draftmancerCard.set ?? "")
      }
      
      return draftmancerCard
    }
    
    for cockatriceCard in cockatriceDatabase.cards.card where !cockatriceCard.reverseRelated.isEmpty {
      for relationship in cockatriceCard.reverseRelated {
        guard let index = cards.firstIndex(where: { $0.name == relationship }) else { continue }
        
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
    
    var cardsGroupedBySet: [String: [DraftmancerCard]] = .init(grouping: cards, by: \.set!)
    
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
      draftmancerString += "\n[DefaultSlot]\n"
      for card in cards {
        draftmancerString += [card.name, card.set.flatMap { "(\($0.uppercased()))" }, card.collectorNumber].compactMap{ $0 }.joined(separator: " ") + "\n"
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
