import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public typealias Card = Swiftfall.Card

public class Swiftfall {
  
  static let scryfall = "https://api.scryfall.com/"
  
  public struct Symbol: Codable, CustomStringConvertible {
    
    // The plaintext symbol. Often surrounded with curly braces {}. Note that not all symbols are ASCII text (for example, {∞}).
    public let symbol: String
    
    // An alternate version of this symbol, if it is possible to write it without curly braces.
    public let looseVariant: String?
    
    // An English snippet that describes this symbol. Appropriate for use in alt text or other accessible communication formats.
    public let english: String
    
    // True if it is possible to write this symbol “backwards”. For example, the official symbol {U/P} is sometimes written as {P/U} or {P\U} in informal settings. Note that the Scryfall API never writes symbols backwards in other responses. This field is provided for informational purposes.
    public let transposable: Bool
    
    // True if this is a mana symbol.
    public let representsMana: Bool?
    
    // True if this symbol appears in a mana cost on any Magic card. For example {20} has this field set to false because {20} only appears in Oracle text, not mana costs.
    public let appearsInManaCosts: Bool
    
    // A decimal number representing this symbol’s converted mana cost. Note that mana symbols from funny sets can have fractional converted mana costs.
    public let cmc: Double?
    
    // True if this symbol is only used on funny cards or Un-cards.
    public let funny: Bool
    
    // An array of colors that this symbol represents.
    public let colors: [String]
    
    // String that is printed when print(self) is called.
    public var description: String {
      return "Symbol: \(symbol)\nEnglish: \(english)\n"
    }
  }
  
  public struct SymbolList: Codable, CustomStringConvertible {
    
    // if there are more pages, should always be false
    public let hasMore: Bool
    
    // the symbols
    public let data: [Symbol]
    
    public var description: String {
      var text = ""
      for sym in data {
        text += sym.description
        text += "\n"
      }
      return text
    }
  }
  
  public struct RulingList: Codable, CustomStringConvertible, Sendable {
    // Contains rulings
    public let data: [Ruling]
    
    public let hasMore: Bool
    
    public var description: String {
      var text = ""
      for rule in data {
        text += rule.description
        text += "\n"
      }
      return text
    }
  }
  
  // A Catalog object contains an array of Magic datapoints (words, card values, etc). Catalog objects are provided by the API as aids for building other Magic software and understanding possible values for a field on Card objects.
  public struct Catalog: Codable, CustomStringConvertible, Sendable {
    public let uri: String?
    public let totalValues: Int?
    public let totalItems: Int?
    public let data:[String]
    
    public enum CatalogType: String, CaseIterable {
      case cardNames = "card-names"
      case artistNames = "artist-names"
      case wordBank = "word-bank"
      case supertypes = "supertypes"
      case cardTypes = "card-types"
      case artifactTypes = "artifact-types"
      case battleTypes = "battle-types"
      case creatureTypes = "creature-types"
      case enchantmentTypes = "enchantment-types"
      case landTypes = "land-types"
      case planeswalkerTypes = "planeswalker-types"
      case spellTypes = "spell-types"
      case powers
      case toughnesses
      case loyalties
      case watermarks
      case keywordAbilities = "keyword-abilities"
      case keywordActions = "keyword-actions"
      case abilityWords = "ability-words"
      case flavorWords = "flavor-words"
    }
    
    public var description: String {
      var text = ""
      for thing in data {
        text += "\(thing)\n"
      }
      return text
    }
  }
  
  public struct Ruling: Codable, CustomStringConvertible, Hashable, Sendable {
    //     A computer-readable string indicating which company produced this ruling, either wotc or scryfall.
    public let source: String
    
    // The date when the ruling or note was published.
    public let publishedAt: String
    
    // The text of the ruling.
    public let comment: String
    
    public let oracleId: UUID
    
    // A simple print function for a ruling
    public var description: String {
      return "Source: \(source)\nComments: \(comment)\n"
    }
  }
  
  // Sometimes we will cause and error and the API will tell us what it is.
  public struct ScryfallError: Codable, Error, CustomStringConvertible {
    
    let code: String
    let type: String?
    let status: Int
    let details: String
    let warnings: [String]?
    
    public var description: String {
      return "Error: \(code)\nDetails: \(details)\n"
    }
    
    public var localizedDescription: String {
      details
    }
  }
  
  // struct which contains all sets
  public struct SetList: Codable, CustomStringConvertible, Sendable {
    // data is an array of Sets
    public let data: [ScryfallSet]
    
    public let hasMore: Bool
    
    // prints each set
    public var description: String {
      var text = ""
      var i = 0
      for set in data {
        text += "Set Number: \(i)\n"
        text += set.description
        text += "\n"
        i = i + 1
      }
      return text
    }
  }
  
  // struct which contrains a list of cards
  public struct CardList: Codable, CustomStringConvertible {
    // an array of Cards
    public let data: [Card]
    
    public let hasMore: Bool
    
    public let nextPage: URL?
    
    public let totalCards: Int?
    
    // prints each set
    public var description: String {
      var text = ""
      var i = 0
      for card in data {
        text += "\n"
        text += card.description
        text += "\n"
        i = i + 1
      }
      return text
    }
  }
  
  // A Magic set is how cards are released in reality.
  // It contains no cards in Swiftfall or Scryfall.
  public struct ScryfallSet: Codable, CustomStringConvertible, Hashable, Sendable {
    
    // The unique three or four-letter code for this set.
    public var code: String?
    
