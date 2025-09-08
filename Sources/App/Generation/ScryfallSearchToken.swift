//
//  ScryfallSearchToken.swift
//  Spellbook
//
//  Created by Josh Birnholz on 2/10/21.
//  Copyright © 2021 iowncode. All rights reserved.
//

import Foundation

func colors(in string: String) -> OrderedSet<ScryfallSearchToken.Color> {
  let colors = OrderedSet(string.compactMap { ScryfallSearchToken.Color.init(rawValue: String($0.uppercased())) })
  guard colors.count == string.count else { return [] }
  return colors
}

indirect public enum ScryfallSearchToken: Hashable, Equatable, Codable {
  public enum Quantifier: String, CaseIterable, Equatable, Codable, Sendable {
    /// =
    case exactly = "="
    /// >=
    case including = ">="
    /// <=
    case atMost = "<="
    /// >
    case greaterThan = ">"
    /// <
    case lessThan = "<"
    
    case not = "!="
    
    init?(value: String, valueForColon: Quantifier = .exactly) {
      if let value = Quantifier(rawValue: value) {
        self = value
      } else if let value = Quantifier.allCases.first(where: { $0.numericHumanReadable == value }) {
        self = value
      } else if value == ":" {
        self = valueForColon
      } else {
        return nil
      }
    }
    
    func performOn<T: Comparable>(_ lhs: T, _ rhs: T) -> Bool {
      switch self {
      case .exactly:
        return lhs == rhs
      case .including:
        return lhs >= rhs
      case .atMost:
        return lhs <= rhs
      case .greaterThan:
        return lhs > rhs
      case .lessThan:
        return lhs < rhs
      case .not:
        return lhs != rhs
      }
    }
    
    var opposite: Quantifier? {
      switch self {
      case .exactly:
        return .not
      case .including:
        return .lessThan
      case .atMost:
        return .greaterThan
      case .greaterThan:
        return .atMost
      case .lessThan:
        return .including
      case .not:
        return .exactly
      }
    }
    
    var humanReadable: String {
      switch self {
      case .exactly: return "equal to"
      case .including: return "greater than or equal to"
      case .atMost: return "less than or equal to"
      case .greaterThan: return "greater than"
      case .lessThan: return "less than"
      case .not: return "not equal to"
      }
    }
    
    var numericHumanReadable: String {
      switch self {
      case .including: return "≥"
      case .atMost: return "≤"
      case .not: return "≠"
      default: return rawValue
      }
    }
    
    var qualityHumanReadable: String {
      switch self {
      case .including: return "≥"
      case .atMost: return "≤"
      default: return "is"
      }
    }
    
    var colorHumanReadable: String {
      switch self {
      case .exactly: return "exactly"
      case .including: return "including"
      case .atMost: return "at most"
      case .greaterThan: return "greater than"
      case .lessThan: return "less than"
      case .not: return "not"
      }
    }
    
    static let colorCases: [Quantifier] = [.exactly, .including, .atMost]
    
    init?(colorHumanReadable: String) {
      switch colorHumanReadable {
      case "exactly": self = .exactly
      case "including": self = .including
      case "at most": self = .atMost
      case "greater than": self = .greaterThan
      case "less than": self = .lessThan
      case "not": self = .not
      default: return nil
      }
    }
  }
  
  public enum Color: String, CaseIterable, Codable {
    case w = "W"
    case u = "U"
    case b = "B"
    case r = "R"
    case g = "G"
    case c = "C"
//    case m = "M"
    
    var humanReadable: String {
      switch self {
      case .w: return "white"
      case .u: return "blue"
      case .b: return "black"
      case .r: return "red"
      case .g: return "green"
      case .c: return "colorless"
//      case .m: return "multicolored"
      }
    }
    
    var sortOrder: Int {
      switch self {
      case .w: return 0
      case .u: return 1
      case .b: return 2
      case .r: return 3
      case .g: return 4
      case .c: return 5
//      case .m: return 6
      }
    }
  }
  
  public enum Stat: String, CaseIterable, Equatable, Codable {
    case cmc = "mv"
    case power = "power"
    case toughness = "toughness"
    case loyalty = "loyalty"
    
    var humanReadable: String {
      switch self {
      case .cmc: return "mana value"
      default: return rawValue
      }
    }
    
    #if OFFLINE_BACKUP
    var predicatePropertyKeyPathString: String {
      switch self {
      case .cmc:
        return #keyPath(Card.convertedManaCost)
      case .power:
        return #keyPath(Card.power)
      case .toughness:
        return #keyPath(Card.toughness)
      case .loyalty:
        return #keyPath(Card.loyalty)
      }
    }
    
    var predicateNumericPropertyKeyPathString: String {
      switch self {
      case .cmc:
        return #keyPath(Card.convertedManaCost)
      case .power:
        return #keyPath(Card.numericPower)
      case .toughness:
        return #keyPath(Card.numericToughness)
      case .loyalty:
        return #keyPath(Card.numericLoyalty)
      }
    }
    
    var predicateNumericPropertyKeyPath: ReferenceWritableKeyPath<Card, Double> {
      switch self {
      case .cmc:
        return \Card.convertedManaCost
      case .power:
        return \Card.numericPower
      case .toughness:
        return \Card.numericToughness
      case .loyalty:
        return \Card.numericLoyalty
      }
    }
    
    var predicateCardFaceNumericPropertyKeyPath: ReferenceWritableKeyPath<CardFace, Double> {
      switch self {
      case .cmc:
        fatalError("This should not be called.")
      case .power:
        return \CardFace.numericPower
      case .toughness:
        return \CardFace.numericToughness
      case .loyalty:
        return \CardFace.numericLoyalty
      }
    }
    #endif
  }
  
  public enum Language: Hashable, Equatable, Codable {
    case any
    case language(Card.Language)
    
    var name: String {
      switch self {
      case .any: return "Any"
      case .language(let lang): return lang.name
      }
    }
  }
  
  public enum Legality: String, CaseIterable, Equatable, Codable {
    case legal, restricted, banned
  }
  
  public enum Rarity: String, CaseIterable, Comparable, Codable, Equatable {
    public static func < (lhs: ScryfallSearchToken.Rarity, rhs: ScryfallSearchToken.Rarity) -> Bool {
      return lhs.value < rhs.value
    }
    
    case common, uncommon, rare, mythic, special, bonus
    
    var humanReadable: String {
      if case .mythic = self {
        return "mythic rare"
      } else {
        return rawValue
      }
    }
    
    var value: Int {
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
  
  public enum BorderColor: String, CaseIterable, Codable {
    case black, white, silver, gold, borderless
  }
  
  public enum ColorChoice: String, CaseIterable, Codable {
    case color
    case identity
    
    var humanReadable: String {
      switch self {
      case .color: return "colors"
      case .identity: return "color identity"
      }
    }
    
    #if OFFLINE_BACKUP
    var predicatePropertyKeyPath: String {
      switch self {
      case .color: return #keyPath(Card.colors)
      case .identity: return #keyPath(Card.colorIdentity)
      }
    }
    #endif
  }
  
  enum Format: String, CaseIterable, Codable {
    case standard, future, historic, timeless, gladiator, pioneer, explorer, modern, legacy, pauper, vintage, penny, commander, oathbreaker, brawl, historicbrawl, alchemy, paupercommander, duel, oldschool, premodern, predh
    
    var name: String {
      switch self {
      case .standard:
        return "Standard"
      case .future:
        return "Future Standard"
      case .historic:
        return "Historic"
      case .gladiator:
        return "Gladiator"
      case .pioneer:
        return "Pioneer"
      case .explorer:
        return "Explorer"
      case .modern:
        return "Modern"
      case .legacy:
        return "Legacy"
      case .pauper:
        return "Pauper"
      case .vintage:
        return "Vintage"
      case .penny:
        return "Penny Dreadful"
      case .commander:
        return "Commander"
      case .brawl:
        return "Standard Brawl"
      case .historicbrawl:
        return "Brawl"
      case .alchemy:
        return "Alchemy"
      case .paupercommander:
        return "Pauper Commander"
      case .duel:
        return "Duel Commander"
      case .oldschool:
        return "Old School 93/94"
      case .premodern:
        return "Premodern"
      case .timeless:
        return "Timeless"
      case .oathbreaker:
        return "Oathbreaker"
      case .predh:
        return "PreDH"
      }
    }
  }
  
  enum Criterion: String, CaseIterable, Codable {
    case adventure, arenaid, artist, artistmisprint, augmentation, back, booster, boosterfun, brawlcommander, buyabox, ci, colorshifted, commander, companion, manland, datestamped, digital, doublesided, etb, etched, englishart, extra, firstprint, flavorname, flavor, flip, foil, fbb, fwb, frenchvanilla, fullart, funny, future, gameday, hires, historic, splitmana, intropack, invitational, leveler, localizedname, mtgoid, masterpiece, meld, modal, mdfc, modern, multiverse, new, nonfoil, old, oversized, paperart, party, permanent, phyrexian, planeswalkerdeck, prerelease, printedtext, promo, promostamped, release, reprint, reserved, spell, spikey, split, starterdeck, story, tcgplayer, textless, timeshifted, token, tombstone, transform, onlyprint, vanilla, variation, watermark, alchemy, bear, stamp, outlaw, serialized, gamechanger, beginnerbox, startercollection, universesbeyond, normal, finalfantasy
    
    case cycleland, bounceland, checkland, canopyland, dual, fastland, fetchland, filterland, gainland, painland, scryland, shadowland, shockland, storageland, triland, battleland, bondland, triome, slowland, snarl, owned
    
    var title: String {
      switch self {
      case .alchemy:
        return "Alchemy"
      case .adventure:
        return "Adventure"
      case .arenaid:
        return "Arena ID"
      case .artistmisprint:
        return "Artist Misprint"
      case .augmentation:
        return "Augment"
      case .back:
        return "Back"
      case .booster:
        return "Booster"
      case .brawlcommander:
        return "Brawl Commander"
      case .buyabox:
        return "Buy-a-Box"
      case .ci:
        return "Color Indicator"
      case .colorshifted:
        return "Colorshifted"
      case .commander:
        return "Commander"
      case .companion:
        return "Companion"
      case .manland:
        return "Creature Land"
      case .datestamped:
        return "Datestamped"
      case .digital:
        return "Digital"
      case .doublesided:
        return "Double Sided"
      case .etb:
        return "E T B"
      case .englishart:
        return "English Art"
      case .extra:
        return "Extra"
      case .firstprint:
        return "First Printing"
      case .flavorname:
        return "Flavor Name"
      case .flavor:
        return "Flavor Text"
      case .flip:
        return "Flip"
      case .foil:
        return "Foil"
      case .fbb:
        return "Foreign Black Border"
      case .fwb:
        return "Foreign White Border"
      case .frenchvanilla:
        return "French Vanilla"
      case .fullart:
        return "Full Art"
      case .funny:
        return "Funny"
      case .future:
        return "Future"
      case .gameday:
        return "Game Day"
      case .hires:
        return "Highres"
      case .historic:
        return "Historic"
      case .splitmana:
        return "Hybrid Mana"
      case .intropack:
        return "Intro Pack"
      case .invitational:
        return "Invitational Card"
      case .leveler:
        return "Leveler"
      case .localizedname:
        return "Localized Name"
      case .mtgoid:
        return "MTGO ID"
      case .masterpiece:
        return "Masterpiece"
      case .meld:
        return "Meld"
      case .modal:
        return "Modal"
      case .mdfc:
        return "Modal Double Faced"
      case .modern:
        return "Modern"
      case .multiverse:
        return "Multiverse"
      case .new:
        return "New"
      case .nonfoil:
        return "Nonfoil"
      case .old:
        return "Old"
      case .oversized:
        return "Oversized"
      case .paperart:
        return "Paper Art"
      case .party:
        return "Party"
      case .permanent:
        return "Permanent"
      case .phyrexian:
        return "Phyrexian Mana"
      case .planeswalkerdeck:
        return "Planeswalker Deck"
      case .prerelease:
        return "Prerelease Promo"
      case .printedtext:
        return "Printed Text"
      case .promo:
        return "Promo"
      case .promostamped:
        return "Promo Stamped"
      case .release:
        return "Release Promo"
      case .reprint:
        return "Reprint"
      case .reserved:
        return "Reserved List"
      case .spell:
        return "Spell"
      case .spikey:
        return "Spikey"
      case .split:
        return "Split Card"
      case .starterdeck:
        return "Starter Deck"
      case .story:
        return "Story Spotlight"
      case .tcgplayer:
        return "TCGplayer ID"
      case .textless:
        return "Textless"
      case .timeshifted:
        return "Timeshifted"
      case .token:
        return "Token"
      case .tombstone:
        return "Tombstone"
      case .transform:
        return "Transform"
      case .onlyprint:
        return "Unique"
      case .vanilla:
        return "Vanilla"
      case .variation:
        return "Variation"
      case .watermark:
        return "Watermark"
      case .cycleland:
        return "Cycle Land"
      case .bounceland:
        return "Bounce Land"
      case .checkland:
        return "Check Land"
      case .canopyland:
        return "Canopy Land"
      case .dual:
        return "Dual Land"
      case .fastland:
        return "Fast Land"
      case .fetchland:
        return "Fetch Land"
      case .filterland:
        return "Filter Land"
      case .gainland:
        return "Gain Land"
      case .painland:
        return "Pain Land"
      case .scryland:
        return "Scry Land"
      case .shadowland:
        return "Shadow Land"
      case .shockland:
        return "Shock Land"
      case .storageland:
        return "Storage Land"
      case .triland:
        return "Tri Land"
      case .triome:
        return "Triome"
      case .battleland:
        return "Battle Land"
      case .bondland:
        return "Battlebond Land"
      case .boosterfun:
        return "Booster Fun"
      case .etched:
        return "Etched"
      case .slowland:
        return "Slowland"
      case .artist:
        return "Artist"
      case .bear:
        return "Bear"
      case .snarl:
        return "Snarl"
      case .stamp:
        return "Stamp"
      case .owned:
        return "Owned"
      case .outlaw:
        return "Outlaw"
      case .serialized:
        return "Serialized"
      case .gamechanger:
        return "Game Changer"
      case .beginnerbox:
        return "Beginner Box"
      case .startercollection:
        return "Starter Collection"
      case .universesbeyond:
        return "Universes Beyond"
      case .normal:
        return "Normal"
      case .finalfantasy:
        return "Final Fantasy"
      }
    }
    
    init?(rawValue: String) {
      let rawValue = rawValue.lowercased()
      if let value = Self.allCases.first(where: {
        $0.rawValue == rawValue || $0.alternateNames.contains(rawValue)
      }) {
        self = value
      } else {
        return nil
      }
    }
    
    var alternateNames: [String] {
      switch self {
      case .phyrexian:
        return ["phyrexia"]
      case .hires:
        return ["highres"]
      case .triome:
        return ["tricycleland"]
      case .cycleland:
        return ["bikeland", "bicycleland"]
      case .bounceland:
        return ["karoo"]
      case .canopyland:
        return ["canland"]
      case .battleland:
        return ["tangoland"]
      case .bondland:
        return ["crowdland", "battlebondland"]
      case .etched:
        return ["etch"]
      default:
        return []
      }
    }
    
    var humanReadable: String? {
      switch self {
      case .adventure: "the cards have Adventures"
      case .arenaid: "the cards have an Arena ID"
      case .artist: "the cards have artists"
      case .artistmisprint: "the cards are cards with a misprinted artist"
      case .augmentation: "the cards are augment pieces"
      case .back: "the cards have non-standard backs"
      case .bear: "the cards are 2/2/2 bears"
      case .booster: "the cards are cards that are included in the standard contents of draft boosters"
      case .boosterfun: "the cards are special versions that are part of \"Project Booster Fun\""
      case .brawlcommander: "the cards can be your Brawl commander"
      case .buyabox: "the cards are Buy-a-Box promos"
      case .ci: "the cards have color indicators"
      case .colorshifted: "the cards have a colorshifted frame"
      case .commander: "the cards can be your commander"
      case .companion: "the cards are Companions"
      case .manland: "the cards are lands that become creatures"
      case .datestamped: "the cards are cards with a date stamp"
      case .digital: "the cards are digital prints"
      case .doublesided: "the cards are double-sided"
      case .etb: "the cards have an ETB effect"
      case .etched: "the cards are available in etched foil"
      case .englishart: "the cards have art that has been printed in English"
      case .extra: "the cards are “extras”"
      case .firstprint: "the card is the first printing"
      case .flavorname: "the cards have flavor names"
      case .flavor: "the cards have flavor text"
      case .flip: "the cards flip"
      case .foil: "the cards are available in foil"
      case .fbb: "the cards are cards printed in black border in non-English editions of white-border sets"
      case .fwb: "the cards are “foreign white border” prints"
      case .frenchvanilla: "the cards are French vanilla"
      case .fullart: "the cards are cards with full extended art"
      case .funny: "the cards are funny"
      case .future: "the cards have the future frame"
      case .gameday: "the cards are Game Day promos"
      case .hires: "the cards have hi-res scans"
      case .historic: "the cards are historic"
      case .splitmana: "the cards have hybrid mana"
      case .intropack: "the cards are exclusive Intro Pack cards"
      case .invitational: "the cards are Invitational cards"
      case .leveler: "the cards have Level Up"
      case .localizedname: "the cards have localized names"
      case .mtgoid: "the cards have a MTGO ID (CatID)"
      case .masterpiece: "the cards are masterpieces"
      case .meld: "the cards meld"
      case .modal: "the cards have modal effects"
      case .mdfc: "the cards are modal DFCs"
      case .modern: "the cards have the 2003 frame"
      case .multiverse: "the cards have a Multiverse ID"
      case .new: "the cards have a new frame"
      case .nonfoil: "the cards are available in nonfoil"
      case .old: "the cards have the ‘93/97 frame"
      case .oversized: "the cards are larger than standard card size"
      case .paperart: "the cards have art that has been printed in paper"
      case .party: "the cards are Clerics, Rogues, Warriors, or Wizards"
      case .permanent: "the cards become permanents"
      case .phyrexian: "the cards have Phyrexian mana"
      case .planeswalkerdeck: "the cards are exclusive Planeswalker Deck cards"
      case .prerelease: "the cards are set prerelease event promos"
      case .printedtext: "the cards have their printed text listed"
      case .promo: "the cards are promotional prints"
      case .promostamped: "the cards are cards with a non-date stamp"
      case .release: "the cards are set release event promos"
      case .reprint: "the cards are reprints"
      case .reserved: "the cards are on the Reserved List"
      case .spell: "the cards are spells"
      case .spikey: "the cards are cards that have ever been banned or restricted"
      case .split: "the cards are split"
      case .starterdeck: "the cards are exclusive to a Starter deck"
      case .story: "the cards are Story Spotlights"
      case .tcgplayer: "the cards have a TCGplayer ID"
      case .textless: "the cards are printed without rules text"
      case .timeshifted: "the cards are timeshifted in Time Spiral"
      case .token: "the cards are tokens"
      case .tombstone: "the cards have the Odyssey tombstone mark"
      case .transform: "the cards transform"
      case .onlyprint: "the card has been printed exactly once"
      case .vanilla: "the cards are vanilla"
      case .variation: "the cards are variations of standard printings"
      case .watermark: "the cards have watermarks"
      case .alchemy: "the set type is alchemy"
      case .cycleland: "the cards are cycling dual lands"
      case .bounceland: "the cards are land-bouncing duals"
      case .checkland: "the cards are dual lands that check for other types"
      case .canopyland: "the cards are dual lands that cantrip"
      case .dual: "the cards are dual lands"
      case .fastland: "the cards are duals lands that are 'fast'"
      case .fetchland: "the cards are dual lands that fetches lands from the library"
      case .filterland: "the cards are dual lands that filters mana into other colors"
      case .gainland: "the cards are dual lands from the cycle that gains 1 life"
      case .painland: "the cards are dual lands that damage you when you get colored mana"
      case .scryland: "the cards are dual lands that scry when they enter the battlefield"
      case .shadowland: "the cards are dual lands from the land-revealing SOI cycle"
      case .shockland: "the cards are dual lands that deal 2 damage to you"
      case .storageland: "the cards are lands that allow you to store up mana for later use"
      case .triland: "the cards are lands that produce three colors of mana"
      case .triome: "the cards are tricycleland"
      case .battleland: "the cards are dual lands from the 'takes-two-to-tango' cycle"
      case .bondland: "the cards are dual lands that require two or more opponents"
      case .slowland: "the cards are dual lands that check for two other lands"
      case .snarl: "the cards are Snarl duals"
      case .stamp: "the cards have a security stamp"
      case .owned: "the cards are in your collection"
      case .outlaw: "the cards are Assassins, Mercenaries, Pirates, Rogues, or Warlocks"
      case .serialized: "the cards are marked with serial numbers"
      case .gamechanger: "the cards are on the Commander Game Changer list"
      case .beginnerbox: "the cards are part of a beginniner box"
      case .startercollection: "the cards are part of a starter collection"
      case .universesbeyond: "the cards are part of a Universes Beyond edition"
      case .normal: "the cards are printed with standard frames and effects"
      case .finalfantasy: "the cards are from Final Fantasy"
      }
    }
    
    var negatedHumanReadable: String? {
      switch self {
      case .back: return "the cards have standard backs"
      case .englishart: return "the cards have art that has not been printed in English"
      case .firstprint: return "the cards aren’t the first printing"
      case .onlyprint: return "the card has been printed more than once"
//      case .meld: return "the cards don’t meld"
//      case .permanent: return "the cards don’t become permanents"
//      case .printedtext: return "the cards don't have their printed text listed"
//      case .split: return "the cards don’t split"
      default:
        if var humanReadable = humanReadable {
          if let range = humanReadable.range(of: "the cards have") {
            humanReadable.replaceSubrange(range, with: "the cards don’t have")
            return humanReadable
          } else if let range = humanReadable.range(of: "the cards can") {
            humanReadable.replaceSubrange(range, with: "the cards can’t")
            return humanReadable
          } else if let range = humanReadable.range(of: "the cards are") {
            humanReadable.replaceSubrange(range, with: "the cards aren’t")
            return humanReadable
          } else if let range = humanReadable.range(of: "the cards") {
            humanReadable.replaceSubrange(range, with: "the cards don’t")
            return humanReadable
          }
        }
        
        return nil
      }
    }
    
    var humanReadableNegation: String {
      return "not \(title)"
    }
    
    static let options: [Option] = [
      Option("Adventure", value: "adventure", description: "the cards have Adventures"),
      Option("Arena ID", value: "arenaid", description: "the cards have an Arena ID"),
      Option("Art Series", value: "artseries", description: "the cards are Art Series"),
      Option("Artist", value: "artist", description: "have artists"),
      Option("Artist Misprint", value: "artistmisprint", description: "cards with a misprinted artist"),
      Option("Attraction Lights", value: "lights", description: "the cards have attraction lights"),
      Option("Augment", value: "augmentation", description: "the cards are augment pieces"),
      Option("Back", value: "back", description: "the cards have non-standard backs"),
      Option("Bear", value: "bear", description: "the cards are 2/2/2 bears"),
      Option("Booster", value: "booster", description: "cards that are included in the standard contents of draft boosters"),
      Option("Borderless", value: "borderless", description: "the cards are borderless"),
      Option("Brawl Commander", value: "brawlcommander", description: "the cards can be your Brawl commander"),
      Option("Buy-a-Box", value: "buyabox", description: "Buy-a-Box promos"),
      Option("Cardmarket ID", value: "cardmarket", description: "the cards have a Cardmarket ID"),
      Option("Class Layout", value: "class", description: "the cards are Class-type"),
      Option("Color Indicator", value: "ci", description: "the cards have color indicators"),
      Option("Colorshifted", value: "colorshifted", description: "the cards have a colorshifted frame"),
      Option("Commander", value: "commander", description: "the cards can be your commander"),
      Option("Companion", value: "companion", description: "the cards are Companions"),
      Option("Content Warning", value: "contentwarning", description: "the cards have content warnings"),

      Option("Covered", value: "covered", description: "the cards are covered"),
      Option("Creature Land", value: "manland", description: "the cards are lands that become creatures"),
      Option("Datestamped", value: "datestamped", description: "cards with a date stamp"),
      Option("Digital", value: "digital", description: "the cards are digital prints"),
      Option("Double Sided", value: "doublesided", description: "the cards are double-sided"),
      Option("Duel Commander", value: "duelcommander", description: "the cards can be your Duel Commander"),
      Option("E T B", value: "etb", description: "the cards have an ETB effect"),
      Option("English Art", value: "englishart", description: "the cards have art that has been printed in English"),
      Option("Etched", value: "etch", description: "the cards are available in etched foil"),
      Option("Extended Art", value: "extended", description: "the cards are extended art frames"),
      Option("Extra", value: "extra", description: "the cards are Scryfall “extras”"),
      Option("First Printing", value: "firstprint", description: "the card is the first printing"),
      Option("Flavor Name", value: "flavorname", description: "the cards have flavor names"),
      Option("Flavor Text", value: "flavor", description: "the cards have flavor text"),
      Option("Flip", value: "flip", description: "the cards flip"),
      Option("Foil", value: "foil", description: "the cards are available in foil"),
      Option("Foreign Black Border", value: "fbb", description: "Cards printed in black border in non-English editions of white-border sets"),
      Option("Foreign White Border", value: "fwb", description: "the cards are “foreign white border” prints"),
      Option("French Vanilla", value: "frenchvanilla", description: "the cards are French vanilla"),
      Option("Full Art", value: "fullart", description: "cards with full extended art"),
      Option("Funny", value: "funny", description: "the cards are funny"),
      Option("Future", value: "future", description: "the cards have the future frame"),
      Option("Game Day", value: "gameday", description: "Game Day promos"),
      Option("Highres", value: "hires", description: "the cards have hi-res scans"),
      Option("Historic", value: "historic", description: "the cards are historic"),
      Option("Hybrid Mana", value: "splitmana", description: "the cards have hybrid mana"),
      Option("Illustration", value: "illustration", description: "have illustration IDs"),
      Option("Intro Pack", value: "intropack", description: "exclusive Intro Pack cards"),
      Option("Invitational Card", value: "invitational", description: "Invitational cards"),
      Option("Leveler", value: "leveler", description: "the cards have Level Up"),
      Option("Localized Name", value: "localizedname", description: "the cards have localized names"),
      Option("MTGO ID", value: "mtgoid", description: "the cards have a MTGO ID (CatID)"),
      Option("Masterpiece", value: "masterpiece", description: "the cards are masterpieces"),
      Option("Meld", value: "meld", description: "the cards meld"),
      Option("Modal", value: "modal", description: "the cards have modal effects"),
      Option("Modal Double Faced", value: "mdfc", description: "the cards are modal DFCs"),
      Option("Modern", value: "modern", description: "the cards have the 2003 frame"),
      Option("Multiverse ID", value: "multiverse", description: "the cards have a Multiverse ID"),
      Option("New", value: "new", description: "the cards have a new frame"),
      Option("Nonfoil", value: "nonfoil", description: "the cards are available in nonfoil"),
      Option("Oathbreaker", value: "oathbreaker", description: "the cards can be your oathbreaker"),
      Option("Old", value: "old", description: "the cards have the ‘93/97 frame"),
      Option("Outlaw", value: "outlaw", description: "the cards are Assassins, Mercenaries, Pirates, Rogues, or Warlocks"),
      Option("Oversized", value: "oversized", description: "larger than standard card size"),
      Option("Paired Commander", value:"partner", description: "the cards have multi-commander mechanics"),
      Option("Paper Art", value: "paperart", description: "the cards have art that has been printed in paper"),
      Option("Party", value: "party", description: "the cards are Clerics, Rogues, Warriors, or Wizards"),
      Option("Permanent", value: "permanent", description: "the cards become permanents"),
      Option("Phyrexian Mana", value: "phyrexia", description: "the cards have Phyrexian mana"),
      Option("Planar", value: "planar", description: "the cards are planar deck cards"),
      Option("Planeswalker Deck", value: "planeswalkerdeck", description: "exclusive Planeswalker Deck cards"),
      Option("Prerelease Promo", value: "prerelease", description: "set prerelease event promos"),
      Option("Printed Text", value: "printedtext", description: "the cards have their printed text listed"),
      Option("Promo", value: "promo", description: "the cards are promotional prints"),
      Option("Related", value: "related", description: "the cards have related cards"),
      Option("Release Promo", value: "release", description: "set release event promos"),
      Option("Reprint", value: "reprint", description: "the cards are reprints"),
      Option("Reserved List", value: "reserved", description: "on the Reserved List"),
      Option("Reversible", value: "reversible", description: "the cards are reversible cards"),
      Option("Security Stamp", value: "stamp", description: "the cards have a security stamp"),
      Option("Showcase", value: "showcase", description: "the cards are showcases"),
      Option("Spell", value: "spell", description: "the cards are spells"),
      Option("Spellbook", value: "spellbook", description: "the cards have spellbooks"),
      Option("Spikey", value: "spikey", description: "cards that have ever been banned or restricted"),
      Option("Split Card", value: "split", description: "the cards are split"),
      Option("Stamped", value: "stamped", description: "cards with a non-date stamp"),
      Option("Starter Deck", value: "starterdeck", description: "exclusive to a Starter deck"),
      Option("Story Spotlight", value: "story", description: "the cards are Story Spotlights"),
      Option("TCGplayer ID", value: "tcgplayer", description: "the cards have a TCGplayer ID"),
      Option("Textless", value: "textless", description: "printed without rules text"),
      Option("Token", value: "token", description: "the cards are tokens"),
      Option("Tombstone", value: "tombstone", description: "the cards have the Odyssey tombstone mark"),
      Option("Transform", value: "transform", description: "the cards transform"),
      Option("Unique", value: "onlyprint", description: "the card has been printed exactly once"),
      Option("Vanilla", value: "vanilla", description: "the cards are vanilla"),
      Option("Variation", value: "variation", description: "the cards are variations of standard printings"),
      Option("Watermark", value: "watermark", description: "the cards have watermarks"),
      Option("Game Changer", value: "gamechanger", description: "on the Commander Game Changer list"),
      Option("Beginner Box", value: "beginnerbox", description: "part of a beginner box"),
      Option("Starter Collection", value: "startercollection", description: "part of a starter collection"),
      Option("Universes Beyond", value: "universesbeyond", description: "from a Universes Beyond edition"),
      Option("Final Fantasy", value: "finalfantasy", description: "from Final Fantasy")
    ].sorted { $0.title < $1.title }
  }
  
  public enum New: String, CaseIterable, Codable {
    case rarity, art, artist, flavor, frame, language
  }
  
  public enum Frame: String, CaseIterable, Codable {
    case classic1993 = "1993"
    case classic1997 = "1997"
    case modern2003 = "2003"
    case stamp2015 = "2015"
    case future = "future"
    
    // Frame effects
    
    case showcase
    case extendedart
    
    var name: String {
      switch self {
      case .classic1993:
        "‘93 Classic"
      case .classic1997:
        "‘97 Classic"
      case .modern2003:
        "Modern"
      case .stamp2015:
        "2015 Stamp"
      case .future:
        "Future"
      case .showcase:
        "Showcase"
      case .extendedart:
        "Extended Art"
      }
    }
  }
  
  public enum Game: String, CaseIterable, Codable {
    case paper, mtgo, arena
    
    var name: String {
      switch self {
      case .paper: "Paper"
      case .arena: "Arena"
      case .mtgo: "Magic Online"
      }
    }
  }
  
  public enum Prefer: String, CaseIterable, Codable {
    // prefer:oldest, prefer:newest, prefer:usd-low or prefer:usd-high (and the equivalents for tix and eur), or prefer:promo.
    case oldest, newest, promo
    case usdLow = "usd-low", usdHigh = "usd-high"
    case eurLow = "eur-low", eurHigh = "eur-high"
    case tixLow = "tix-low", tixHigh = "tix-high"
  }
  
  case direct(query:String, name:String? = nil, humanReadableDescription: String? = nil)
  case cardName(String, exact: Bool = false)
  case oracleContains(String)
  case type(String)
  case colors(ColorChoice, [Color], Quantifier = .exactly)
  case manaCost(String, Quantifier = .including)
  case stats(Stat, Quantifier, String)
  case price(Currency, Quantifier, String)
  case legal(Legality, String)
  case sets([String])
  case blocks([String])
  case `in`(String)
  case rarity(Rarity, Quantifier = .exactly)
  case keyword(String)
  case criterion(String)
  case year(Quantifier, String)
  case border(BorderColor)
  case artist(String)
  case include(String)
  case flavorText(String)
  case lore(String)
  case unique(String)
  case language(Language?)
  case watermark(String)
  case owned(Int, Quantifier = .including)
  case new(New?)
  case cheapest(Currency)
  case artists(Quantifier = .exactly, String)
  case colorCount(ColorChoice, Int, Quantifier = .exactly)
  case devotion(Quantifier = .including, String)
  case collectorNumber(Quantifier, String)
  case setType(String)
  case cube(String)
  case frame(Frame?)
  case stamp(Swiftfall.Card.SecurityStamp?)
  case game(Game?)
  case prefer(Prefer?)
  case art(String)
  case function(String)
  
  case and(ScryfallSearchToken, ScryfallSearchToken)
  case or(ScryfallSearchToken, ScryfallSearchToken)
  case not(ScryfallSearchToken)
  case parentheses(ScryfallSearchToken)
  
  var allBaseTokens: [ScryfallSearchToken] {
    switch self {
    case .and(let first, let second):
      return first.allBaseTokens + second.allBaseTokens
    case .or(let first, let second):
      return first.allBaseTokens + second.allBaseTokens
    case .not(let token):
      return token.allBaseTokens
    case .parentheses(let token):
      return token.allBaseTokens
    default:
      return [self]
    }
  }
  
  var allBaseTokensWithoutNot: [ScryfallSearchToken] {
    switch self {
    case .and(let first, let second):
      return first.allBaseTokensWithoutNot + second.allBaseTokensWithoutNot
    case .or(let first, let second):
      return first.allBaseTokensWithoutNot + second.allBaseTokensWithoutNot
    case .not(_):
      return [self]
    case .parentheses(let token):
      return token.allBaseTokensWithoutNot
    default:
      return [self]
    }
  }
  
  init?(andMultiple tokens: [ScryfallSearchToken]) {
    guard !tokens.isEmpty else {
      return nil
    }
    guard tokens.count >= 2 else {
      self = tokens[0]
      return
    }
    
    var result: ScryfallSearchToken = .and(tokens[0], tokens[1])
    let tokens = tokens.dropFirst(2)
    
    for token in tokens {
      if case .or = token {
        result = .and(result, .parentheses(token))
      } else {
        result = .and(result, token)
      }
    }
    
    self = result
  }
  
  init?(orMultiple tokens: [ScryfallSearchToken]) {
    guard !tokens.isEmpty else {
      return nil
    }
    guard tokens.count >= 2 else {
      self = tokens[0]
      return
    }
    
    var result: ScryfallSearchToken = .or(tokens[0], tokens[1])
    let tokens = tokens.dropFirst(2)
    
    for token in tokens {
      if case .and = token {
        result = .or(result, .parentheses(token))
      } else {
        result = .or(result, token)
      }
    }
    
    self = result
  }
  
  private func spaceFixed(_ string: String) -> String {
    string.contains(" ") ? "\"\(string)\"" : string
  }
  
  func matches(_ card: MTGCard) -> Bool {
    switch self {
    case .direct(let query, let name, let humanReadableDescription):
      break // Not yet implemented
    case .cardName(let string, let exact):
      let string = string.replacingOccurrences(of: "_", with: " ").lowercased()
      if exact {
        return card.allNames.contains(where: { $0.lowercased() == string })
      } else {
        return card.allNames.contains(where: { $0.lowercased().contains(string) })
      }
    case .oracleContains(let string):
      return card.oracleText?.lowercased().contains(string.lowercased()) == true
    case .type(let string):
      return card.typeLine?.lowercased().contains(string.lowercased()) == true
    case .colors(let colorChoice, let array, let quantifier):
      guard let cardValueArray = colorChoice == .color ? card.colors : card.colorIdentity else { return false }
      let cardValue = Set(cardValueArray)
      let colors = Set(array.compactMap { MTGColor(rawValue: $0.rawValue) })
      switch quantifier {
      case .exactly:
        return colors == cardValue
      case .including: // >=
        return cardValue.isSuperset(of: colors)
      case .atMost: // <=
        return cardValue.isSubset(of: colors)
      case .greaterThan: // >
        return cardValue.isStrictSuperset(of: colors)
      case .lessThan: // <
        return cardValue.isStrictSubset(of: colors)
      case .not:
        return colors != cardValue
      }
    case .manaCost(let string, let quantifier):
      return false // Not yet implemented
    case .stats(let stat, let quantifier, let string):
      guard let doubleValue = Double(string) else { return false }
      switch stat {
      case .cmc:
        guard let cardValue = card.convertedManaCost.flatMap(Double.init) else { return false }
        return quantifier.performOn(cardValue, doubleValue)
      case .power:
        guard let cardValue = card.power.flatMap(Double.init) else { return false }
        return quantifier.performOn(cardValue, doubleValue)
      case .toughness:
        guard let cardValue = card.toughness.flatMap(Double.init) else { return false }
        return quantifier.performOn(cardValue, doubleValue)
      case .loyalty:
        guard let cardValue = card.loyalty.flatMap(Double.init) else { return false }
        return quantifier.performOn(cardValue, doubleValue)
      }
    case .price(let currency, let quantifier, let string):
      return false
    case .legal(let legality, let string):
      return false
    case .sets(let array):
      return array.contains(where: { $0.lowercased() == card.set.lowercased() })
    case .blocks(let array):
      return false
    case .in(let string):
      return card.set.lowercased() == string.lowercased()
    case .rarity(let rarity, let quantifier):
      guard let rarity = MTGCard.Rarity(rawValue: rarity.rawValue) else { return false }
      
      return quantifier.performOn(card.rarity, rarity)
    case .keyword(let string):
      return card.keywords?.contains(where: { $0.lowercased() == string.lowercased() }) == true
    case .criterion(let string):
      return false
    case .year(let quantifier, let string):
      guard let releaseDate = card.releaseDate, let intValue = Int(string) else { return false }
      let component = Calendar.current.component(.year, from: releaseDate)
      return quantifier.performOn(component, intValue)
    case .border(let borderColor):
      return card.borderColor?.rawValue.lowercased() == borderColor.rawValue.lowercased()
    case .artist(let string):
      return card.artist?.lowercased().contains(string.lowercased()) == true
    case .include(let string):
      return false
    case .flavorText(let string):
      return card.flavorText?.lowercased().contains(string.lowercased()) == true
    case .lore(let string):
      return card.name?.lowercased().contains(string) == true || card.flavorName?.lowercased().contains(string) == true || card.flavorText?.lowercased().contains(string) == true || card.cardFaces?.contains(where: { face in
        face.name?.lowercased().contains(string) == true || face.flavorName?.lowercased().contains(string) == true || face.flavorText?.lowercased().contains(string) == true
      }) == true
    case .unique(let string):
      return false
    case .language(let language):
      guard let language else { return false }
      switch language {
      case .any:
        return true
      case .language(let language):
        return card.language.rawValue.lowercased() == language.rawValue.lowercased()
      }
    case .watermark(let string):
      return card.watermark?.lowercased() == string.lowercased()
    case .owned(let int, let quantifier):
      return false
    case .new(let new):
      return false
    case .cheapest(let currency):
      return false
    case .artists(let quantifier, let string):
      guard let artist = card.artist else { return false }
      return quantifier.performOn(artist.lowercased(), string.lowercased())
    case .colorCount(let colorChoice, let int, let quantifier):
      break // Not yet implemented
    case .devotion(let quantifier, let string):
      break // Not yet implemented
    case .collectorNumber(let quantifier, let string):
      switch quantifier {
      case .exactly:
        return card.collectorNumber.lowercased() == string.lowercased()
      case .not:
        return card.collectorNumber.lowercased() != string.lowercased()
      default:
        guard let intValue = Int(string), let intCardValue = Int(card.collectorNumber)  else { return false }
        return quantifier.performOn(intCardValue, intValue)
      }
    case .setType(let string):
      return false
    case .cube(let string):
      return false
    case .frame(let frame):
      return card.frame.lowercased() == frame?.rawValue.lowercased()
    case .stamp(let securityStamp):
      break // Not yet implemented
    case .game(let game):
      if let value = game?.rawValue.lowercased() {
        return card.games.contains(value)
      }
    case .prefer(let prefer):
      return false
    case .art(let string):
      return false
    case .function(let string):
      break // Not yet implemented
    case .and(let scryfallSearchToken, let scryfallSearchToken2):
      return scryfallSearchToken.matches(card) && scryfallSearchToken2.matches(card)
    case .or(let scryfallSearchToken, let scryfallSearchToken2):
      return scryfallSearchToken.matches(card) || scryfallSearchToken2.matches(card)
    case .not(let scryfallSearchToken):
      return !scryfallSearchToken.matches(card)
    case .parentheses(let scryfallSearchToken):
      return scryfallSearchToken.matches(card)
    }
    
    return true
  }
  
  #if OFFLINE_BACKUP
  var predicate: NSPredicate? {
    switch self {
    case .language(let lang):
      switch lang {
      case .any:
//        return "lang:any"
        return nil
      case .language(let lang):
        return NSPredicate(format: "%K == %@", #keyPath(Card.language), lang.rawValue)
      }
    case .cardName(let text, let exact):
      if exact {
        return NSPredicate(format: "%K LIKE[cd] %@", #keyPath(Card.name), text)
      } else {
        return NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Card.name), text)
      }
    case .oracleContains(let text):
      // TODO: Filter out parentheses text, add fullOracle token that searches the complete oracleText
      return NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Card.oracleText), text)
    case .type(let text):
      return NSPredicate(format: "%K CONTAINS[cd] %@", #keyPath(Card.typeLine), text)
    case .colors(let choice, let colors, let quantifier):
      if colors.contains(.c) && colors.count > 1 {
        // Cards can't be both colorless and colored
        return nil
      }
      
      let propertyKeyPath = choice.predicatePropertyKeyPath
      
      switch quantifier {
      case .not: // !=
        return ScryfallSearchToken.not(.colors(choice, colors, .exactly)).predicate
      case .exactly: // ==
        if colors == [.c] {
          return NSPredicate(format: "%K == ''", propertyKeyPath)
        }
        let colorPredicates: [NSPredicate] = ScryfallSearchToken.Color.allCases.map {
          if colors.contains($0) {
            return NSPredicate(format: "%K CONTAINS[c] %@", propertyKeyPath, $0.rawValue)
          } else {
            return NSPredicate(format: "NOT (%K CONTAINS[c] %@)", propertyKeyPath, $0.rawValue)
          }
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: colorPredicates)
      case .including: // >=
        if colors == [.c] {
          // Greater than or equal to colorless is ALL CARDS
          return NSPredicate(format: "%K LIKE %@", #keyPath(Card.name), "*")
        }
        let colorPredicates: [NSPredicate] = colors.map {
          return NSPredicate(format: "%K CONTAINS[c] %@", propertyKeyPath, $0.rawValue)
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: colorPredicates)
      case .atMost: // <=
        if colors == [.c] {
          // Less than or equal to colorless is only all colorless
          return NSPredicate(format: "%K == ''", propertyKeyPath)
        }
        
        let colorPredicates: [NSPredicate] = colors.map {
          return NSPredicate(format: "%K CONTAINS[c] %@", propertyKeyPath, $0.rawValue)
        }
        let containsAnySpecifiedColorPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: colorPredicates)
        
        let unusedColorPredicates: [NSPredicate] = ScryfallSearchToken.Color.allCases.compactMap {
          guard $0 != .c && !colors.contains($0) else { return nil }
          return NSPredicate(format: "%K CONTAINS[c] %@", propertyKeyPath, $0.rawValue)
        }
        let doesNotContainUnusedColorPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: NSCompoundPredicate(orPredicateWithSubpredicates: unusedColorPredicates))
        
        let isColorlessPredicate = NSPredicate(format: "%K == ''", propertyKeyPath)
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          isColorlessPredicate,
          NSCompoundPredicate(andPredicateWithSubpredicates: [containsAnySpecifiedColorPredicate, doesNotContainUnusedColorPredicate])
        ])
      case .greaterThan: // >
        if colors == [.c] {
          return NSPredicate(format: "%K != ''", propertyKeyPath)
        }
        
        let colorPredicates: [NSPredicate] = colors.map {
          return NSPredicate(format: "%K CONTAINS[c] %@", propertyKeyPath, $0.rawValue)
        }
        
        let includesAllSpecifiedColorsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: colorPredicates)
        
        let unusedColorPredicates: [NSPredicate] = ScryfallSearchToken.Color.allCases.compactMap {
          guard $0 != .c && !colors.contains($0) else { return nil }
          return NSPredicate(format: "%K CONTAINS[c] %@", propertyKeyPath, $0.rawValue)
        }
        let containsUnusedColorPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: unusedColorPredicates)
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [includesAllSpecifiedColorsPredicate, containsUnusedColorPredicate])
      case .lessThan: // <
        if colors == [.c] {
          // Nothing is less than colorless
          return NSPredicate(format: "%K == 'INVALID'", propertyKeyPath)
        }
        
        let colorPredicates: [NSPredicate] = colors.map {
          return NSPredicate(format: "%K CONTAINS[c] %@", propertyKeyPath, $0.rawValue)
        }
        let containsAnySpecifiedColorPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: colorPredicates)
        
        let doesNotContainAllSpecifiedColorsPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: NSCompoundPredicate(andPredicateWithSubpredicates: colorPredicates))
        
        let unusedColorPredicates: [NSPredicate] = ScryfallSearchToken.Color.allCases.compactMap {
          guard $0 != .c && !colors.contains($0) else { return nil }
          return NSPredicate(format: "%K CONTAINS[c] %@", propertyKeyPath, $0.rawValue)
        }
        let doesNotContainUnusedColorPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: NSCompoundPredicate(orPredicateWithSubpredicates: unusedColorPredicates))
        
        let isColorlessPredicate = NSPredicate(format: "%K == ''", propertyKeyPath)
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          isColorlessPredicate,
          NSCompoundPredicate(andPredicateWithSubpredicates: [containsAnySpecifiedColorPredicate, doesNotContainAllSpecifiedColorsPredicate, doesNotContainUnusedColorPredicate])
        ])
      }
    case .manaCost(let text, let quantifier):
      switch quantifier {
      case .exactly:
        // TODO: Search these in any order
        return NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.manaCost), text)
      default:
        return nil
