//
//  JumpInParser.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 6/18/25.
//

import Foundation
import SwiftSoup
import Vapor

struct JumpstartSet: Content {
  let name: String
  let code: String
}

struct JumpInParser {
  struct Card {
    let name: String
    let probability: Double?
  }
  
  struct Packet: Codable, Content, Hashable {
    init(name: String, setCode: String, colors: [MTGColor], randomSlots: [[JumpInParser.Card]], fixedCards: [String]) {
      self.name = name
      self.setCode = setCode
      self.colors = colors
      self.randomSlots = randomSlots
      self.fixedCards = fixedCards
    }
    
    let name: String
    let setCode: String
    let colors: [MTGColor]
    let randomSlots: [[Card]]
    let fixedCards: [String]
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(name)
      hasher.combine(setCode)
      hasher.combine(colors)
    }
    
    static func ==(lhs: Packet, rhs: Packet) -> Bool {
      return lhs.name == rhs.name && lhs.setCode == rhs.setCode && lhs.colors == rhs.colors
    }
    
    enum CodingKeys: String, CodingKey {
      case name
      case setCode
      case colors
    }
    
    func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(name, forKey: .name)
      try container.encode(setCode, forKey: .setCode)
      try container.encode(colors.map(\.rawValue), forKey: .colors)
    }
    
    init(from decoder: any Decoder) throws {
      throw PackError.unsupported
    }
    
    func generateDeckList() -> String {
      var lines: [String] = []
      
      // Add fixed cards
      for name in fixedCards {
        lines.append("1 \(name)")
      }
      
      // Add one card from each random slot
      for slot in randomSlots {
        let total = slot.reduce(0) { $0 + ($1.probability ?? 0) }
        let pick = Double.random(in: 0..<total)
        var cumulative: Double = 0
        
        for card in slot {
          cumulative += card.probability ?? 0
          if pick < cumulative {
            lines.append("1 \(card.name)")
            break
          }
        }
      }
      
      return lines.joined(separator: "\n")
    }
  }
  
  private let packets: [String: [Packet]]
  
  static let shared: JumpInParser = .init()
  
  private init() {
    let url = urlForResource("jump-in-packet-list", withExtension: "html")
    guard
      let data = try? Data(contentsOf: url),
      let html = String(data: data, encoding: .utf8)
    else {
      self.packets = .init()
      return
    }
    
    do {
      let doc = try SwiftSoup.parse(html)
      let packetElements = try doc.select("div.pack")
      
      let allPackets = try packetElements.map { pack in
        let name = try pack.select("h2").first()?.text() ?? "Unknown"
        let setCode = try pack.attr("data-set-code")
        let colorString = try pack.attr("data-colors")  // e.g., "W,U"
        let colors = colorString.split(separator: ",").compactMap { MTGColor(rawValue: String($0)) }
        
        // Random slots
        var randomSlots: [[Card]] = []
        let randomSlotTable = try pack.select("table.table")
        
        for row in try randomSlotTable.select("tr") {
          var cards: [Card] = []
          let cells = try row.select("td").filter { try $0.text() != "- or -" }
          
          for i in stride(from: 0, to: cells.count, by: 2) {
            let percentText = try cells[i].text().replacingOccurrences(of: "%", with: "")
            let probability = Double(percentText.trimmingCharacters(in: .whitespaces))
            let name = try cells[i + 1].select("a").text()
            cards.append(Card(name: name, probability: probability ?? 0))
          }
          
          if !cards.isEmpty {
            randomSlots.append(cards)
          }
        }
        
        // Fixed cards
        var fixedCards: [String] = []
        let cardBlocks = try pack.select("div.card-block")
        
        for block in cardBlocks {
          for li in try block.select("li") {
            let dropRate = try? li.select(".card-drop-rate").first()?.text()
            if dropRate?.contains("%") != true {
              if let name = try li.select("a").first()?.text() {
                fixedCards.append(name)
              }
            }
          }
        }
        
        return Packet(
          name: name,
          setCode: setCode.lowercased(),
          colors: colors,
          randomSlots: randomSlots,
          fixedCards: fixedCards
        )
      }
      
      self.packets = .init(grouping: allPackets, by: \.setCode)
    } catch {
      print("Error setting up JumpInParser: \(error)")
      self.packets = .init()
      return
    }
  }
  
  func supportedSetCodes() -> [String] {
    Array(packets.keys.map { $0.uppercased() })
  }
  
  func generateDeckList(for setCode: String) -> String? {
    guard let packet = packets[setCode.lowercased()]?.randomElement() else {
      return nil
    }
    
    return packet.generateDeckList()
  }
  
  func getAllSets(_ req: Request) async throws -> [String] {
    return Array(packets.keys).map { $0.uppercased() }
  }
  
  func getAllPackets(_ req: Request) async throws -> [Packet] {
    if let setCode = req.parameters.get("set") {
      guard let packets = packets[setCode.lowercased()] else { throw PackError.invalidSet(setCode) }
      return packets.sorted { $0.name < $1.name }
    } else {
      return Array(packets.values.joined()).sorted { $0.name < $1.name }
    }
  }
  
  func selectPackets(_ req: Request) async throws -> [Packet] {
    guard let setCode = req.parameters.get("set") else { throw PackError.missingSet }
    let firstPack = try? req.query.get(String.self, at: "pack1").uppercased()
    
    guard let array = packets[setCode.lowercased()] else { throw PackError.invalidSet(setCode) }
    var packets = Set(array)
    
    if let firstPack {
      guard let pack = packets.first(where: { $0.name == firstPack }) else {
        throw PackError.invalidJumpStartName
      }
      packets.remove(pack)
      
      switch pack.colors.count {
      case 1:
        guard let mono = packets.removeRandomElement(where: { $0.colors.count == 1 }),
              let multi = packets.removeRandomElement(where: { $0.colors.count > 1 && $0.colors.contains(pack.colors[0]) }),
              let other = packets.randomElement(where: {
                if $0.colors.count > 1 && !$0.colors.contains(pack.colors[0]) { return false }
                return true
              })
        else {
          throw PackError.failedToBuildPack
        }
        
        return [mono, multi, other].shuffled()
      case 2:
        guard let firstMono = packets.removeRandomElement(where: { $0.colors == [pack.colors[0]] }),
              let secondMono = packets.removeRandomElement(where: { $0.colors == [pack.colors[1]] }),
              let other = packets.randomElement(where: {
                switch $0.colors.count {
                case 1:
                  return true
                case 2:
                  return Set($0.colors) == Set(pack.colors)
                case 3:
                  return Set(pack.colors).isSubset(of: Set($0.colors))
                default:
                  return false
                }
              })
        else {
          throw PackError.failedToBuildPack
        }
        
        return [firstMono, secondMono, other].shuffled()
      case 3:
        guard let firstMono = packets.removeRandomElement(where: { $0.colors.count == 1 && pack.colors.contains($0.colors[0]) }),
              let secondMono = packets.removeRandomElement(where: { $0.colors.count == 1 && pack.colors.contains($0.colors[0]) && pack.colors != firstMono.colors }),
              let other = packets.removeRandomElement(where: {
                if $0.colors.count > 1 {
                  return Set($0.colors).isSubset(of: Set(pack.colors))
                }
                return true
              })
        else {
          throw PackError.failedToBuildPack
        }
        
        return [firstMono, secondMono, other].shuffled()
      default:
        guard
          let mono = packets.removeRandomElement(where: { $0.colors.count == 1 }),
          let multi = packets.removeRandomElement(where: { $0.colors.count > 1 && Set($0.colors) != Set(mono.colors) }),
          let other = packets.randomElement(where: { Set($0.colors) != Set(mono.colors) && Set($0.colors) != Set(multi.colors) })
        else {
          throw PackError.failedToBuildPack
        }
        
        return [mono, multi, other].shuffled()
      }
    } else {
      guard
        let mono = packets.removeRandomElement(where: { $0.colors.count == 1 }),
        let multi = packets.removeRandomElement(where: { $0.colors.count > 1 && Set($0.colors) != Set(mono.colors) }),
        let other = packets.randomElement(where: { Set($0.colors) != Set(mono.colors) && Set($0.colors) != Set(multi.colors) })
      else {
        throw PackError.failedToBuildPack
      }
      
      return [mono, multi, other].shuffled()
    }
  }
}


