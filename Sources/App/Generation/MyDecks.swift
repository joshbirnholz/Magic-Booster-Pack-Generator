//
//  QuickCustomCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 2/24/21.
//

import Foundation
import Vapor

struct MyDeck: Codable, Content {
	enum DualType: String, Codable, Content {
		case dfc, partners
	}
	
	let name: String
	let url: URL
	let front: URL
	let back: URL?
	let ids: [String]
	let revision: Int?
	let type: DualType?
	let ci: String
	let theme: String?
	let comment: String?
    let hide: Bool?
    
    var isVisible: Bool {
        if let hide = hide {
            return !hide
        }
        return true
    }
}

final class MyDecks: Sendable {
	static let shared = MyDecks()
	
	private init() { }
	
    let deckURLs: Result<[MyDeck], Error> = Result {      
        let url = urlForResource("mydecks", withExtension: "json")
        
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: url)
        
        let decks = try decoder.decode([MyDeck].self, from: data)
        return decks.filter {
            $0.isVisible
        }.sorted {
            $0.name < $1.name
        }
    }
    
	func getDecks(_ req: Request) throws -> EventLoopFuture<[MyDeck]> {
		let promise: EventLoopPromise<[MyDeck]> = req.eventLoop.makePromise()

		do {
			let cardList = try self.deckURLs.get()
			promise.succeed(cardList)
		} catch {
			promise.fail(error)
		}

		return promise.futureResult
	}
}
