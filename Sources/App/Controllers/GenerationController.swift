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
		let includeExtendedArt: Bool = (try? req.query.get(Bool.self, at: "extendedart")) ?? true
		let set = try req.parameters.next(String.self)
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterPack, export: export, includeExtendedArt: includeExtendedArt, specialOptions: specialOptions)
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
		let includeExtendedArt: Bool = (try? req.query.get(Bool.self, at: "extendedart")) ?? true
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		
		if count == 1 {
			return try boosterPack(req)
		}
		
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterBox, export: export, boxCount: count, includeExtendedArt: includeExtendedArt, specialOptions: specialOptions)
				promise.succeed(result: result)
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
	
	func prereleasePack(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let includeExtendedArt: Bool = (try? req.query.get(Bool.self, at: "extendedart")) ?? true
		let count = try? req.query.get(Int.self, at: "count")
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		
		let includePromo: Bool = (try? req.query.get(Bool.self, at: "promo")) ?? true
		let includeLands: Bool = (try? req.query.get(Bool.self, at: "lands")) ?? true
		let includeSheet: Bool = (try? req.query.get(Bool.self, at: "sheet")) ?? true
		let includeSpindown: Bool = (try? req.query.get(Bool.self, at: "spindown")) ?? true
		let boosterCount = try? req.query.get(Int.self, at: "boosters")
		
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .prereleaseKit, export: export, boxCount: count, prereleaseIncludePromoCard: includePromo, prereleaseIncludeLands: includeLands, prereleaseIncludeSheet: includeSheet, prereleaseIncludeSpindown: includeSpindown, prereleaseBoosterCount: boosterCount, includeExtendedArt: includeExtendedArt, specialOptions: specialOptions)
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
	
	func singleCardNamed(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let facedown: Bool = (try? req.query.get(Bool.self, at: "facedown")) ?? false
		
		let fuzzy = try? req.query.get(String.self, at: "fuzzy")
		let exact = try? req.query.get(String.self, at: "exact")
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				if let fuzzy = fuzzy {
					let result = try singleCardFuzzy(name: fuzzy, facedown: facedown, export: export)
					promise.succeed(result: result)
				} else if let exact = exact {
					let result = try singleCardExact(name: exact, facedown: facedown, export: export)
					promise.succeed(result: result)
				} else {
					throw PackError.noName
				}
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
	
	func singleCard(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let facedown: Bool = (try? req.query.get(Bool.self, at: "facedown")) ?? false
		
		let code = try req.parameters.next(String.self)
		let number = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try singleCardCodeNumber(code: code, number: number, facedown: facedown, export: export)
				promise.succeed(result: result)
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
	
	func singleCardRandom(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let facedown: Bool = (try? req.query.get(Bool.self, at: "facedown")) ?? false
		
		let query = try? req.query.get(String.self, at: "q")
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				if let query = query {
					let result = try singleCardScryfallQuery(query: query, facedown: facedown, export: export)
					promise.succeed(result: result)
				} else {
					let result = try singleCardRand(facedown: facedown, export: export)
					promise.succeed(result: result)
				}
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
}