    // The unique code for this set on MTGO, which may differ from the regular code.
    public let mtgo: String?
    
    //The English name of the set.
    public var name: String
    
    //
    public let uri: String
    
    // Scryfall API URI
    public let scryfallUri: String
    
    // A Scryfall API URI that you can request to begin paginating over the cards in this set.
    public let searchUri: URL?
    
    // the release date of the set
    public let releasedAt: Date?
    
    // A computer-readable classification for this set. See below.
    public let setType: String
    
    // The number of cards in this set.
    public let cardCount: Int
    
    // Bool for if the card is digital
    public let digital: Bool
    
    // Bool for if the card is foil
    public let foilOnly: Bool
    
    // Block code, like self.code but the for the block the set is a member of
    public let blockCode: String?
    
    // The block or group name code for this set, if any.
    public let block: String?
    
    public let printedSize: Int?
    
    //A URI to an SVG file for this set’s icon on Scryfall’s CDN. Hotlinking this image isn’t recommended, because it may change slightly over time. You should download it and use it locally for your particular user interface needs.
    public let iconSvgUri: String?
    
    private func getCards(searchURL: URL) async -> [CardList?] {
      
      do {
        let cardlist: CardList = try await parseResource(url: searchURL)
        var cardListArray: [CardList?] = []
        if cardlist.hasMore, let nextPage = cardlist.nextPage {
          await cardListArray += self.getCards(searchURL: nextPage)
        }
        cardListArray.append(cardlist)
        return cardListArray
      } catch {
        return []
      }
    }
    
    public func getCards() async -> [CardList?] {
      
      guard let searchUri else { return [] }
      
      do {
        let cardlist: CardList = try await parseResource(url: searchUri)
        
        var cardListArray: [CardList?] = []
        
        if cardlist.hasMore, let nextPage = cardlist.nextPage {
          let nextCardListArray = await self.getCards(searchURL: nextPage)
          for list in nextCardListArray {
            cardListArray.append(list)
          }
        }
        cardListArray.append(cardlist)
        return cardListArray
      } catch {
        return []
      }
    }
    
    // prints the minimal data for the set
    public var description: String{
      var text = ""
      text += "Name: \(name)\n"
      text += "Code: \(code)\n"
      if let block {
        text += "Block: \(block)\n"
      }
      text += "Number of Cards: \(self.cardCount)\n"
      if let releasedAt {
        text += "Release Date: \(releasedAt)\n"
      }
      text += "Set Type: \(setType)\n"
      
      return text
    }
  }
  
  public struct Card: Codable, CustomStringConvertible, Equatable, Hashable, Sendable, Identifiable {
    var object: String
    
    internal init(prices: Swiftfall.Card.Prices? = nil, id: UUID, oracleId: UUID? = nil, multiverseIds: [Int], mtgoId: Int? = nil, arenaId: Int? = nil, mtgoFoilId: Int? = nil, tcgplayerId: Int? = nil, tcgplayerEtchedId: Int? = nil, name: String, flavorName: String? = nil, uri: String? = nil, scryfallUri: String, cardFaces: [Swiftfall.Card.Face]? = nil, printsSearchUri: String, securityStamp: String? = nil, rulingsUri: String, layout: String, cmc: Double? = nil, typeLine: String? = nil, oracleText: String? = nil, manaCost: String? = nil, power: String? = nil, toughness: String? = nil, loyalty: String? = nil, defense: String? = nil, colors: [String]? = nil, colorIndicator: [String]? = nil, colorIdentity: [String]? = nil, keywords: [String]? = nil, producedMana: [String]? = nil, purchaseUris: [String : URL]? = nil, flavorText: String? = nil, attractionLights: [Int]? = nil, illustrationId: String? = nil, imageUris: [String : URL]? = nil, legalities: [String : String], reserved: Bool, edhrecRank: Int? = nil, allParts: [Swiftfall.Card.RelatedCard]? = nil, set: String, setName: String, setType: String? = nil, rarity: String, cardBackId: UUID? = nil, artist: String? = nil, collectorNumber: String, digital: Bool, highresImage: Bool, lifeModifier: String? = nil, handModifier: String? = nil, frame: String, frameEffects: [String]? = nil, promoTypes: [String]? = nil, oversized: Bool? = nil, fullArt: Bool, watermark: String? = nil, borderColor: String, storySpotlightNumber: Int? = nil, storySpotlightUri: String? = nil, storySpotlight: Bool? = nil, contentWarning: Bool? = nil, printedName: String? = nil, printedText: String? = nil, printedTypeLine: String? = nil, textless: Bool, lang: Swiftfall.Card.Language, foil: Bool, finishes: [Swiftfall.Card.Finish], nonfoil: Bool, promo: Bool, booster: Bool, releasedAt: String, relatedUris: [String : URL]? = nil, games: [String], gameChanger: Bool? = nil, variation: Bool? = nil, variationOf: UUID? = nil) {
      self.object = "card"
      self.prices = prices
      self.id = id
      self.oracleId = oracleId
      self.multiverseIds = multiverseIds
      self.mtgoId = mtgoId
      self.arenaId = arenaId
      self.mtgoFoilId = mtgoFoilId
      self.tcgplayerId = tcgplayerId
      self.tcgplayerEtchedId = tcgplayerEtchedId
      self.name = name
      self.flavorName = flavorName
      self.uri = uri
      self.scryfallUri = scryfallUri
      self.cardFaces = cardFaces
      self.printsSearchUri = printsSearchUri
      self.securityStamp = securityStamp
      self.rulingsUri = rulingsUri
      self.layout = layout
      self.cmc = cmc
      self.typeLine = typeLine
      self.oracleText = oracleText
      self.manaCost = manaCost
      self.power = power
      self.toughness = toughness
      self.loyalty = loyalty
      self.defense = defense
      self.colors = colors
      self.colorIndicator = colorIndicator
      self.colorIdentity = colorIdentity
      self.keywords = keywords
      self.producedMana = producedMana
      self.purchaseUris = purchaseUris
      self.flavorText = flavorText
      self.attractionLights = attractionLights
      self.illustrationId = illustrationId
      self.imageUris = imageUris
      self.legalities = legalities
      self.reserved = reserved
      self.edhrecRank = edhrecRank
      self.allParts = allParts
      self.set = set
      self.setName = setName
      self.setType = setType
      self.rarity = rarity
      self.cardBackId = cardBackId
      self.artist = artist
      self.collectorNumber = collectorNumber
      self.digital = digital
      self.highresImage = highresImage
      self.lifeModifier = lifeModifier
      self.handModifier = handModifier
      self.frame = frame
      self.frameEffects = frameEffects
      self.promoTypes = promoTypes
      self.oversized = oversized
      self.fullArt = fullArt
      self.watermark = watermark
      self.borderColor = borderColor
      self.storySpotlightNumber = storySpotlightNumber
      self.storySpotlightUri = storySpotlightUri
      self.storySpotlight = storySpotlight
      self.contentWarning = contentWarning
      self.printedName = printedName
      self.printedText = printedText
      self.printedTypeLine = printedTypeLine
      self.textless = textless
      self.lang = lang
      self.foil = foil
      self.finishes = finishes
      self.nonfoil = nonfoil
      self.promo = promo
      self.booster = booster
      self.releasedAt = releasedAt
      self.relatedUris = relatedUris
      self.games = games
      self.gameChanger = gameChanger
      self.variation = variation
      self.variationOf = variationOf
    }
    
    
    // Some cards have cards closely related to them. They will contain an array of RelatedCards.
    public struct RelatedCard: Codable, CustomStringConvertible, Equatable, Hashable, Sendable {
      
