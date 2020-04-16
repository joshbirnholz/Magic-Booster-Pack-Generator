//
//  GenerationController.swift
//  App
//
//  Created by Josh Birnholz on 4/15/20.
//

import Vapor

final class GeneratorController {
	func boosterPack(_ req: Request) throws -> Future<String> {
		if let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters")), count > 1 {
			return try boosterBox(req)
		}
		
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterPack, export: export)
				promise.succeed(result: result)
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
	
	func boosterBox(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters"))
		
		if count == 1 {
			return try boosterPack(req)
		}
		
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterBox, export: export, boxCount: count)
				promise.succeed(result: result)
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
	
	func prereleasePack(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let count = try? req.query.get(Int.self, at: "count")
		
		let includePromo: Bool = (try? req.query.get(Bool.self, at: "promo")) ?? true
		let includeLands: Bool = (try? req.query.get(Bool.self, at: "lands")) ?? true
		let includeSheet: Bool = (try? req.query.get(Bool.self, at: "sheet")) ?? true
		let includeSpindown: Bool = (try? req.query.get(Bool.self, at: "spindown")) ?? true
		let boosterCount = try? req.query.get(Int.self, at: "boosters")
		
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .prereleaseKit, export: export, boxCount: count, prereleaseIncludePromoCard: includePromo, prereleaseIncludeLands: includeLands, prereleaseIncludeSheet: includeSheet, prereleaseIncludeSpindown: includeSpindown, prereleaseBoosterCount: boosterCount)
				promise.succeed(result: result)
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
	
	private static let decoder = JSONDecoder()
	
	struct DeckList: Content {
		var deck: String
	}
	
	func fullDeck(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		
		return try req.content.decode(DeckList.self).flatMap { decklist in
			let promise: Promise<String> = req.eventLoop.newPromise()
			
			DispatchQueue.global().async {
				do {
					let result: String = try deck(decklist: decklist.deck, export: export)
					promise.succeed(result: result)
				} catch {
					promise.fail(error: error)
				}
			}
			
			return promise.futureResult
		}
	}
}
