//
//  Swiftfall+GetCollection.swift
//  Magic Board
//
//  Created by Josh Birnholz on 2/20/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Swiftfall {
	
	// struct which contrains a list of cards
    public struct CardCollectionList: Codable, CustomStringConvertible, Sendable {
        // an array of Cards
        public let data: [Card]
		
		public let warnings: [String]?
		
		public let notFound: [MTGCardIdentifier]?
        
        // prints each set
        public var description: String {
            var text = ""
            var i = 0
            for card in data {
                text += "Card Number: \(i)\n"
                text += card.description
                text += "\n"
                i = i + 1
            }
            return text
        }
    }	
}

extension Sequence {
  func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
    var values: [T] = []

    for element in self {
      try await values.append(transform(element))
    }

    return values
  }
  
  func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
    var values: [T] = []

    for element in self {
      if let value = try await transform(element) {
        values.append(value)
      }
    }

    return values
  }
}
