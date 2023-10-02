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
		DispatchQueue.global(qos: .background).async {
			do {
				try self.load()
			} catch {
				print("Error loading custom cards", error)
			}
		}
	}
	
	private var cards: [String: MTGCard] = [:]
	
	var isFinishedLoading = false {
    didSet {
      print("Loaded \(cards.count) custom cards")
      
      DispatchQueue.global(qos: .background).async {
        if let draftMancerOutput = self.draftMancerOutput {
          print("Draftmancer input:")
          print(draftMancerOutput)
        }
      }
    }
	}
  
  var draftMancerOutput: String? {
    let draftmancerCards: [DraftmancerCard] = cards.values.sorted(on: \.collectorNumber) {
      $0.compare($1, options: .numeric) == .orderedDescending
    }.map(DraftmancerCard.init(mtgCard:))
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.keyEncodingStrategy = .convertToSnakeCase
    
    if let data = try? encoder.encode(draftmancerCards), let string = String(data: data, encoding: .utf8) {
      return "[CustomCards]\n" + string + "\n[DefaultSlot]\n"
    }
    
    return nil
  }
	
	let cardList: Result<[QuickCustomCard], Error> = {
		return Result {
			let url: URL = {
				#if canImport(Vapor)
				let directory = DirectoryConfiguration.detect()
				let configDir = "Sources/App/Generation"
				return URL(fileURLWithPath: directory.workingDirectory)
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
  
  struct CustomCardListResponse: JSONResponseEncodable {
    let cards: [QuickCustomCard]
    let draftmancerOutput: String?
  }
	
	func getCustomCards(_ req: Request) throws -> EventLoopFuture<CustomCardListResponse> {
    return req.eventLoop.makeCompletedFuture {
      while !self.isFinishedLoading { }
      
      let cardList = try self.cardList.get()
      let draftMancerOutput = self.draftMancerOutput
      
      return CustomCardListResponse(
        cards: cardList,
        draftmancerOutput: draftMancerOutput
      )
    }
	}
}

fileprivate struct DraftmancerCard: Codable {
  struct Face: Codable {
    var name: String
    var imageUris: [String: URL]
    var type: String
    var subtypes: [String]?
  }
  
  enum DraftEffect: String, Codable {
    case FaceUp              // Reveal the card to other players and mark the card as face up. Important note: Necessary for most 'UsableEffects" to function correctly!.
    case Reveal              // Reveal the card to other players
    case NotePassingPlayer   // Note the previous player's name on the card.
    case NoteDraftedCards    // Note the number of cards drafted this round, including this card.
    case ChooseColors        // Note colors chosen by your neighbors and you.
    case AetherSearcher      // Reveal and note the next drafted card.
    case CanalDredger        // The last card of each booster is passed to you.
    case ArchdemonOfPaliano  // Pick the next 3 cards randomly.
    
    // Optional on pick effects:
    case LoreSeeker          // "You may add a booster pack to the draft".
    
    // Usable effects (when the card is already in the player's pool):
    case RemoveDraftCard     // Remove the picked card(s) from the draft and associate them with the card.
    case CogworkLibrarian    // Replace this card in a pack for an additional pick.
    case AgentOfAcquisitions // Pick the whole booster, skip until next round.
    case LeovoldsOperative   // Pick an additional card, skip the next booster.
    case NoteCardName        // Note the picked card's name on the card.
    case NoteCreatureName    // Note the picked creature's name on the card.
    case NoteCreatureTypes   // Note the picked creature's types on the card.
  }
  
  var name: String
  var manaCost: String
  var type: String
  var imageUris: [String: URL]
  var colors: [String]?
  var printedNames: [String: URL]?
  var set: String?
  var collectorNumber: String?
  var rarity: String?
  var subtypes: [String]?
  var rating: Int?
  var layout: String?
  var back: Face?
  var relatedCards: [Face]?
  var draftEffects: [DraftEffect]?
  
  init(mtgCard: MTGCard) {
    self.name = mtgCard.name ?? ""
    self.manaCost = mtgCard.manaCost ?? ""
    var types = (mtgCard.typeLine ?? "").components(separatedBy: " — ")
    self.type = types.removeFirst()
    self.subtypes = types.first?.components(separatedBy: " ")
    self.set = mtgCard.set
    self.collectorNumber = mtgCard.collectorNumber
    self.rarity = nil
    self.layout = mtgCard.layout
    self.back = nil
    self.relatedCards = mtgCard.allParts?.compactMap {
      guard
        $0.name != mtgCard.name,
        let id = $0.scryfallID,
        let card = try? Swiftfall.getCard(id: id.uuidString)
      else { return nil }
      
      let mtgCard = MTGCard(card)
      var types = (mtgCard.typeLine ?? "").components(separatedBy: " — ")
      let type = types.removeFirst()
      let subtypes = types.first?.components(separatedBy: " ")
      let imageUris = {
        if let url = mtgCard.imageUris?["large"] {
          return ["en": url]
        } else {
          return [:]
        }
      }()
      
      return Face(
        name: mtgCard.name ?? "",
        imageUris: imageUris,
        type: type,
        subtypes: subtypes
      )
    }
    self.draftEffects = nil
    
    if let url = mtgCard.imageUris?["large"] {
      self.imageUris = ["en": url]
    } else {
      self.imageUris = [:]
    }
    
    self.colors = mtgCard.colors?.compactMap { $0.rawValue }
    self.printedNames = nil
    self.rating = nil
  }
}

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