      // An unique ID for this card in Scryfall’s database.
      public let id: UUID
      
      // The name of this particular related card.
      public let name: String
      
      // A URI where you can retrieve a full object describing this card on Scryfall’s API.
      public let uri: String
      
      public let component: String?
      
      public let typeLine: String?
      
      public var description: String {
        return "Name: \(name)\nURI: \(uri)"
      }
    }
    
    public struct Face: Codable, CustomStringConvertible, Equatable, Hashable, Sendable {
      
      // All of these variables are the same as a normal card.
      
      public let name: String?
      
      public let flavorName: String?
      
      public let manaCost: String?
      
      public let cmc: Double?
      
      public let typeLine: String?
      
      public let oracleText: String?
      
      public let colors: [String]?
      
      public let colorIndicator: [String]?
      
      public let power: String?
      
      public let toughness: String?
      
      public let loyalty: String?
      
      public let defense: String?
      
      public let flavorText: String?
      
      public let illustrationId: String?
      
      public let imageUris: [String: URL]?
      
      public let oracleId: UUID?
      
      public let watermark: String?
      
      /// The localized name printed on this card, if any.
      public let printedName: String?
      
      /// The localized text printed on this card, if any.
      public let printedText: String?
      
      /// The localized type line printed on this card, if any.
      public let printedTypeLine: String?
      
      public var description: String {
        var text = ""
        // Each variable is tested to see if printing it makes sense.
        text += "Name: \(name!)\n"
        
        if let manaCost {
          text += "Cost: \(manaCost)\n"
        }
        if let typeLine {
          text += "Type Line: \(typeLine)\n"
        }
        if let oracleText {
          text += "Oracle Text:\n\(oracleText)\n"
        }
        if let power, let toughness {
          text += "Power: \(power)\nToughness: \(toughness)\n"
        }
        if let loyalty {
          text += "Loyalty: \(loyalty)\n"
        }
        return text
      }
    }
    
    public struct Prices: Codable, CustomStringConvertible, Equatable, Hashable, Sendable {
      
      public let usd: String?
      
      public let usdFoil: String?
      
      public let usdEtched: String?
      
      public let usdGlossy: String?
      
      public let eur: String?
      
      public let eurFoil: String?
      
      public let tix: String?
      
      public var description: String {
        var text = ""
        if let usd = self.usd {
          text += "usd: \(usd)"
        }
        if let usdFoil = self.usdFoil {
          text += "usdFoil: \(usdFoil)"
        }
        if let eur = self.eur {
          text += "eur: \(eur)"
        }
        if let eurFoil = self.eurFoil {
          text += "eurFoil: \(eurFoil)"
        }
        if let tix = self.tix {
          text += "tix: \(tix)"
        }
        if let usdEtched = usdEtched {
          text += "usdEtched: \(usdEtched)"
        }
        if let usdGlossy = usdGlossy {
          text += "usdGlossy: \(usdGlossy)"
        }
        return text
      }
      
    }
    
    public enum Language: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
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
      case quenya = "qya"
      
