//
//  GenerationController.swift
//  App
//
//  Created by Josh Birnholz on 4/15/20.
//

import Vapor

final class GeneratorController {
	func boosterPack(_ req: Request) throws -> Future<String> {
		let objectStateOnly: Bool = (try? req.query.get(Bool.self, at: "objectonly")) ?? false
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterPack, objectStateOnly: objectStateOnly)
				promise.succeed(result: result)
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
	
	func boosterBox(_ req: Request) throws -> Future<String> {
		let objectStateOnly: Bool = (try? req.query.get(Bool.self, at: "objectonly")) ?? false
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterBox, objectStateOnly: objectStateOnly)
				promise.succeed(result: result)
			} catch {
				promise.fail(error: error)
			}
		}
		
		return promise.futureResult
	}
	
	func prereleasePack(_ req: Request) throws -> Future<String> {
		let objectStateOnly: Bool = (try? req.query.get(Bool.self, at: "objectonly")) ?? false
		
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global().async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .prereleaseKit, objectStateOnly: objectStateOnly)
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
		let objectStateOnly: Bool = (try? req.query.get(Bool.self, at: "objectonly")) ?? false
		
		return try req.content.decode(DeckList.self).flatMap { decklist in
			let promise: Promise<String> = req.eventLoop.newPromise()
			
			DispatchQueue.global().async {
				do {
					let result: String = try deck(decklist: decklist.deck, objectStateOnly: objectStateOnly)
					promise.succeed(result: result)
				} catch {
					promise.fail(error: error)
				}
			}
			
			return promise.futureResult
		}
	}
}
