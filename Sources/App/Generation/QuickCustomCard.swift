//
//  QuickCustomCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 2/24/21.
//

import Foundation
import Vapor

struct QuickCustomCard: Codable, Content {
	var name: String
	var imageURL: URL?
	var backURL: URL?
	var card: MTGCard?
}

fileprivate struct QuickCustomCardList: Codable {
	let cards: [QuickCustomCard]
}

final class CustomCards {
	static let shared = CustomCards()
	
	private init() {
		do {
			try load()
		} catch {
			print("Error loading custom cards", error)
		}
	}
	
	private var cards: [String: MTGCard] = [:]
	
	var isFinishedLoading = false {
		didSet {
			print("Loaded \(cards.count) custom cards")
		}
	}
	
	let cardList: Result<[QuickCustomCard], Error> = {
		return Result {
			let url: URL = {
				#if canImport(Vapor)
				let directory = DirectoryConfig.detect()
				let configDir = "Sources/App/Generation"
				return URL(fileURLWithPath: directory.workDir)
					.appendingPathComponent(configDir, isDirectory: true)
					.appendingPathComponent("customcards.json", isDirectory: false)
				#else
				return Bundle.main.url(forResource: "customcards", withExtension: "json")
				#endif
			}()
			
			let decoder = JSONDecoder()
			let data = try Data(contentsOf: url)
			let cardList = try decoder.decode(QuickCustomCardList.self, from: data).cards
			return cardList
		}
	}()
	
	private func load() throws {
		guard !isFinishedLoading else { return }
		defer {
			isFinishedLoading = true
		}
		
		let cardList = try self.cardList.get()
		
		let identifiers: [MTGCardIdentifier] = Array(Set(cardList.compactMap { card in
			guard card.card == nil else { return nil }
			return MTGCardIdentifier.name(card.name)
		}))
		
		let collections: [Swiftfall.CardCollectionList] = try identifiers.chunked(by: 75).compactMap {
			do {
				return try Swiftfall.getCollection(identifiers: $0)
			} catch {
				print(error)
				throw error
			}
		}
		let notFound = collections.compactMap(\.notFound).joined()
		if !notFound.isEmpty {
			print("Failed to load custom cards with identifiers:", notFound)
		}
		print("Found all custom cards")
		
		let foundCards = collections.map(\.data).joined().map(MTGCard.init)
		
		for (index, card) in cardList.enumerated() {
			let collectorNumber = String(index+1)
			
			if var card = card.card {
				card.collectorNumber = collectorNumber
				card.set = "CUSTOM"
				self.cards[collectorNumber] = card
			} else if let imageURL = card.imageURL, var foundCard = foundCards.first(where: { $0.name == card.name }) {
				if let backURL = card.backURL, var faces = foundCard.cardFaces {
					faces[0].imageUris = [
						"normal": imageURL,
						"large": imageURL
					]
					faces[1].imageUris = [
						"normal": backURL,
						"large": backURL
					]
					foundCard.cardFaces = faces
				} else {
					foundCard.imageUris = [
						"normal": imageURL,
						"large": imageURL
					]
				}
				foundCard.collectorNumber = collectorNumber
				foundCard.set = "CUSTOM"
				self.cards[collectorNumber] = foundCard
			}
		}
	}
	
	func card(with identifier: MTGCardIdentifier) -> MTGCard? {
		while !isFinishedLoading { }
		switch identifier {
		case .name(let name), .nameSet(let name, _):
			if let card = cards.sorted(on: \.key, by: { Int($0)! > Int($1)! }).first(where: { $0.value.name?.lowercased() == name.lowercased() })?.value {
				return card
			} else {
				return cards.sorted(on: \.key, by: { Int($0)! > Int($1)! }).first(where: { $0.value.name?.lowercased().hasPrefix(name.lowercased()) == true })?.value
			}
		case .collectorNumberSet(let collectorNumber, _, _):
			guard let number = Int(collectorNumber) else { return nil }
			return cards[String(number)]
		default:
			return nil
		}
	}
	
	func getCustomCards(_ req: Request) throws -> EventLoopFuture<[QuickCustomCard]> {
		let promise: Promise<[QuickCustomCard]> = req.eventLoop.newPromise()
		
		while !isFinishedLoading { }
		
		do {
			let cardList = try self.cardList.get()
			promise.succeed(result: cardList)
		} catch {
			promise.fail(error: error)
		}
		
		return promise.futureResult
	}
}