      var name: String {
        switch self {
        case .english:
          return "English"
        case .spanish:
          return "Spanish"
        case .french:
          return "French"
        case .german:
          return "German"
        case .italian:
          return "Italian"
        case .portuguese:
          return "Portuguese"
        case .japanese:
          return "Japanese"
        case .korean:
          return "Korean"
        case .russian:
          return "Russian"
        case .simplifiedChinese:
          return "Simplified Chinese"
        case .traditionalChinese:
          return "Traditional Chinese"
        case .hebrew:
          return "Hebrew"
        case .latin:
          return "Latin"
        case .ancientGreek:
          return "Ancient Greek"
        case .arabic:
          return "Arabic"
        case .sanskrit:
          return "Sanskrit"
        case .phyrexian:
          return "Phyrexian"
        case .quenya:
          return "Quenya"
        }
      }
      
      var value: Int {
        switch self {
        case .english:
          return 0
        case .spanish:
          return 1
        case .french:
          return 2
        case .german:
          return 3
        case .italian:
          return 4
        case .portuguese:
          return 5
        case .japanese:
          return 6
        case .korean:
          return 7
        case .russian:
          return 8
        case .simplifiedChinese:
          return 9
        case .traditionalChinese:
          return 10
        case .hebrew:
          return 11
        case .latin:
          return 12
        case .ancientGreek:
          return 13
        case .arabic:
          return 14
        case .sanskrit:
          return 15
        case .phyrexian:
          return 16
        case .quenya:
          return 17
        }
      }
      
      var displayAbbreviation: String {
        switch self {
        case .simplifiedChinese: return "汉语"
        case .traditionalChinese: return "漢語"
        default: return rawValue.uppercased()
        }
      }
    }
    
    public enum SecurityStamp: String, Codable, Equatable, Hashable, CaseIterable {
          case oval
          case triangle
          case acorn
          case arena
          case heart
          
          public var descriptiveString: String {
            switch self {
            case .oval: "ovular"
            case .triangle: "triangular"
            case .acorn: "acorn/funny"
            case .arena: "Arena"
            case .heart: "heart"
            }
          }
        }
    
    public let prices: Prices?
    
    //    public struct Preview: Codable, Equatable, Hashable {
    //      let source: String
    //      let sourceUri: String
    //      var sourceURL: URL? {
    //        URL(string: sourceUri)
    //      }
    //      let previewedAt: Date
    //    }
    //
    //    public let preview: Preview?
    
    // A unique ID for this card in Scryfall’s database.
    public let id: UUID
    
    // A unique ID for this card’s oracle identity. This value is consistent across reprinted card editions, and unique among different cards with the same name (tokens, Unstable variants, etc).
    public let oracleId: UUID?
    
    // This card’s multiverse IDs on Gatherer, if any, as an array of integers. Note that Scryfall includes many promo cards, tokens, and other esoteric objects that do not have these identifiers.
    public let multiverseIds: [Int]
    
    // This card’s Magic Online ID (also known as the Catalog ID), if any. A large percentage of cards are not available on Magic Online and do not have this ID.
    public let mtgoId: Int?
    
    // This card’s Arena ID
    public let arenaId: Int?
    
    // This card’s foil Magic Online ID (also known as the Catalog ID), if any. A large percentage of cards are not available on Magic Online and do not have this ID.
    public let mtgoFoilId: Int?
    
    public let tcgplayerId: Int?
    
    public let tcgplayerEtchedId: Int?
    
    // The name of this card. If this card has multiple faces, this field will contain both names separated by ␣//␣.
    public let name: String
    
    public let flavorName: String?
    
    // A link to this card object on Scryfall’s API.
    public let uri: String?
    
    // A link to this card’s permapage on Scryfall’s website.
    public let scryfallUri: String
    
    public var scryfallURL: URL {
      URL(string: scryfallUri)!
    }
    
    // If the card has multiple face this is an array of the card faces
    public let cardFaces: [Face]?
    
    // A link to where you can begin paginating all re/prints for this card on Scryfall’s API.
    /// This should be a URL, but has to be a String in order to support migrating old bookmarks.
    public let printsSearchUri: String
    
    public let securityStamp: String?
    
    public func getAllPrints() async throws -> [Card] {
      try await getAllCards(searchURL: URL(string: printsSearchUri)!)
    }
    
    public func getOtherLanguages() async throws -> [Card] {
      try await getAllCards(query: "e:\"\(self.set)\" cn:\"\(collectorNumber)\" lang:any", unique: .prints)
    }
    
    public func getSameLanguagePrints() async throws -> [Card] {
      let query = "!\"\(name)\" lang:\(lang.rawValue)"
      return try await getAllCards(query: query, unique: .prints)
    }
    
    // A link to this card’s rulings on Scryfall’s API.
    /// This should be a URL, but has to be a String in order to support migrating old bookmarks.
    public let rulingsUri: String
    
    // A computer-readable designation for this card’s layout. See the layout article.
    public let layout: String
    
    // The card’s converted mana cost. Note that some funny cards have fractional mana costs.
    public let cmc: Double?
    
    // The type line of this card.
    public let typeLine: String?
    
    // The Oracle text for this card, if any.
    public let oracleText: String?
    
    // The mana cost for this card. This value will be any empty string "" if the cost is absent. Remember that per the game rules, a missing mana cost and a mana cost of {0} are different values.
    public let manaCost: String?
    
    // This card’s power, if any. Note that some cards have powers that are not numeric, such as *.
    public let power: String?
    
    // This card’s toughness, if any. Note that some cards have toughnesses that are not numeric, such as *.
    public let toughness: String?
    
