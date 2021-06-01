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
	
	let name: String?
	let url: URL
	let front: URL
	let back: URL?
	let ids: [String]
	let revision: Int?
	let type: DualType?
	let ci: String
	let theme: String?
}

final class MyDecks {
	static let shared = MyDecks()
	
	private init() { }
	
	let deckURLs: Result<[MyDeck], Error> = Result {
		let url: URL = {
			   #if canImport(Vapor)
			   let directory = DirectoryConfig.detect()
			   let configDir = "Sources/App/Generation"
			   return URL(fileURLWithPath: directory.workDir)
				   .appendingPathComponent(configDir, isDirectory: true)
				   .appendingPathComponent("mydecks.json", isDirectory: false)
			   #else
			   return Bundle.main.url(forResource: "mydecks", withExtension: "json")
			   #endif
		   }()
		   
		   let decoder = JSONDecoder()
		   let data = try Data(contentsOf: url)
		   
		   let urls = try decoder.decode([MyDeck].self, from: data)
		   return urls
	   }
	
	func getDecks(_ req: Request) throws -> EventLoopFuture<[MyDeck]> {
		let promise: Promise<[MyDeck]> = req.eventLoop.newPromise()

		do {
			let cardList = try self.deckURLs.get()
			promise.succeed(result: cardList)
		} catch {
			promise.fail(error: error)
		}

		return promise.futureResult
	}
}