//      case .including:
//        <#code#>
//      case .atMost:
//        <#code#>
//      case .greaterThan:
//        <#code#>
//      case .lessThan:
//        <#code#>
      }
//      return "mana\(quantifier.rawValue)\(text)"
    case .stats(let stat, let quantifier, let value):
      
      switch stat {
      case .cmc:
        return NSPredicate(format: "%K \(quantifier.rawValue) %@", stat.predicatePropertyKeyPathString, value)
      default:
        // TODO: This doesn't work for power/toughness/loyalty since they're STRINGS
        switch quantifier {
        case .exactly:
          return NSPredicate(format: "%K \(quantifier.rawValue) %@", stat.predicatePropertyKeyPathString, value)
        default:
          return Card.makePredicateForOptionalDoubleValue(
            keyPath: stat.predicateNumericPropertyKeyPath,
            format: "%K \(quantifier.rawValue) %@",
            arguments: value
          )
        }
      }
      
//    case .legal(let legality, let format):
//      return "\(legality.rawValue):\(format)"
    case .sets(let sets):
      let setPredicates = sets.map { NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.set), $0) }
      return NSCompoundPredicate(orPredicateWithSubpredicates: setPredicates)
//    case .blocks(let blocks):
//      return "block:\(blocks.joined(separator: ","))"
    case .rarity(let rarity, let quantifier):
      switch quantifier {
      case .not:
        return ScryfallSearchToken.not(.rarity(rarity, .exactly)).predicate
      case .exactly:
        return NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.rarity), rarity.rawValue)
      case .including: // >=
        let allowedRarities = ScryfallSearchToken.Rarity.allCases.filter { $0 >= rarity }
        let predicates = allowedRarities.map { NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.rarity), $0.rawValue) }
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
      case .atMost:
        let allowedRarities = ScryfallSearchToken.Rarity.allCases.filter { $0 <= rarity }
        let predicates = allowedRarities.map { NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.rarity), $0.rawValue) }
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
      case .greaterThan:
        let allowedRarities = ScryfallSearchToken.Rarity.allCases.filter { $0 > rarity }
        let predicates = allowedRarities.map { NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.rarity), $0.rawValue) }
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
      case .lessThan:
        let allowedRarities = ScryfallSearchToken.Rarity.allCases.filter { $0 < rarity }
        let predicates = allowedRarities.map { NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.rarity), $0.rawValue) }
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
      }