// MARK: Add Lands

extension JumpInParser {

  func jumpinDeck(_ req: Request) async throws -> String {
    let set1 = try req.query.get(String.self, at: "set1").uppercased()
    let set2 = try req.query.get(String.self, at: "set2").uppercased()
    let pack1 = try req.query.get(String.self, at: "pack1").uppercased()
    let pack2 = try req.query.get(String.self, at: "pack2").uppercased()
    
    let format = try? req.query.get(String.self, at: "format")

    let export = req.query.getBoolValue(at: "export") ?? true

    guard
      let packetA = packets.values.joined().first(where: { $0.name == pack1 && $0.setCode.uppercased() == set1 }),
      let packetB = packets.values.joined().first(where: { $0.name == pack2 && $0.setCode.uppercased() == set2 })
    else {
      throw PackError.invalidJumpStartName
    }

    let fullDecklist = try await addLands(packetA: packetA, set1: set1, packetB: packetB, set2: set2)

    if format == "list" {
      return fullDecklist
    }
    
    return try await deck(.arena(fullDecklist), export: export, autofix: true, outputName: "\(packetA.name) + \(packetB.name)", direct: true)
  }

  func addLands(packetA: Packet, set1: String, packetB: Packet, set2: String) async throws -> String {
    var deckCards = packetA.generateDeckList().split(separator: "\n").map { "\($0) (\(packetA.setCode.uppercased()))" }
    + packetB.generateDeckList().split(separator: "\n").map { "\($0) (\(packetB.setCode.uppercased()))" }

    var cardCounts = Array(DeckParser.parse(deckList: deckCards.joined(separator: "\n"), autofix: true).map { $0.cardCounts }.joined())
    let identifiers = cardCounts.map(\.identifier)
    let collection = try await Swiftfall.getCollection(identifiers: identifiers).data.map(MTGCard.init)
    
    var totalQuantity: Int {
      cardCounts.reduce(0, { $0 + $1.count })
    }

    let (basics, duals) = generateLandFixing(packetA: packetA, packetB: packetB, deckCards: collection)
    
    let availableDuals: [MTGCard] = try await {
      let duals = try await Swiftfall.getCards(query: "e:\(set1) t:land r:c produces=2").data.map(MTGCard.init)
      if duals.count == 10 {
        return duals
      } else {
        return try await Swiftfall.getCards(query: "e:dmu t:land r:c produces=2").data.map(MTGCard.init)
      }
    }()

    let hasFiveColor = collection.contains { card in
      guard card.typeLine.contains("Land"), let mana = card.producedMana else { return false }
      return Set(mana).count >= 5
    }

    let fiveColor: MTGCard? = hasFiveColor ? nil : try await {
      let first = try await Swiftfall.getCards(query: "e:\(set1) t:land r:c produces:5").data
      if first.count == 1 {
        return MTGCard(first[0])
      }
      let second = try await Swiftfall.getCards(query: "e:\(set2) t:land r:c produces:5").data
      if second.count == 1 {
        return MTGCard(second[0])
      }
      let wilds = try await Swiftfall.getCard(exact: "Evolving Wilds")
      return MTGCard(wilds)
    }()
    
    for (colors, count) in duals {
      guard totalQuantity < 40 else { break }
      let count = min(count, 40 - totalQuantity)
      let card = availableDuals.first(where: { Set($0.producedMana ?? []) == Set(colors) }) ?? fiveColor
      if let card = card {
        cardCounts.append(.init(identifier: .nameSet(name: card.name!, set: card.set.uppercased()), count: count))
        deckCards.append("\(count) \(card.name!) (\(card.set.uppercased()))")
      }
    }

    for (color, count) in basics.sorted(by: { $0.value < $1.value }) {
      guard let land = color.land else { continue }
      guard totalQuantity < 40 else { break }
      // In a dual color deck, at least five basics of each color are added.
      let count = min(Set(packetA.colors + packetB.colors).count == 2 ? max(count, 5) : count, 40 - totalQuantity)
      cardCounts.append(.init(identifier: .nameSet(name: land.capitalized, set: set1.uppercased()), count: count))
      deckCards.append("\(count) \(land.capitalized) (\(set1.uppercased()))")
    }
    
    
    for cardCount in cardCounts {
      print(cardCount)
    }
    
    print(totalQuantity)

    return deckCards.joined(separator: "\n")
  }