    // This loyalty if any. Note that some cards have loyalties that are not numeric, such as X.
    public let loyalty: String?
    
    public let defense: String?
    
    // This card’s colors.
    public let colors: [String]?
    
    // This card’s color indicator.
    public let colorIndicator: [String]?
    
    // This card’s color identity.
    public let colorIdentity: [String]?
    
    public let keywords: [String]?
    
    public let producedMana: [String]?
    
    // Online listings for these cards names.
    public let purchaseUris: [String:URL]?
    
    // Flavor text on the card, if there is any
    public let flavorText: String?
    
    public let attractionLights: [Int]?
    
    // id of the illustration
    public let illustrationId: String?
    
    // uris of the images
    public let imageUris: [String:URL]?
    
    // legality in different formats
    public let legalities: [String:String]
    
    // is or is not on the reserved list
    public let reserved: Bool
    
    // This card’s overall rank/popularity on EDHREC. Not all carsd are ranked.
    public let edhrecRank: Int?
    
    // If this card is closely related to other cards, this property will be an array with.
    public let allParts: [RelatedCard]?
    
    // This card's set code
    public let set: String
    
    // This card's set's full name
    public let setName: String
    
    public let setType: String?
    
    // This card's rarity. This is not the same for all versions of the card.
    public let rarity: String
    
    public let cardBackId: UUID?
    
    // This card's artist
    public let artist: String?
    
    // This card’s collector number. Note that collector numbers can contain non-numeric characters, such as letters or ★.
    public let collectorNumber: String
    
    // True if this is a digital card on Magic Online.
    public let digital: Bool
    
    // True if this card’s imagery is high resolution.
    public let highresImage: Bool
    
    public let lifeModifier: String?
    
    public let handModifier: String?
    
    // This card’s frame layout.
    // https://scryfall.com/docs/api/layouts
    public let frame: String
    
    // This card’s frame effects, if any.
    // https://scryfall.com/docs/api/layouts
    public let frameEffects: [String]?
    
    public let promoTypes: [String]?
    
    public let oversized: Bool?
    
    // True if this card’s artwork is larger than normal.
    public let fullArt: Bool
    
    // This card’s watermark, if any.
    public let watermark: String?
    
    // This card’s border color: black, borderless, gold, silver, or white.
    public let borderColor: String
    
    // This card’s story spotlight number, if any.
    public let storySpotlightNumber: Int?
    
    // A URL to this cards’s story article, if any.
    public let storySpotlightUri: String?
    
    // If the card is a story spotlight
    public let storySpotlight: Bool?
    
    // If the card has a content warning
    public let contentWarning: Bool?
    
    /// The localized name printed on this card, if any.
    public let printedName: String?
    
    /// The localized text printed on this card, if any.
    public let printedText: String?
    
    /// The localized type line printed on this card, if any.
    public let printedTypeLine: String?
    
    public let textless: Bool
    
    public let lang: Language
    
    /// True if this printing exists in a foil version.
    public let foil: Bool
    
    public enum Finish: String, Codable, Equatable, Hashable, CaseIterable, Comparable, Sendable {
      public static func < (lhs: Swiftfall.Card.Finish, rhs: Swiftfall.Card.Finish) -> Bool {
        return lhs.value < rhs.value
      }
      
      case nonfoil, foil, etched, glossy
      
      var value: Int {
        switch self {
        case .nonfoil: return 0
        case .foil: return 1
        case .etched: return 2
        case .glossy: return 3
        }
      }
    }
    
    public let finishes: [Finish]
    
    /// True if this printing exists in a nonfoil version.
    public let nonfoil: Bool
    
    public let promo: Bool
    
    public func getRulings() async throws -> RulingList {
      return try await parseResource(url: URL(string: rulingsUri)!)
    }
    
    public let booster: Bool
    
    /// The date this card was first released.
    public let releasedAt: String
    
    public var releaseDate: Date {
      Swiftfall.dateFormatter.date(from: releasedAt)!
    }
    
    public let relatedUris: [String: URL]?
    
    public let games: [String]
    
    /// True if this card is on the [Commander Game Changer list](https://mtg.wiki/page/Commander_(format)/Game_Changers).
    private let gameChanger: Bool?
    
    public var isGameChanger: Bool {
      gameChanger == true
    }
    
    private let variation: Bool?
    
    // Whether this card is a variation of another printing.
    public var isVariation: Bool {
      variation == true
    }
    
    // The printing ID of the printing this card is a variation of.
    public let variationOf: UUID?
    
    // return string when self is used as a parameter for print
    public var description: String {
      var text = ""
      // if the card has multiple faces, print them
      if (self.cardFaces) != nil {
        for face in cardFaces! {
          text += face.description
          text += "\n"
        }
        return text
      }
      // Each variable is tested to see if printing it makes sense.
      text += "Name: \(name)\n"
      if let manaCost {
        text += "Cost: \(manaCost)\n"
      }
      if let typeLine {
        text += "Type Line: \(typeLine)\n"
      }
      if let oracleText {
        text += "Oracle Text:\n\(oracleText)\n"
      }
      if let power, let toughness {
        text += "Power: \(power)\nToughness: \(toughness)\n"
      }
      if let loyalty {
        text += "Loyalty: \(loyalty)\n"
      }
      
      return text
    }
    
