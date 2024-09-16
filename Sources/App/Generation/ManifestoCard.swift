//
//  ManifestoCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 9/15/24.
//
import Foundation

struct ManifestoSet: Codable {
  let name: String
  let code: String
  let gathererCode: String
  let magicCardsInfoCode: String
  let releaseDate: String
  let releaseNumber: Int
  let border: String
  let type: String
  let mkmName: String
  let mkmID: String
  let cards: [ManifestoCard]
  
  enum CodingKeys: String, CodingKey {
    case name = "name"
    case code = "code"
    case gathererCode = "gathererCode"
    case magicCardsInfoCode = "magicCardsInfoCode"
    case releaseDate = "releaseDate"
    case releaseNumber = "release_number"
    case border = "border"
    case type = "type"
    case mkmName = "mkm_name"
    case mkmID = "mkm_id"
    case cards = "cards"
  }
}

// MARK: - Card
struct ManifestoCard: Codable {
  let artist: String
  let convertedManaCost: Int
  let faceConvertedManaCost: Int
  let colors: [String]
  let colorIdentity: [String]
  let designer: String
  let flavor: String
  let frameType: String
  let id: String
  let imageName: String
  let layout: String
  let manaCost: String
  let multiverseid: Int
  let name: String
  let number: String
  let rarity: String
  let relatedCards: RelatedCards
  let subtypes: [String]?
  let supertypes: [String]?
  let text: String
  let type: String
  let types: [String]
  let power: String?
  let toughness: String?
  let loyalty: String?
  
  enum CodingKeys: String, CodingKey {
    case artist = "artist"
    case convertedManaCost = "convertedManaCost"
    case faceConvertedManaCost = "faceConvertedManaCost"
    case colors = "colors"
    case colorIdentity = "colorIdentity"
    case designer = "designer"
    case flavor = "flavor"
    case frameType = "frameType"
    case id = "id"
    case imageName = "imageName"
    case layout = "layout"
    case manaCost = "manaCost"
    case multiverseid = "multiverseid"
    case name = "name"
    case number = "number"
    case rarity = "rarity"
    case relatedCards = "relatedCards"
    case subtypes = "subtypes"
    case supertypes = "supertypes"
    case text = "text"
    case type = "type"
    case types = "types"
    case power = "power"
    case toughness = "toughness"
    case loyalty = "loyalty"
  }
}

// MARK: - RelatedCards
struct RelatedCards: Codable {
  
}

extension DraftmancerCard {
  init(manifestoCard: ManifestoCard, set: String) {
    let imageURL = URL(string: "https://revolution-manifesto.herokuapp.com/cards/\(set)/\(manifestoCard.number).jpg")!
    
    let typeLine = manifestoCard.type.components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    let type = typeLine.first ?? ""
    var subtypes: [String]?
    if typeLine.count > 1 {
      subtypes = typeLine.last?.components(separatedBy: " ")
    }
    
    var name = manifestoCard.name
    if let index = name.firstIndex(of: "_") {
      name = String(name[..<index])
    }
    
    self.init(
      name: name,
      manaCost: manifestoCard.manaCost,
      type: type,
      imageUris: nil,
      colors: manifestoCard.colors,
      printedNames: nil,
      image: imageURL,
      set: set,
      collectorNumber: manifestoCard.number,
      rarity: Rarity(rawValue: manifestoCard.rarity),
      subtypes: subtypes,
      rating: nil,
      layout: manifestoCard.layout,
      back: nil,
      relatedCards: nil,
      relatedCardIdentifiers: nil,
      draftEffects: nil,
      power: manifestoCard.power,
      toughness: manifestoCard.toughness,
      oracleText: manifestoCard.text,
      loyalty: manifestoCard.loyalty,
      keywords: nil
    )
  }
}

struct ManifestoDatabase: Codable {
  let data: [String: ManifestoSet]
}

let loadedManifestoSets: [ManifestoSet]? = {
//  guard let url = try? urlsForResources(withExtension: "json", subdirectory: "Manifesto") else { return nil }
  
  let url = urlForResource("AllSets", withExtension: "json", subdirectory: "Manifesto")
  
  let decoder = JSONDecoder()
  
  do {
    guard let data = try? Data(contentsOf: url) else { print("Nothing at \(url)"); return nil }
    let database = try decoder.decode(ManifestoDatabase.self, from: data)
    
    print("✅ Loaded Manifesto \(database.data.count) sets")
    return Array(database.data.values)
  } catch {
    print("‼️ Error loading Manifesto set from \(url.lastPathComponent):", error)
    return nil
  }
}()

extension DraftmancerSet {
  init(manifestoSet: ManifestoSet) {
    let cards: [DraftmancerCard] = manifestoSet.cards.map { card in
        .init(manifestoCard: card, set: manifestoSet.code)
    }
    
    self.init(
      cards: cards,
      name: manifestoSet.name
    )
  }
}