//    case .in(let value):
//      return "in:\(value)"
//    case .keyword(let value):
//      return "keyword:\(spaceFixed(value))"
    case .criterion(let value):
      guard let criterion = Criterion(rawValue: value.lowercased()) else { return nil }
      switch criterion {
      case .adventure:
        return NSPredicate(format: "%K LIKE[c] 'adventure'", #keyPath(Card.layout))
      case .arenaid:
        return nil
      case .artistmisprint:
        return nil
      case .augmentation:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "%K LIKE[c] 'augment'", #keyPath(Card.layout)),
          NSPredicate(format: "%K CONTAINS[c] 'host'", #keyPath(Card.typeLine))
        ])
      case .back:
        return NSPredicate(format: "%K != %@", #keyPath(Card.cardBackId), NSUUID(uuidString: "0aeebaf5-8c7d-4636-9e82-8c27447861f7")!)
      case .booster:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isFoundInBoosters), NSNumber(value: true))
      case .boosterfun:
        return nil
      case .brawlcommander:
        return nil
      case .buyabox:
        return nil
      case .ci:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "SUBQUERY(%K, $face, $face.colorIndicator != nil).@count > 0", #keyPath(Card.faces)),
          NSPredicate(format: "%K != nil", #keyPath(Card.colorIndicator))
        ])
      case .colorshifted:
        return nil
      case .commander:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K CONTAINS[c] 'legendary'", #keyPath(Card.typeLine)),
            NSPredicate(format: "%K CONTAINS[c] 'creature'", #keyPath(Card.typeLine))
          ]),
          NSPredicate(format: "oracleText CONTAINS[c] 'can be your commander'")
        ])
      case .companion:
        return nil
      case .manland:
        return nil
      case .datestamped:
        return nil
      case .digital:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isDigital), NSNumber(value: true))
      case .doublesided:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "%K LIKE[c] 'transform'", #keyPath(Card.layout)),
          NSPredicate(format: "%K LIKE[c] 'modal_dfc'", #keyPath(Card.layout)),
          NSPredicate(format: "%K LIKE[c] 'meld'", #keyPath(Card.layout)),
          NSPredicate(format: "%K LIKE[c] 'double_faced_token'", #keyPath(Card.layout))
        ])
      case .etb:
        return NSPredicate(format: "%K CONTAINS[c] 'enters the battlefield'", #keyPath(Card.oracleText))
      case .etched:
        return nil
      case .englishart:
        return nil
      case .extra:
        return CardService.shared.isExtraPredicate
//      case .firstprint:
//        <#code#>
//      case .flavorname:
        // TODO: This doesn't work…
//        return NSCompoundPredicate(orPredicateWithSubpredicates: [
//          NSPredicate(format: "flavorName != nil"),
//          NSPredicate(format: "SUBQUERY(faces, $face, $face.flavorName != nil).@count > 0")
//        ])
      case .flavor:
        return NSPredicate(format: "%K != nil", #keyPath(Card.flavorText))
      case .flip:
        return NSPredicate(format: "%K LIKE[c] 'flip'", #keyPath(Card.layout))
      case .foil:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isFoilAvailable), NSNumber(value: true))
      case .fbb:
        return nil
      case .fwb:
        return nil
      case .frenchvanilla:
        return nil
      case .fullart:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isFullArt), NSNumber(value: true))
      case .funny:
        return nil
      case .future:
        return NSPredicate(format: "%K LIKE[c] 'future'", #keyPath(Card.frame))
      case .gameday:
        return nil
      case .hires:
        return NSPredicate(format: "%K == %@", #keyPath(Card.highResImage), NSNumber(value: true))
      case .historic:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "%K CONTAINS[c] 'artifact'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'legendary'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'saga'", #keyPath(Card.typeLine))
        ])
      case .splitmana:
        let splitSymbols: [MTGSymbolName] = [
          .symbol_2_W, .symbol_2_U, .symbol_2_B, .symbol_2_R, .symbol_2_G,
          .symbol_W_U, .symbol_U_B, .symbol_B_R, .symbol_R_G, .symbol_G_W,
          .symbol_W_B, .symbol_U_R, .symbol_B_G, .symbol_R_W, .symbol_G_U
        ]
        return NSCompoundPredicate(orPredicateWithSubpredicates: splitSymbols.map {
          NSPredicate(format: "%K CONTAINS %@", #keyPath(Card.manaCost), $0.rawValue)
        })
      case .intropack:
        return nil
      case .invitational:
        return nil
      case .leveler:
        return NSPredicate(format: "%K LIKE[c] 'leveler'", #keyPath(Card.layout))
      case .localizedname:
        return nil
      case .mtgoid:
        return nil
      case .masterpiece:
        return NSPredicate(format: "%K LIKE[c] 'masterpiece'", #keyPath(Card.setType))
      case .meld:
        return NSPredicate(format: "%K LIKE[c] 'meld'", #keyPath(Card.layout))
      case .modal:
        return nil
      case .mdfc:
        return NSPredicate(format: "%K LIKE[c] 'modal_dfc'", #keyPath(Card.layout))
      case .modern:
        return NSPredicate(format: "%K LIKE[c] '2003'", #keyPath(Card.frame))
      case .multiverse:
        return nil
      case .new:
        return nil
      case .nonfoil:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isNonFoilAvailable), NSNumber(value: true))
      case .old:
        return nil
      case .oversized:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isOversized), NSNumber(value: true))
      case .paperart:
        return nil
      case .party:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "%K CONTAINS[c] 'cleric'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'rogue'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'warrior'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'wizard'", #keyPath(Card.typeLine))
        ])
      case .outlaw:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "%K CONTAINS[c] 'warlock'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'rogue'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'assassin'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'mercenary'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'pirate'", #keyPath(Card.typeLine)),
        ])
      case .permanent:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "%K CONTAINS[c] 'artifact'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'creature'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'enchantment'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'planeswalker'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'land'", #keyPath(Card.typeLine))
        ])
      case .phyrexian:
        let splitSymbols: [MTGSymbolName] = [
          .symbol_W_P, .symbol_U_P, .symbol_B_P, .symbol_R_P, .symbol_G_P,
          .symbol_W_U_P, .symbol_U_B_P, .symbol_B_R_P, .symbol_R_G_P, .symbol_G_W_P,
          .symbol_W_B_P, .symbol_U_R_P, .symbol_B_G_P, .symbol_R_W_P, .symbol_G_U_P
        ]
        return NSCompoundPredicate(orPredicateWithSubpredicates: splitSymbols.map {
          NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "%K CONTAINS %@", #keyPath(Card.manaCost), $0.rawValue),
            NSPredicate(format: "%K CONTAINS %@", #keyPath(Card.oracleText), $0.rawValue)
          ])
        })
      case .planeswalkerdeck:
        return nil
      case .prerelease:
        return nil
      case .printedtext:
        return NSPredicate(format: "%K != nil", #keyPath(Card.oracleText))
      case .promo:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isPromo), NSNumber(value: true))
      case .promostamped:
        return nil
      case .release:
        return nil
      case .reprint:
        return nil
      case .reserved:
        return NSPredicate(format: "%K == %@", #keyPath(Card.reserved), NSNumber(value: true))
      case .spell:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "%K CONTAINS[c] 'artifact'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'creature'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'enchantment'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'planeswalker'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'land'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'instant'", #keyPath(Card.typeLine)),
          NSPredicate(format: "%K CONTAINS[c] 'sorcery'", #keyPath(Card.typeLine)),
        ])
      case .spikey:
        return nil
      case .split:
        return NSPredicate(format: "%K LIKE[c] 'split'", #keyPath(Card.layout))
      case .starterdeck:
        return nil
      case .story:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isStorySpotlight), NSNumber(value: true))
      case .tcgplayer:
        return nil
      case .textless:
        return NSPredicate(format: "%K == %@", #keyPath(Card.isTextless), NSNumber(value: true))
      case .timeshifted:
        return nil
      case .token:
        return NSPredicate(format: "%K CONTAINS[c] 'token'", #keyPath(Card.layout))
      case .tombstone:
        return nil
      case .transform:
        return NSPredicate(format: "%K LIKE[c] 'transform'", #keyPath(Card.layout))
      case .onlyprint:
        return nil
      case .vanilla:
        #warning("TODO: Check for cards with reminder text all in reminder text")
        return NSPredicate(format: "%K LIKE[c] '' OR %K == nil", #keyPath(Card.oracleText), #keyPath(Card.oracleText))
      case .variation:
        return nil
      case .watermark:
        return NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "%K != nil", #keyPath(Card.watermark)),
          NSPredicate(format: "SUBQUERY(faces, $face, $face.watermark != nil).@count > 0")
        ])
      case .alchemy:
        return NSPredicate(format: "%K LIKE[c] 'alchemy'", #keyPath(Card.setType))
      case .cycleland,
          .bounceland,
          .checkland,
          .canopyland,
          .dual,
          .fastland,
          .fetchland,
          .filterland,
          .gainland,
          .painland,
          .scryland,
          .shadowland,
          .shockland,
          .storageland,
          .triland,
          .battleland,
          .bondland,
          .triome,
          .slowland,
          .snarl:
        guard let cardNames = cardNamesForCriterion[criterion] else { return nil }
        let predicates = cardNames.compactMap { ScryfallSearchToken.cardName($0, exact: true).predicate }
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
      case .artist:
        return nil
      case .firstprint:
        return nil
      case .flavorname:
        return nil
      case .bear:
        return ScryfallSearchToken(andMultiple: [
          .stats(.power, .exactly, "2"),
          .stats(.toughness, .exactly, "2"),
          .stats(.cmc, .exactly, "2")
        ])?.predicate
      case .stamp:
        return NSPredicate(format: "%K != nil", #keyPath(Card.securityStamp))
      case .owned:
        return nil
      }
      
//      return "is:\(spaceFixed(value))"
    case .and(let first, let second):
      if let first = first.predicate, second.noPredicateAllowed {
        return first
      } else if let second = second.predicate, first.noPredicateAllowed {
        return second
      }
      
      guard let first = first.predicate, let second = second.predicate else { return nil }
      return NSCompoundPredicate(andPredicateWithSubpredicates: [first, second])
    case .or(let first, let second):
      guard let first = first.predicate, let second = second.predicate else { return nil }
      return NSCompoundPredicate(orPredicateWithSubpredicates: [first, second])
    case .not(let token):
      if case .unique(_) = token {
        return nil
      } else if case .include(_) = token {
        return nil
      }
      guard let predicate = token.predicate else { return nil }
      return NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
    case .parentheses(let token):
      return token.predicate
//    case .year(let quantifier, let year):
//      return "year\(quantifier.rawValue)\(year)"
    case .border(let color):
      return NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.borderColor), color.rawValue)
    case .artist(let artist):
      return NSPredicate(format: "%K CONTAINS[c] %@", #keyPath(Card.artist), artist)
    case .include(_):
      return nil
    case .flavorText(let value):
      return NSPredicate(format: "%K CONTAINS[c] %@", #keyPath(Card.flavorText), value)
    case .lore(let value):
      let tokens: [ScryfallSearchToken] = [
        .oracleContains(value),
        .flavorText(value),
        .cardName(value)
      ]
      
      return ScryfallSearchToken.init(orMultiple: tokens)?.predicate
//    case .price(let currency, let quantifier, let value):
//      return "\(currency.rawValue)\(quantifier.rawValue)\(value)"
//    case .uniquePrints:
//      return "unique:prints"
    case .watermark(let value):
      return NSCompoundPredicate(orPredicateWithSubpredicates: [
        NSPredicate(format: "%K LIKE[c] %@", #keyPath(Card.watermark), value),
        NSPredicate(format: "SUBQUERY(faces, $face, $face.watermark LIKE[c] %@).@count > 0", value)
      ])
//    default: return nil
    case .price(_, _, _):
      return nil
    case .legal(_, _):
      return nil
    case .blocks(_):
      return nil
    case .in(_):
      return nil
    case .keyword(_):
      return nil
    case .year(_, _):
      return nil
    case .unique(_):
      return nil
    case .owned(_, _):
      return nil
    }
  }
  #endif
  
  private var cardNamesForCriterion: [Criterion: [String]] {
    [
      .cycleland: [
        "Canyon Slough",
        "Fetid Pools",
        "Irrigated Farmland",
        "Scattered Groves",
        "Sheltered Thicket"
      ],
      .bounceland: [
        "Azorius Chancery",
        "Boros Garrison",
        "Coral Atoll",
        "Dimir Aqueduct",
        "Dormant Volcano",
        "Everglades",
        "Golgari Rot Farm",
        "Gruul Turf",
        "Guildless Commons",
        "Izzet Boilerworks",
        "Jungle Basin",
        "Karoo",
        "Orzhov Basilica",
        "Rakdos Carnarium",
        "Selesnya Sanctuary",
        "Simic Growth Chamber"
      ],
      .checkland: [
        "Clifftop Retreat",
        "Dragonskull Summit",
        "Drowned Catacomb",
        "Glacial Fortress",
        "Hinterland Harbor",
        "Isolated Chapel",
        "Rootbound Crag",
        "Sulfur Falls",
        "Sunpetal Grove",
        "Woodland Cemetery"
      ],
      .canopyland: [
        "Firey Islet",
        "Horizon Canopy",
        "Nurturing Peatland",
        "Silent Clearing",
        "Sunbaked Canyon",
        "Waterlogged Grove"
      ],
      .dual: [
        "Badlands",
        "Bayou",
        "Plateau",
        "Savannah",
        "Scrubland",
        "Taiga",
        "Tropical Island",
        "Tundra",
        "Underground Sea",
        "Volcanic Island"
      ],
      .fastland: [
        "Blackcleave Cliffs",
        "Blooming Marsh",
        "Botanical Sanctum",
        "Concealed Courtyard",
        "Copperline Gorge",
        "Darkslick Shores",
        "Inspiring Vantage",
        "Razorverge Thicket",
        "Seachrome Coast",
        "Spirebluff Canal"
      ],
      .fetchland: [
        "Arid Mesa",
        "Bloodstained Mire",
        "Flooded Strand",
        "Marsh Flats",
        "Misty Rainforest",
        "Polluted Delta",
        "Scalding Tarn",
        "Verdant Catacombs",
        "Windswept Heath",
        "Wooded Foothills"
      ],
      .filterland: [
        "Cascade Bluffs",
        "Cascading Cataracts",
        "Crystal Quarry",
        "Darkwater Catacombs",
        "Fetid Heath",
        "Fire-Lit Thicket",
        "Flooded Grove",
        "Graven Cairns",
        "Mossfire Valley",
        "Mystic Gate",
        "Rugged Prairie",
        "Shadowblood Ridge",
        "Skycloud Expanse",
        "Sungrass Prairie",
        "Sunken Ruins",
        "Twilight Mire",
        "Wooded Bastion"
      ],
      .gainland: [
        "Akoum Refuge",
        "Bloodfell Caves",
        "Blossoming Sands",
        "Dismal Backwater",
        "Graypelt Refuge",
        "Jungle Hollow",
        "Jwar Isle Refuge",
        "Kazandu Refuge",
        "Rugged Highlands",
        "Scoured Barrens",
        "Sejiri Refuge",
        "Swiftwater Cliffs",
        "Thornwood Falls",
        "Tranquil Cove",
        "Wind-Scarred Crag"
      ],
      .painland: [
        "Adarkar Wastes",
        "Battlefield Forge",
        "Brushland",
        "Caves of Koilos",
        "Karplusan Forest",
        "Llanowar Wastes",
        "Shivan Reef",
        "Sulfurous Springs",
        "Underground River",
        "Yavimaya Coast"
      ],
      .scryland: [
        "Temple of Abandon",
        "Temple of Deceit",
        "Temple of Enlightenment",
        "Temple of Epiphany",
        "Temple of Malady",
        "Temple of Malice",
        "Temple of Mystery",
        "Temple of Plenty",
        "Temple of Silence",
        "Temple of Triumph"
      ],
      .shadowland: [
        "Choked Estuary",
        "Foreboding Ruins",
        "Fortified Village",
        "Game Trail",
        "Port Town"
      ],
      .shockland: [
        "Blood Crypt",
        "Breeding Pool",
        "Godless Shrine",
        "Hallowed Fountain",
        "Overgrown Tomb",
        "Sacred Foundry",
        "Steam Vents",
        "Stomping Ground",
        "Temple Garden",
        "Watery Grave"
      ],
      .storageland: [
        "Bottomless Vault",
        "Calciform Pools",
        "Crucible of the Spirit Dragon",
        "Dreadship Reef",
        "Dwarven Hold",
        "Fungal Reaches",
        "Hollow Trees",
        "Icatian Store",
        "Mage-Ring Network",
        "Molten Slagheap",
        "Saltcrusted Steppe",
        "Sand Silos"
      ],
      .triland: [
        "Arcane Sanctum",
        "Crumbling Necropolis",
        "Frontier Bivouac",
        "Jungle Shrine",
        "Mystic Monastery",
        "Nomad Outpost",
        "Opulent Palace",
        "Sandsteppe Citadel",
        "Savage Lands",
        "Seaside Citadel"
      ],
      .battleland: [
        "Canopy Vista",
        "Cinder Glade",
        "Prairie Stream",
        "Smoldering Marsh",
        "Sunken Hollow"
      ],
      .triome: [
        "Indatha Triome",
        "Jetmir's Garden",
        "Ketria Triome",
        "Raffine's Tower",
        "Raugrin Triome",
        "Savai Triome",
        "Spara's Headquarters",
        "Xander's Lounge",
        "Zagoth Triome",
        "Ziatora's Proving Ground"
      ],
      .slowland: [
        "Deathcap Glade",
        "Deserted Beach",
        "Dreamroot Cascade",
        "Haunted Ridge",
        "Overgrown Farmland",
        "Rockfall Vale",
        "Shattered Sanctum",
        "Shipwreck Marsh",
        "Stormcarved Coast",
        "Sundown Pass"
      ],
      .snarl: [
        "Frostboil Snarl",
        "Furycalm Snarl",
        "Necroblossom Snarl",
        "Shineshadow Snarl",
        "Vineglimmer Snarl"
      ],
      .bondland: [
        "Bountiful Promenade",
        "Luxury Suite",
        "Morphic Pool",
        "Rejuvenating Springs",
        "Sea of Clouds",
        "Spectator Seating",
        "Spire Garden",
        "Training Center",
        "Undergrowth Stadium",
        "Vault of Champions"
      ]
    ]
  }
  
//  cate(format: "typeLine CONTAINS[c] 'Vanguard'"),
//  NSPredicate(format: "typeLine CONTAINS[c] 'Scheme'"),
//  NSPredicate(format: "typeLine CONTAINS[c] 'Plane '"),
//  NSPredicate(format: "typeLine CONTAINS[c] 'Phenomenon'"),
//  NSPredicate(format: "layout LIKE[c] 'token'"),
//  NSPredicate(format: "layout LIKE[c] 'emblem'"),
//  NSPredicate(format: "setType LIKE[c] 'memorabilia'"),
//  NSPredicate(format: "set ENDSWITH[c] 'Minigames'"),
//  NSPredicate(format: "set LIKE[c] 'cmb1'"),
//  NSPredicate(format: "set LIKE[c] 'cmb2'"
  
  var needsExtras: Bool {
    switch self {
    case .include(let value):
      return value.lowercased() == "extras"
    case .type(let t):
      let t = t.lowercased()
      switch t {
      case "vanguard", "plane", "phenomenon", "token", "emblem":
        return true
//      case _ where CardTypes.planes.options.contains(where: { $0.value.lowercased() == t }):
//        return true
      default:
        break
      }
    case .criterion(let c):
      guard let criterion = Criterion(rawValue: c) else { return false }
      switch criterion {
//      case .adventure:
//        <#code#>
//      case .arenaid:
//        <#code#>
//      case .artist:
//        <#code#>
//      case .artistmisprint:
//        <#code#>
      case .augmentation:
        return true
//      case .back:
//        <#code#>
//      case .booster:
//        <#code#>
//      case .boosterfun:
//        <#code#>
//      case .brawlcommander:
//        <#code#>
//      case .buyabox:
//        <#code#>
//      case .ci:
//        <#code#>
//      case .colorshifted:
//        <#code#>
//      case .commander:
//        <#code#>
//      case .companion:
//        <#code#>
//      case .manland:
//        <#code#>
//      case .datestamped:
//        <#code#>
//      case .digital:
//        <#code#>
//      case .doublesided:
//        <#code#>
//      case .etb:
//        <#code#>
//      case .etched:
//        <#code#>
//      case .englishart:
//        <#code#>
      case .extra:
        return true
//      case .firstprint:
//        <#code#>
//      case .flavorname:
//        <#code#>
//      case .flavor:
//        <#code#>
//      case .flip:
//        <#code#>
//      case .foil:
//        <#code#>
//      case .fbb:
//        <#code#>
//      case .fwb:
//        <#code#>
//      case .frenchvanilla:
//        <#code#>
//      case .fullart:
//        <#code#>
      case .funny:
        return true
//      case .future:
//        <#code#>
//      case .gameday:
//        <#code#>
//      case .hires:
//        <#code#>
//      case .historic:
//        <#code#>
//      case .splitmana:
//        <#code#>
//      case .intropack:
//        <#code#>
//      case .invitational:
//        <#code#>
//      case .leveler:
//        <#code#>
//      case .localizedname:
//        <#code#>
//      case .mtgoid:
//        <#code#>
//      case .masterpiece:
//        <#code#>
//      case .meld:
//        <#code#>
//      case .modal:
//        <#code#>
//      case .mdfc:
//        <#code#>
//      case .modern:
//        <#code#>
//      case .multiverse:
//        <#code#>
//      case .new:
//        <#code#>
//      case .nonfoil:
//        <#code#>
//      case .old:
//        <#code#>
      case .oversized:
        return true
//      case .paperart:
//        <#code#>
//      case .party:
//        <#code#>
//      case .permanent:
//        <#code#>
//      case .phyrexian:
//        <#code#>
//      case .planeswalkerdeck:
//        <#code#>
//      case .prerelease:
//        <#code#>
//      case .printedtext:
//        <#code#>
//      case .promo:
//        <#code#>
//      case .promostamped:
//        <#code#>
//      case .release:
//        <#code#>
//      case .reprint:
//        <#code#>
//      case .reserved:
//        <#code#>
//      case .spell:
//        <#code#>
//      case .spikey:
//        <#code#>
//      case .split:
//        <#code#>
//      case .starterdeck:
//        <#code#>
//      case .story:
//        <#code#>
//      case .tcgplayer:
//        <#code#>
//      case .textless:
//        <#code#>
//      case .timeshifted:
//        <#code#>
      case .token:
        return true
//      case .tombstone:
//        <#code#>
//      case .transform:
//        <#code#>
//      case .onlyprint:
//        <#code#>
//      case .vanilla:
//        <#code#>
//      case .variation:
//        <#code#>
//      case .watermark:
//        <#code#>
//      case .alchemy:
//        <#code#>
//      case .bear:
//        <#code#>
//      case .cycleland:
//        <#code#>
//      case .bounceland:
//        <#code#>
//      case .checkland:
//        <#code#>
//      case .canopyland:
//        <#code#>
//      case .dual:
//        <#code#>
//      case .fastland:
//        <#code#>
//      case .fetchland:
//        <#code#>
//      case .filterland:
//        <#code#>
//      case .gainland:
//        <#code#>
//      case .painland:
//        <#code#>
//      case .scryland:
//        <#code#>
//      case .shadowland:
//        <#code#>
//      case .shockland:
//        <#code#>
//      case .storageland:
//        <#code#>
//      case .triland:
//        <#code#>
//      case .battleland:
//        <#code#>
//      case .bondland:
//        <#code#>
//      case .triome:
//        <#code#>
//      case .slowland:
//        <#code#>
//      case .snarl:
//        <#code#>
      default:
        return false
      }
    case .sets(let sets):
      return sets.contains(where: {
        $0.hasPrefix("t") || $0 == "cmb1" || $0 == "cmb2"
      })
    default:
      break
    }
    
    return false
  }
  
  var noPredicateAllowed: Bool {
    if case .unique(_) = self {
      return true
    } else if case .include(_) = self {
      return true
    }
    
    return false
  }
  
  var queryString: String {
    switch self {
    case .language(let lang):
      guard let lang else { return "lang:" }
      switch lang {
      case .any: return "lang:any"
      case .language(let lang):
        return "lang:\(lang.rawValue)"
      }
    case .cardName(let text, let exact):
//      let string = spaceFixed(text)
      return exact ? "!" + text : text
    case .oracleContains(let text):
//      let words = text.components(separatedBy: .whitespacesAndNewlines)
//      if words.count == 1, let first = words.first {
//        return "oracle:\(first)"
//      }
//      return "(" + words.map { "oracle:\($0)" }.joined(separator: " ") + ")"
      return "o:\(spaceFixed(text))"
    case .type(let text):
      return "type:\(spaceFixed(text))"
    case .colors(let choice, let colors, let quantifier):
      return "\(choice.rawValue)\(quantifier.rawValue)\(colors.map(\.rawValue).joined())"
    case .manaCost(let text, let quantifier):
      return "mana\(quantifier.rawValue)\(text)"
    case .stats(let stat, let quantifier, let value):
      return "\(stat.rawValue)\(quantifier.rawValue)\(value)"
    case .legal(let legality, let format):
      return "\(legality.rawValue):\(format)"
    case .sets(let sets):
      return "set:\(sets.joined(separator: ","))"
    case .blocks(let blocks):
      return "block:\(blocks.joined(separator: ","))"
    case .rarity(let rarity, let quantifier):
      return "rarity\(quantifier.rawValue)\(rarity.rawValue)"
    case .in(let value):
      return "in:\(value)"
    case .keyword(let value):
      return "keyword:\(spaceFixed(value))"
    case .criterion(let value):
      return "is:\(spaceFixed(value))"
    case .and(let first, let second):
      return "\(first.queryString) \(second.queryString)"
    case .or(let first, let second):
      return "\(first.queryString) OR \(second.queryString)"
    case .not(let token):
      if case .not(let token) = token {
        return token.queryString
      } else if case .criterion(let value) = token {
        return "not:\(value)"
      } else if case .direct(let query, let name, let description) = token {
        return "-(\(query))"
      } else {
        return "-\(token.queryString)"
      }
    case .parentheses(let token):
      return "(\(token.queryString))"
    case .year(let quantifier, let year):
      return "year\(quantifier.rawValue)\(year)"
    case .border(let color):
      return "border:\(color.rawValue)"
    case .artist(let artist):
      return "artist:\(spaceFixed(artist))"
    case .include(let quality):
      return "include:\(spaceFixed(quality))"
    case .flavorText(let value):
      return "flavor:\(spaceFixed(value))"
    case .lore(let value):
      return "lore:\(spaceFixed(value))"
    case .price(let currency, let quantifier, let value):
      return "\(currency.rawValue)\(quantifier.numericHumanReadable)\(value)"
    case .unique(let value):
      return "unique:\(value)"
    case .watermark(let wm):
      return "watermark:\(spaceFixed(wm))"
    case .owned(let quantity, let quantifier):
      return "owned\(quantifier.rawValue)\(quantity)"
    case .new(let value):
      return "new:\(value?.rawValue ?? "")"
    case .cheapest(let value):
      return "cheapest:\(value.rawValue)"
    case .artists(let quantifier, let value):
      return "artists\(quantifier.rawValue)\(value)"
    case .colorCount(let colorChoice, let value, let quantifier):
      return "\(colorChoice.rawValue)\(quantifier.rawValue)\(value)"
    case .devotion(let quantifier, let value):
      return "devotion\(quantifier.rawValue)\(value)"
    case .collectorNumber(let quantifier, let value):
      return "number\(quantifier.rawValue)\(value)"
    case .setType(let value):
      return "st:\(value)"
    case .cube(let value):
      return "cube:\(value)"
    case .frame(let value):
      return "frame:\(value?.rawValue ?? "")"
    case .stamp(let stamp):
      return "stamp:\(stamp?.rawValue ?? "")"
    case .game(let value):
      return "game:\(value?.rawValue ?? "")"
    case .prefer(let prefer):
      return "prefer:\(prefer?.rawValue ?? "")"
    case .art(let value):
      return "art:\(value)"
    case .function(let value):
      return "function:\(value)"
    case .direct(query: let query, name: let name, humanReadableDescription: let description):
      return query
    }
  }
  
  var humanReadableDescription: String? {
    switch self {
    case .language(let lang):
      guard let lang else { return nil }
      switch lang {
      case .any:
        return "the cards are any language"
      case .language(let lang):
        return "the language is \(lang.name)"
      }
    case .cardName(let text, let exact):
      if exact {
        return "the name is exactly “\(text)”"
      } else {
        return "the name includes “\(text)”"
      }
    case .oracleContains(let text):
      return "the text includes “\(text)”"
    case .type(let text):
      return "the card types include “\(text)”"
    case .colors(let choice, let colors, let quantifier):
      if colors == [.c] || colors == [] {
        return "the \(choice.humanReadable) \(quantifier.qualityHumanReadable) colorless"
      }
      return "the \(choice.humanReadable) \(quantifier.qualityHumanReadable) \(colors.map(\.rawValue).joined())"
    case .manaCost(let text, let quantifier):
      return "the mana cost \(quantifier.humanReadable) \(text)"
    case .stats(let stat, let quantifier, let value):
      return "the \(stat.rawValue) \(quantifier.qualityHumanReadable) \(value)"
    case .price(let currency, let quantifier, let value):
      return "the \(currency.humanReadable) price \(quantifier.qualityHumanReadable) \(value)"
    case .legal(let legality, let format):
      return "it’s \(legality.rawValue) in \(format.capitalized)"
    case .sets(let sets):
      if sets.count == 1, let first = sets.first {
        return "the set is “\(first)”"
      } else {
        return "the set is one of \(sets.map { "“\($0)”" }.joined(separator: ", "))"
      }
    case .blocks(let blocks):
      if blocks.count == 1, let first = blocks.first {
        return "the block is “\(first)”"
      } else {
        return "the block is one of \(blocks.map { "“\($0)”" }.joined(separator: ", "))"
      }
    case .rarity(let rarity, let quantifier):
      return "the rarity is \(quantifier.qualityHumanReadable) \(rarity.humanReadable)"
    case .in(let value):
      return "the card was in “\(value)”"
    case .keyword(let value):
      return "the card has the keyword “\(value)”"
      
    case .and(let first, let second):
      if let first = first.humanReadableDescription, second.noPredicateAllowed {
        return first
      }
      
      if let second = second.humanReadableDescription, first.noPredicateAllowed {
        return second
      }
      
      guard let first = first.humanReadableDescription, let second = second.humanReadableDescription else {
        return nil
      }
      return "\(first) and \(second)"
    case .or(let first, let second):
      guard let first = first.humanReadableDescription, let second = second.humanReadableDescription else {
        return nil
      }
      return "(\(first) or \(second))"
    case .parentheses(let token):
      guard let first = token.humanReadableDescription else {
        return nil
      }
      return "(\(first))"
    case .criterion(let value):
      if let criterion = Criterion(rawValue: value), let text = criterion.humanReadable {
        return text
      } else {
        return "the cards are “\(value)”"
      }
    case .year(let quantifier, let year):
      return "the release year \(quantifier.numericHumanReadable) \(year)"
    case .border(let color):
      return "the border color is “\(color.rawValue)“"
    case .artist(let artist):
      return "the artist name includes “\(artist)”"
    case .not(let token):
      switch token {
      case .language(let lang):
        guard let lang else { return nil }
        switch lang {
        case .any:
          return "the cards aren’t any language"
        case .language(let lang):
          return "the language is not \(lang.name)"
        }
      case .cardName(let text, _):
        return "the name doesn’t include “\(text)”"
      case .oracleContains(let text):
        return "the text doesn’t include “\(text)”"
      case .type(let text):
        return "the card types exclude “\(text)”"
      case .colors(let choice, let colors, let quantifier):
        switch choice {
        case .color:
          return "the colors are not \(quantifier.qualityHumanReadable) \(colors.map(\.rawValue).joined())"
        case .identity:
          return "the color identity is not \(quantifier.qualityHumanReadable) \(colors.map(\.rawValue).joined())"
        }
      case .manaCost(let text, let quantifier):
        return "the mana cost is not \(quantifier.humanReadable) \(text)"
      case .stats(let stat, let quantifier, let value):
        return "the \(stat.rawValue) is not \(quantifier.rawValue) \(value)"
      case .price(let currency, let quantifier, let value):
        return "the \(currency.humanReadable) price is not \(quantifier.numericHumanReadable) \(value)"
      case .legal(let legality, let format):
        return "it’s not \(legality.rawValue) in \(format)"
      case .sets(let sets):
        if sets.count == 1, let first = sets.first {
          return "the set is not “\(first)”"
        } else {
          return "the set is not one of \(sets.map { "“\($0)”" }.joined(separator: ", "))"
        }
      case .blocks(let blocks):
        if blocks.count == 1, let first = blocks.first {
          return "the block is not “\(first)”"
        } else {
          return "the block is not one of \(blocks.map { "“\($0)”" }.joined(separator: ", "))"
        }
      case .in(let value):
        return "the card was not in “\(value)”"
      case .keyword(let value):
        return "the card doesn’t have the keyword “\(value)”"
      case .rarity(let rarity, let quantifier):
        return "the rarity is not \(quantifier.humanReadable) \(rarity.humanReadable)"
      case .criterion(let value):
        if let criterion = Criterion(rawValue: value) {
          if let text = criterion.negatedHumanReadable {
            return text
          } else if let text = criterion.humanReadable {
            return "not " + text
          }
        }
        return "the cards are not “\(value)”"
      case .and(let first, let second):
        guard let first = first.humanReadableDescription, let second = second.humanReadableDescription else {
          return nil
        }
        return "not (\(first) and \(second))"
      case .or(let first, let second):
        guard let first = first.humanReadableDescription, let second = second.humanReadableDescription else {
          return nil
        }
        return "not (\(first) or \(second))"
      case .parentheses(let token):
        guard let first = token.humanReadableDescription else {
          return nil
        }
        return "(not (\(first)))"
      case .not(let token):
        return token.humanReadableDescription
      case .year(let quantifier, let year):
        return "the release year is not \(quantifier.numericHumanReadable) \(year)"
      case .border(let color):
        return "the border color is not \"\(color.rawValue)\""
      case .artist(let artist):
        return "the artist name doesn't contain “\(artist)”"
      case .include(_):
        return nil
      case .flavorText(let value):
        return "the flavor text doesn't contain “\(value)”"
      case .lore(let value):
        return "the lore doesn't include “\(value)”"
      case .unique(_):
        return nil
      case .watermark(let wm):
        return "the cards don't have the “\(wm)” watermark"
      case .owned(let quantity, let quantifier):
        return "the number of copies in your collection is not \(quantifier.numericHumanReadable) \(quantity)"
      case .new(let value):
        guard let value else { return nil }
        return switch value {
        case .rarity: "the cards don't have a new rarity"
        case .art: "the cards don't have new art"
        case .artist: "the cards don't have new artists"
        case .flavor: "the cards don't have new flavor text"
        case .frame: "the cards don't have new frames"
        case .language: "the cards weren't printed in a new language"
        }
      case .cheapest(let value):
        return "the card doesn't have the lowest \(value.rawValue.uppercased()) price"
      case .artists(_, _):
        return nil
      case .colorCount(let colorChoice, let value, let quantifier):
        if quantifier == .exactly {
          return "the number of \(colorChoice == .identity ? "identity " : "")colors is not \(value)"
        } else {
          return "the number of \(colorChoice == .identity ? "identity " : "")colors is not \(quantifier.rawValue) \(value)"
        }
      case .devotion(let quantifier, let value):
        return "the card's devotion is not \(quantifier.humanReadable) to \(value)"
      case .collectorNumber(let quantifier, let value):
        return nil
      case .setType(let value):
        return "the set type is not \(value)"
      case .cube(let value):
        return "the card is not in the \(value) cube"
      case .frame(let value):
        guard let value else { return nil }
        return switch value {
        case .showcase:
          "the cards don’t have a custom Showcase frame"
        case .extendedart:
          "the cards don’t have an extended art frame"
        default:
          "the cards don’t have the \(value.name) frame"
        }
      case .stamp(let stamp):
        guard let stamp else { return nil }
        return "the cards don’t have the \(stamp.descriptiveString) security stamp"
      case .game(let value):
        guard let value else { return nil }
        return "the card is not available on \(value.name)"
      case .prefer(_):
        return nil
      case .art(let value):
        return "the illustration doesn't contain “\(value)”"
      case .function(let value):
        return "the card isn't tagged “\(value)”"
      case .direct(query: let query, name: let name, humanReadableDescription: let description):
        return nil
      }
    case .include(_):
      return nil
    case .flavorText(let value):
      return "the flavor text contains “\(value)”"
    case .lore(let value):
      return "the lore includes “\(value)”"
    case .unique(_):
      return nil
    case .watermark(let wm):
      return "the cards have the “\(wm)” watermark"
    case .owned(let quantity, let quantifier):
      return "the number of copies in your collection is \(quantifier.numericHumanReadable) \(quantity)"
    case .new(let value):
      guard let value else { return nil }
      return switch value {
      case .rarity: "the cards were printed at a new rarity"
      case .art: "the cards were printed with new art"
      case .artist: "the cards were illustrated by a new artist"
      case .flavor: "the cards were printed with new flavor text"
      case .frame: "the cards were printed in a new frame"
      case .language: "the cards were printed in a new language"
      }
    case .cheapest(let value):
      return "the card has the lowest \(value.rawValue.uppercased()) price"
    case .artists(let quantifier, let value):
      return "the number of artists \(quantifier) \(value)"
    case .colorCount(let colorChoice, let value, let quantifier):
      return "the number of \(colorChoice == .identity ? "identity " : "")colors \(quantifier == .exactly ? "is" : quantifier.rawValue) \(value)"
    case .devotion(let quantifier, let value):
      return "the card's devotion is \(quantifier.humanReadable) to \(value)"
    case .collectorNumber(let quantifier, let value):
      return "the collector number \(quantifier.rawValue) \(value)"
    case .setType(let value):
      return "the set type is \(value)"
    case .cube(let value):
      return "the card is in the \(value) cube"
    case .frame(let value):
      guard let value else { return nil }
      return switch value {
      case .showcase:
        "the cards have a custom Showcase frame"
      case .extendedart:
        "the cards have an extended art frame"
      default:
        "the cards have the \(value.name) frame"
      }
    case .stamp(let stamp):
      guard let stamp else { return nil }
      return "the cards have the \(stamp.descriptiveString) security stamp"
    case .game(let value):
      guard let value else { return nil }
      return "the card is available on \(value.name)"
    case .prefer(_):
      return nil
    case .art(let value):
      return "the illustration contains “\(value)”"
    case .function(let value):
      return "the card is tagged “\(value)”"
    case .direct(query: let query, name: let name, humanReadableDescription: let description):
      return description
    }
  }
  
  var canBeNegated: Bool {
    switch self {
    case .not(let token):
      return token.canBeNegated
    case .include(_):
      return false
    case .year, .stats, .price, .unique(_), .artists(_, _), .collectorNumber(_, _), .prefer:
      return false
    default:
      return true
    }
  }
}

extension MTGCard {
  var allNames: Set<String> {
    var names: [String?] = [name, flavorName]
    names += cardFaces?.compactMap(\.name) ?? []
    names += cardFaces?.compactMap(\.flavorName) ?? []
    
    return Set(names.compactMap { $0 })
  }
}