    public var textRepresentation: String {
      if let cardFaces = cardFaces {
        return cardFaces.map { face in
          var lines: [String?] = []
          lines.append([face.printedName ?? face.name, face.manaCost?.uppercased()].compactMap { $0 }.joined(separator: " "))
          lines.append(colorIndicatorText(face.colorIndicator))
          lines.append(face.printedTypeLine ?? face.typeLine)
          lines.append(face.printedText ?? face.oracleText)
          lines.append([face.power, face.toughness].compactMap { $0 }.joined(separator: "/"))
          lines.append(face.loyalty.map { "Loyalty: \($0)" })
          return lines.compactMap { $0?.isEmpty == true ? nil : $0 }.joined(separator: "\n")
        }.joined(separator: "\n---\n")
      } else {
        var lines: [String?] = []
        lines.append([printedName ?? name, manaCost?.uppercased()].compactMap { $0 }.joined(separator: " "))
        lines.append(colorIndicatorText(colorIndicator))
        lines.append(printedTypeLine ?? typeLine)
        lines.append(printedText ?? oracleText)
        lines.append([power, toughness].compactMap { $0 }.joined(separator: "/"))
        lines.append(loyalty.map { "Loyalty: \($0)" })
        return lines.compactMap { $0?.isEmpty == true ? nil : $0 }.joined(separator: "\n")
      }
    }
    
