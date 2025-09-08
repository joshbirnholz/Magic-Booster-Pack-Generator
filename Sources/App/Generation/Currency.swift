//
//  Currency.swift
//  Spellbook
//
//  Created by Josh Birnholz on 6/1/22.
//  Copyright © 2022 iowncode. All rights reserved.
//

import Foundation

public enum Currency: String, CaseIterable, Equatable, Codable {
    case usd
    case eur
    case tix
    
    var humanReadable: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "Euros"
        case .tix: return "MTGO Tickets"
        }
    }
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .tix: return "TIX: "
        }
    }
  
  var systemImageName: String {
    switch self {
    case .usd:
      "dollarsign"
    case .eur:
      "eurosign"
    case .tix:
      "ticket"
    }
  }
}
