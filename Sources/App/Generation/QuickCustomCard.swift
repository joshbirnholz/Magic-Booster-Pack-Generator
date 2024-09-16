//
//  QuickCustomCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 2/24/21.
//

import Foundation
import Vapor

//struct QuickCustomCard: Codable, Content {
//	var name: String
//	var imageURL: URL?
//	var backURL: URL?
//	var card: MTGCard?
//}
//
//fileprivate struct QuickCustomCardList: Codable {
//	let cards: [QuickCustomCard]
//}
//
//final class CustomCards {
//	static let shared = CustomCards()
//	
//	private init() {
//		DispatchQueue.global(qos: .background).async {
//			do {
//				try self.load()
//			} catch {
//				print("Error loading custom cards", error)
//			}
//		}
//	}
//	
//	private var cards: [String: MTGCard] = [:]
//	
//	var isFinishedLoading = false {
//    didSet {
//      print("Loaded \(cards.count) custom cards")
//    }
//	}
//  
//  var draftMancerOutput: String? {
//    let draftmancerCards: [DraftmancerCard] = cards.values
//      .sorted(on: \.collectorNumber) {
//      $0.compare($1, options: .numeric) == .orderedDescending
//    }
//      .map(DraftmancerCard.init(mtgCard:))
//    
//    let encoder = JSONEncoder()
//    encoder.outputFormatting = .prettyPrinted
//    encoder.keyEncodingStrategy = .convertToSnakeCase
//    
//    if let data = try? encoder.encode(draftmancerCards), let string = String(data: data, encoding: .utf8) {
//      return "[CustomCards]\n" + string + "\n[DefaultSlot]\n"
//    }
//    
//    return nil
//  }
//	
//	let cardList: Result<[QuickCustomCard], Error> = {
//		return Result {
//			let url: URL = {
//				#if canImport(Vapor)
//				let directory = DirectoryConfiguration.detect()
//				let configDir = "Sources/App/Generation"
//				return URL(fileURLWithPath: directory.workingDirectory)
//					.appendingPathComponent(configDir, isDirectory: true)
//					.appendingPathComponent("customcards.json", isDirectory: false)
//				#else
//				return Bundle.main.url(forResource: "customcards", withExtension: "json")
//				#endif
//			}()
//			
//			let decoder = JSONDecoder()
//			let data = try Data(contentsOf: url)
//			let cardList = try decoder.decode(QuickCustomCardList.self, from: data).cards
//			return cardList
//		}
//	}()
//	
//	private func load() throws {
//		guard !isFinishedLoading else { return }
//		defer {
//			isFinishedLoading = true
//		}
//		
//		let cardList = try self.cardList.get()
//		
//		let identifiers: [MTGCardIdentifier] = Array(Set(cardList.compactMap { card in
//			guard card.card == nil else { return nil }
//			return MTGCardIdentifier.name(card.name)
//		}))
//		
//		let collections: [Swiftfall.CardCollectionList] = try identifiers.chunked(by: 75).compactMap {
//			do {
//				return try Swiftfall.getCollection(identifiers: $0)
//			} catch {
//				print(error)
//				throw error
//			}
//		}
//		let notFound = collections.compactMap(\.notFound).joined()
//		if !notFound.isEmpty {
//			print("Failed to load custom cards with identifiers:", notFound)
//		}
//		print("Found all custom cards")
//		
//		let foundCards = collections.map(\.data).joined().map(MTGCard.init)
//		
//		for (index, card) in cardList.enumerated() {
//			let collectorNumber = String(index+1)
//			
//			if var card = card.card {
//				card.collectorNumber = collectorNumber
//				card.set = "CUSTOM"
//				self.cards[collectorNumber] = card
//			} else if let imageURL = card.imageURL, var foundCard = foundCards.first(where: { $0.name == card.name }) {
//				if let backURL = card.backURL, var faces = foundCard.cardFaces {
//					faces[0].imageUris = [
//						"normal": imageURL,
//						"large": imageURL
//					]
//					faces[1].imageUris = [
//						"normal": backURL,
//						"large": backURL
//					]
//					foundCard.cardFaces = faces
//				} else {
//					foundCard.imageUris = [
//						"normal": imageURL,
//						"large": imageURL
//					]
//				}
//				foundCard.collectorNumber = collectorNumber
//				foundCard.set = "CUSTOM"
//				self.cards[collectorNumber] = foundCard
//			}
//		}
//	}
//	
//	func card(with identifier: MTGCardIdentifier) -> MTGCard? {
//		while !isFinishedLoading { }
//		switch identifier {
//		case .name(let name), .nameSet(let name, _):
//			if let card = cards.sorted(on: \.key, by: { Int($0)! > Int($1)! }).first(where: { $0.value.name?.lowercased() == name.lowercased() })?.value {
//				return card
//			} else {
//				return cards.sorted(on: \.key, by: { Int($0)! > Int($1)! }).first(where: { $0.value.name?.lowercased().hasPrefix(name.lowercased()) == true })?.value
//			}
//		case .collectorNumberSet(let collectorNumber, _, _):
//			guard let number = Int(collectorNumber) else { return nil }
//			return cards[String(number)]
//		default:
//			return nil
//		}
//	}
//  
//  struct CustomCardListResponse: JSONResponseEncodable {
//    let cards: [QuickCustomCard]
//    let draftmancerOutput: String?
//  }
//	
//	func getCustomCards(_ req: Request) throws -> EventLoopFuture<CustomCardListResponse> {
//    return req.eventLoop.makeCompletedFuture {
//      while !self.isFinishedLoading { }
//      
//      let cardList = try self.cardList.get()
//      let draftMancerOutput = self.draftMancerOutput
//      
//      return CustomCardListResponse(
//        cards: cardList,
//        draftmancerOutput: draftMancerOutput
//      )
//    }
//	}
//}

extension Encodable {
  func encodeResponse(for request: Vapor.Request) -> NIOCore.EventLoopFuture<Vapor.Response> {
    return request.eventLoop.makeCompletedFuture {
      var headers = HTTPHeaders()
      headers.add(name: .contentType, value: "application/json")
      
      let encoder = JSONEncoder()
      let data = try encoder.encode(self)
      let string = String.init(data: data, encoding: .utf8) ?? ""
      
      return .init(
        status: .ok, headers: headers, body: .init(string: string)
      )
    }
  }
}

protocol JSONResponseEncodable: Encodable, ResponseEncodable {
  
}

public extension EventLoop {
  func makeCompletedFuture<Success>(withResultOf body: () throws -> Success) -> EventLoopFuture<Success> {
    makeCompletedFuture(Result {
      return try body()
    })
  }
}
