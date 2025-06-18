//
//  JumpInParser.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 6/18/25.
//

import Foundation
import SwiftSoup

struct JumpInParser {
  struct Card {
    let name: String
    let probability: Double?
  }
  
  struct Packet {
    let name: String
    let setCode: String
    let randomSlots: [[Card]]
    let fixedCards: [String]
  }
  
  private let packets: [Packet]
  
  static let shared: JumpInParser? = .init()
  
  private init?() {
    let url = urlForResource("jump-in-packet-list", withExtension: "html")
    guard
      let data = try? Data(contentsOf: url),
      let html = String(data: data, encoding: .utf8)
    else {
      return nil
    }
    
    do {
      let doc = try SwiftSoup.parse(html)
      let packetElements = try doc.select("div.pack")
      
      self.packets = try packetElements.map { pack in
        let name = try pack.select("h2").first()?.text() ?? "Unknown"
        let setCode = try pack.attr("data-set-code")
        
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
        
        return Packet(name: name, setCode: setCode, randomSlots: randomSlots, fixedCards: fixedCards)
      }
    } catch {
      print("Error setting up JumpInParser: \(error)")
      return nil
    }
  }
  
  func supportedSetCodes() -> [String] {
    Set(packets.map { $0.setCode }).sorted()
  }
  
  func generateDeckList(for setCode: String) -> String? {
    guard let packet = packets.randomElement(where: { $0.setCode.lowercased() == setCode.lowercased() }) else {
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
}