  func generateLandFixing(
    packetA: Packet,
    packetB: Packet,
    deckCards: [MTGCard]
  ) -> (basics: [MTGColor: Int], duals: [Set<MTGColor>: Int]) {
    var duals: [Set<MTGColor>: Int] = [:]
    var basics: [MTGColor: Int] = [:]

    let colorsA = Set(packetA.colors)
    let colorsB = Set(packetB.colors)
    let allColors = colorsA.union(colorsB)

    func addTriColorDuals(_ colors: Set<MTGColor>) {
      let array = Array(colors)
      for i in 0..<array.count {
        for j in i+1..<array.count {
          duals[Set([array[i], array[j]]), default: 0] += 1
        }
      }
    }

    func addTwoColorDuals(_ colors: Set<MTGColor>) {
      if colors.count == 2 {
        duals[colors, default: 0] += 2
      }
    }

    if colorsA.count == 1, colorsB.count == 1, allColors.count == 2 {
      addTwoColorDuals(allColors)
    }

    for packet in [packetA, packetB] {
      let colors = Set(packet.colors)
      if colors.count == 2 {
        addTwoColorDuals(colors)
      } else if colors.count == 3 {
        addTriColorDuals(colors)
      }
    }

    if colorsA.count == 1 && colorsB.count == 2 && colorsA.isDisjoint(with: colorsB) {
      for color in colorsB {
        duals[Set([color, colorsA.first!]), default: 0] += 1
      }
    } else if colorsB.count == 1 && colorsA.count == 2 && colorsB.isDisjoint(with: colorsA) {
      for color in colorsA {
        duals[Set([color, colorsB.first!]), default: 0] += 1
      }
    }

    let totalDuals = duals.values.reduce(0, +)
    let totalBasics = max(16 - totalDuals, 0)

    var colorNeeds: [MTGColor: Int] = [:]
    for card in deckCards {
      for symbol in card.manaCost?.components(separatedBy: CharacterSet(charactersIn: "{}")).filter({ !$0.isEmpty }) ?? [] {
        if let color = MTGColor(rawValue: symbol) {
          colorNeeds[color, default: 0] += 1
        }
      }
      if let oracle = card.oracleText {
        for token in oracle.components(separatedBy: CharacterSet(charactersIn: "{}")).filter({ !$0.isEmpty }) {
          if let color = MTGColor(rawValue: token) {
            colorNeeds[color, default: 0] += 1
          }
        }
      }
    }

    let totalWeight = colorNeeds.values.reduce(0, +)

    if totalWeight > 0 {
      var allocated = 0
      for (color, weight) in colorNeeds {
        let share = Int(round(Double(weight) / Double(totalWeight) * Double(totalBasics)))
        basics[color] = share
        allocated += share
      }

      while allocated < totalBasics {
        if let color = allColors.first {
          basics[color, default: 0] += 1
          allocated += 1
        }
      }

      while allocated > totalBasics {
        if let color = basics.first(where: { $0.value > 0 })?.key {
          basics[color]! -= 1
          allocated -= 1
        }
      }
    } else {
      let even = totalBasics / allColors.count
      for color in allColors {
        basics[color] = even
      }
    }

    return (basics, duals)
  }

}