    private func colorIndicatorText(_ colorIndicator: [String]?) -> String? {
      guard var colorIndicator = colorIndicator else {
        return nil
      }
      let colors = ["W": "White", "U": "Blue", "B": "Black", "R": "Red", "G": "Green"]
      colorIndicator = colorIndicator.compactMap { colors[$0.uppercased()] }
      let prefix = "Color Indicator: "
      switch colorIndicator.count {
      case 0: return nil
      case 1: return prefix + "\(colorIndicator[0])"
      case 2: return prefix + "\(colorIndicator[0]) and \(colorIndicator[1])"
      default:
        let last = colorIndicator.removeLast()
        return prefix + colorIndicator.joined(separator: ", ") + ", and " + last
      }
    }
  }
  
  fileprivate static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()
  
  fileprivate static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .formatted(dateFormatter)
    return decoder
  }()
  
  /// Retreives JSON data from URL and parses it with JSON decoder.
  static func parseResource<ResultType: Decodable>(url: URL, body: Data? = nil, method: String? = "GET", dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = nil, urlSession: URLSession = .shared) async throws -> ResultType {
    do {
      let content: Data
      let response: URLResponse
      
      if let body = body, let method = method {
        var request = URLRequest(url: url)
        request.httpBody = body
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        (content, response) = try await urlSession.data(from: request)
      } else {
        let request = URLRequest(url: url)
        (content, response) = try await urlSession.data(from: request)
      }
      
      let httpStatus = (response as! HTTPURLResponse).statusCode
      
      if !(200..<300).contains(httpStatus), let decoded:ScryfallError = try? decoder.decode(ScryfallError.self, from: content) {
        throw decoded
      }
      
      decoder.dateDecodingStrategy = dateDecodingStrategy ?? .formatted(dateFormatter)
      
      let decoded:ResultType = try decoder.decode(ResultType.self, from: content)
      return decoded
    } catch {
      print(error)
      throw error
    }
  }
  
  // gets a Card by using the Scryfall ID
  public static func getCard(id: String) async throws -> Card {
    return try await parseResource(url: URL(string:"\(scryfall)cards/\(id)")!)
  }
  
  // gets a Card by using the code and id number
  public static func getCard(code: String, number: String, retry: Bool = true) async throws -> Card {
    var number = number
    while number.hasPrefix("0") {
      number = String(number.dropFirst(1))
    }
    
    let suffix = code.lowercased() + "/" + (retry ? number : number.lowercased())
    guard let encodedSuffix = suffix.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      throw SwiftfallError.badURL
    }
    let call = URL(string: "\(scryfall)cards/" + encodedSuffix)!
    
    do {
      return try await parseResource(url: call)
    } catch {
      if retry {
        return try await getCard(code: code, number: number, retry: false)
      } else {
        throw error
      }
    }
  }
  
  public static func getCard(identifier: MTGCardIdentifier) async throws -> Card {
    switch identifier {
    case .id(let id):
      return try await getCard(id: id.uuidString)
    case .mtgoID(let id):
      return try await getCard(mtgoID: id)
    case .multiverseID(let id):
      return try await getCard(multiverseID: id)
    case .oracleID(let id):
      guard let card = try await getAllCards(query: "oracleid:\(id.uuidString)").first else {
        throw SwiftfallError.cardNotFound
      }
      return card
    case .illustrationID(let id):
      guard let card = try await getAllCards(query: "illustrationid:\(id.uuidString)").first else {
        throw SwiftfallError.cardNotFound
      }
      return card
    case .name(let name):
      return try await getCard(exact: name)
    case .nameSet(let name, let set):
      return try await getCard(name: name, set: set.lowercased())
    case .collectorNumberSet(let collectorNumber, let set, _):
      return try await getCard(code: set.lowercased(), number: collectorNumber)
    case .idName(let id, let name):
      return try await getCard(id: id.uuidString)
    }
  }
  
  enum SwiftfallError: Error {
    case badURL
    case cardNotFound
  }
  
  public static func getCard(name: String, set: String, fuzzy: Bool = false) async throws -> Card {
    var components = URLComponents(string: "https://api.scryfall.com/cards/named")!
    components.queryItems = [
      URLQueryItem(name: fuzzy ? "fuzzy" : "exact", value: name),
      URLQueryItem(name: "set", value: set)
    ]
    
    guard let url = components.url else { throw SwiftfallError.badURL }
    
    return try await parseResource(url: url)
  }
  
  public static func getCard(multiverseID: Int) async throws -> Card {
    return try await parseResource(url: URL(string: "https://api.scryfall.com/cards/multiverse\(multiverseID)")!)
  }
  
  // gets a Card by using the arena code
  public static func getCard(arena: Int) async throws -> Card {
    return try await parseResource(url: URL(string: "\(scryfall)cards/arena/\(arena)")!)
  }
  
  public static func getCard(mtgoID: Int) async throws -> Card {
    return try await parseResource(url: URL(string: "\(scryfall)cards/mtgo/\(mtgoID)")!)
  }
  
  // fuzzy
  public static func getCard(fuzzy: String) async throws -> Card {
    let encodeFuzz = fuzzy.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    let call = URL(string: "\(scryfall)cards/named?fuzzy=\(encodeFuzz)")!
    
    return try await parseResource(url: call)
  }
  
  
  // exact
  public static func getCard(exact: String) async throws -> Card {
    
    let encoded = exact.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      .replacingOccurrences(of: "&", with: "%26")
    let call = URL(string: "\(scryfall)cards/named?exact=\(encoded)")!
    
    return try await parseResource(url: call)
  }
  
  // fuzzy
  public static func getRandomCard(query: String? = nil) async throws -> Card {
    
    var components = URLComponents(string: "\(scryfall)cards/random")!
    if let query {
      components.queryItems = [
        URLQueryItem(name: "q", value: query)
      ]
    }
    
    return try await parseResource(url: components.url!)
  }
  
  // get a catalog
  public static func getCatalog(catalog: Catalog.CatalogType) async throws -> Catalog {
    let encodeCatalog = catalog.rawValue.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
    let call = URL(string: "\(scryfall)catalog/\(encodeCatalog)")!
    
    return try await parseResource(url: call)
  }
  
  // set
  public static func getSet(code: String) async throws -> ScryfallSet {
    let encodeExactly = code.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
    return try await parseResource(url: URL(string: "\(scryfall)sets/\(encodeExactly)")!)
  }
  
  
  public static func getSetList() async throws -> SetList {
    return try await parseResource(url: URL(string: "\(scryfall)sets/")!)
  }
  
  
  public static func getCardList() async throws -> CardList {
    return try await parseResource(url: URL(string: "\(scryfall)cards/")!)
  }
  
  public enum SearchOrder: String, CaseIterable, Identifiable, Codable {
    case name, set, released, rarity, color, usd, tix, eur, cmc, power, toughness, artist, edhrec, review, spoiled
    
    public static var allCases: [Swiftfall.SearchOrder] {
      [
        .name, .set, .released, .rarity, .color, .usd, .tix, .eur, .cmc, .power, .toughness, .edhrec, .artist, .review
      ]
    }
    
    public var id: String {
      rawValue
    }
    
    public var name: String {
      switch self {
      case .name:
        return "Name"
      case .set:
        return "Set/Number"
      case .released:
        return "Release Date"
      case .rarity:
        return "Rarity"
      case .color:
        return "Color"
      case .usd:
        return "Price: USD"
      case .tix:
        return "Price: TIX"
      case .eur:
        return "Price: EUR"
      case .cmc:
        return "Mana Value"
      case .power:
        return "Power"
      case .toughness:
        return "Toughness"
      case .edhrec:
        return "EDHREC Rank"
      case .artist:
        return "Artist Name"
      case .review:
        return "Set Review"
      case .spoiled:
        return "Spoiler Date"
      }
    }
  }
  
  public enum SearchOrderDirection: String, CaseIterable, Identifiable, Codable {
    case auto, ascending = "asc", descending = "desc"
    
    public var name: String {
      switch self {
      case .auto: return "Auto"
      case .ascending: return "Ascending"
      case .descending: return "Descending"
      }
    }
    
    public var id: String {
      return rawValue
    }
    
    func autoDirection(for order: SearchOrder) -> SearchOrderDirection {
      switch order {
      case .name:
        return .ascending
      case .released:
        return .descending
      case .set:
        return .ascending
      case .usd:
        return .descending
      case .tix:
        return .descending
      case .eur:
        return .descending
      case .cmc:
        return .descending
      case .power:
        return .ascending
      case .toughness:
        return .ascending
      case .artist:
        return .ascending
      case .rarity:
        return .descending
      case .edhrec:
        return .ascending
        //        case .quantityOwned:
        //          return .descending
      case .review:
        return .ascending
      case .color:
        return .ascending
      case .spoiled:
        return .descending
      }
    }
  }
  
  /// Loads ALL PAGES and doesn't return until each page has been loaded.
  public static func getAllCards(query: String, unique: Unique? = nil, includeExtras: Bool = false, order: SearchOrder? = nil, dir: SearchOrderDirection? = nil, respectPreferences: Bool = false) async throws -> [Card] {
    let url = self.url(forQuery: query, unique: unique, includeExtras: includeExtras, order: order, dir: dir, page: 1)
    return try await getAllCards(searchURL: url)
  }
  
  /// Loads ALL PAGES and doesn't return until each page has been loaded.
  public static func getAllCards(searchURL: URL) async throws -> [Card] {
    func getAllPages(searchURL: URL) async -> [CardList?] {
      do {
        let cardlist: CardList = try await parseResource(url: searchURL)
        
        var cardListArray: [CardList?] = []
        if cardlist.hasMore, let nextPage = cardlist.nextPage {
          await cardListArray += getAllPages(searchURL: nextPage)
        }
        cardListArray.append(cardlist)
        return cardListArray
      } catch {
        return []
      }
    }
    
    let cardlist = await getAllPages(searchURL: searchURL).compactMap { $0?.data }.joined()
    return Array(cardlist)
  }
  
  public enum Unique: String, CaseIterable, Identifiable, Codable {
    case cards
    case prints
    case art
    
    public var id: String {
      rawValue
    }
    
    var name: String {
      switch self {
      case .cards: return "Cards"
      case .prints: return "All prints"
      case .art: return "Unique art"
      }
    }
  }
  
  
  public static func url(forQuery query: String, unique: Unique? = nil, includeExtras: Bool = false, order: SearchOrder? = nil, dir: SearchOrderDirection? = nil, page: Int = 1) -> URL {
    //    let token = ScryfallTokenizer().scryfallToken(for: query, ignoreUnrecognized: true)
    
    let orderQuery: String = {
      if let order = order {
        return "order=\(order.rawValue)&"
      } else {
        return ""
      }
    }()
    let orderDirQuery: String = {
      if let dir = dir {
        return "dir=\(dir.rawValue)&"
      } else {
        return ""
      }
    }()
    
    //    var query = query
    //    if respectPreferences && Preferences.shared.hideFunnyCards {
    //      query = "(\(query)) not:funny"
    //    }
#if COLLECTION
    var inProgressQuery = inProgressQuery
    let regex = #"-?owned(?:>=|<=|>|<|=|:)\d+"#
    let matches = inProgressQuery.matches(forRegex: regex)
    for match in matches.reversed() {
      inProgressQuery.removeSubrange(match.fullMatch.range)
    }
    inProgressQuery = inProgressQuery.replacingOccurrences(of: "-in:collection", with: "")
    inProgressQuery = inProgressQuery.replacingOccurrences(of: "in:collection", with: "")
#endif
    
    var call = "\(scryfall)cards/search?\(orderQuery)\(orderDirQuery)q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    
    call += "&page=\(page)"
    
    if let unique = unique {
      call += "&unique=\(unique.rawValue)"
    }
    
    if includeExtras {
      call += "&include_extras=true"
    }
    
    return URL(string: call)!
  }
  
  /// Loads a SINGLE PAGE of cards from a search.
  public static func getCards(query: String, unique: Unique? = nil, includeExtras: Bool = false, order: SearchOrder? = nil, dir: SearchOrderDirection? = nil, page: Int = 1) async throws -> CardList {
    
    let url = self.url(forQuery: query, unique: unique, includeExtras: includeExtras, order: order, dir: dir, page: page)
    
    let cardlist: CardList = try await parseResource(url: url)
    //            var cardListArray: [CardList?] = []
    //            if loadAllPages {
    //                if cardlist.hasMore, let nextPage = cardlist.nextPage {
    //                    cardListArray += await self.getCards(searchURI: nextPage)
    //                }
    //                cardListArray.append(cardlist)
    //            }
    
    return cardlist
  }
  
  public static func getCards(searchURL: URL) async throws -> CardList {
    return try await parseResource(url: searchURL)
  }
  
  public static func getCardList(page:Int) async throws -> CardList {
    return try await parseResource(url: URL(string: "\(scryfall)cards?page=\(page)")!)
  }
  
  
  public static func getRulingList(code:String,number:String) async throws -> RulingList {
    return try await parseResource(url: URL(string: "\(scryfall)cards/\(code)/\(number)/rulings")!)
    
  }
  
  public static func getSymbols() async throws -> SymbolList {
    return try await parseResource(url: URL(string: "\(scryfall)symbology")!)
  }
  
  // give a search term and return a catalog of similar cards
  public static func autocomplete(_ string: String) async throws -> Catalog {
    return try await parseResource(url: URL(string: "\(scryfall)cards/autocomplete?q=\(string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)")!)
  }
}

