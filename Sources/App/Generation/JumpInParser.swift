//
//  JumpInParser.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 6/18/25.
//

import Foundation
import SwiftSoup
import Vapor

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
    
    var lines: [String] = []
    
    // Add fixed cards
    for name in packet.fixedCards {
      lines.append("1 \(name)")
    }
    
    // Add one card from each random slot
    for slot in packet.randomSlots {
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
  
  func getAllPackets(_ req: Request) throws -> EventLoopFuture<[Packet]> {
    let promise: EventLoopPromise<[Packet]> = req.eventLoop.makePromise()
    guard let setCode = req.parameters.get("set") else { throw PackError.missingSet }
    
    promise.completeWithTask {
      guard let packets = packets[setCode.lowercased()] else { throw PackError.invalidSet(setCode) }
      return packets.sorted { $0.name < $1.name }
    }
    
    return promise.futureResult
  }
  
  func selectPackets(_ req: Request) throws -> EventLoopFuture<[Packet]> {
    let promise: EventLoopPromise<[Packet]> = req.eventLoop.makePromise()
    guard let setCode = req.parameters.get("set") else { throw PackError.missingSet }
    let firstPack = try? req.query.get(String.self, at: "pack1").uppercased()
    
    promise.completeWithTask {
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
            let mono = packets.removeRandomElement(where: { $0.colors.count == 1 }), let color = mono.colors.first,
            let multi = packets.removeRandomElement(where: { $0.colors.count > 1 && $0.colors.contains(color) }),
            let other = packets.randomElement(where: { Set($0.colors) != Set(mono.colors) && Set($0.colors) != Set(multi.colors) })
          else {
            throw PackError.failedToBuildPack
          }
          
          return [mono, multi, other].shuffled()
        }
      } else {
        guard
          let mono = packets.removeRandomElement(where: { $0.colors.count == 1 }), let color = mono.colors.first,
          let multi = packets.removeRandomElement(where: { $0.colors.count > 1 && $0.colors.contains(color) }),
          let other = packets.randomElement(where: { Set($0.colors) != Set(mono.colors) && Set($0.colors) != Set(multi.colors) })
        else {
          throw PackError.failedToBuildPack
        }
        
        return [mono, multi, other].shuffled()
      }
      
    }
    
    return promise.futureResult
  }
}