extension Swiftfall {
  static func getCollection(identifiers: [MTGCardIdentifier]) async throws -> CardCollectionList {    
    let identifiers: [MTGCardIdentifier] = identifiers.map {
      if case .collectorNumberSet(let collectorNumber, let set, _) = $0 {
        return .collectorNumberSet(collectorNumber: collectorNumber, set: set, name: nil)
      } else {
        return $0
      }
    }
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.keyEncodingStrategy = .convertToSnakeCase
    
    let data = try encoder.encode(["identifiers": identifiers])
    let string = String(data: data, encoding: .utf8)!
    
    let call = URL(string: "\(scryfall)cards/collection")!
    
    return try await parseResource(url: call, body: string.data(using: .utf8), method: "POST")
  }
  
}

extension URLSession {
  func data(from request: URLRequest) async throws -> (Data, URLResponse) {
    return try await withCheckedThrowingContinuation { continuation in
      dataTask(with: request) { data, response, error in
        continuation.resume(with: Swift.Result {
          if let error = error {
            throw error
          } else if let data = data, let response = response {
            return (data, response)
          } else {
            fatalError()
          }
        })
      }.resume()
    }
  }
}

extension String {
  func removingTextInParentheses() -> String {
    var string = self
    let matches = string.matches(forRegex: "\\(([^)]+)\\)")
    for match in matches.reversed() {
      string.removeSubrange(match.fullMatch.range)
    }
    return string
  }
}
