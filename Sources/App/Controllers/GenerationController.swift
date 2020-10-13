//
//  GenerationController.swift
//  App
//
//  Created by Josh Birnholz on 4/15/20.
//

import Vapor
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class GeneratorController {
	func boosterPack(_ req: Request) throws -> Future<String> {
		if let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters")), count > 1 {
			return try boosterBox(req)
		}
		
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let includeExtendedArt: Bool = (try? req.query.get(Bool.self, at: "extendedart")) ?? true
		let set = try req.parameters.next(String.self)
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		let includeBasicLands: Bool = (try? req.query.get(Bool.self, at: "lands")) ?? true
		let includeTokens: Bool = (try? req.query.get(Bool.self, at: "tokens")) ?? true
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterPack, export: export, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, specialOptions: specialOptions, autofixDecklist: false)
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
		let includeBasicLands: Bool = (try? req.query.get(Bool.self, at: "lands")) ?? true
		let includeTokens: Bool = (try? req.query.get(Bool.self, at: "tokens")) ?? true
		
		if count == 1 {
			return try boosterPack(req)
		}
		
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterBox, export: export, boxCount: count, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, specialOptions: specialOptions, autofixDecklist: false)
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
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .prereleaseKit, export: export, boxCount: count, prereleaseIncludePromoCard: includePromo, prereleaseIncludeLands: includeLands, prereleaseIncludeSheet: includeSheet, prereleaseIncludeSpindown: includeSpindown, prereleaseBoosterCount: boosterCount, includeExtendedArt: includeExtendedArt, includeBasicLands: true, includeTokens: true, specialOptions: specialOptions, autofixDecklist: false)
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
	
	fileprivate func deckFromURL(_ deckURL: URL, _ export: Bool, _ cardBack: URL?, autofix: Bool, _ promise: EventLoopPromise<String>) throws -> EventLoopFuture<String> {
		guard let components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else {
			throw PackError.invalidURL
		}
		
		switch components.host {
		case "deckstats.net":
			var pathComponents = deckURL.pathComponents
			guard let deckID = pathComponents.removeLast().components(separatedBy: "-").first, let ownerID = pathComponents.last else {
				throw PackError.invalidURL
			}
			
			guard let decklistURL = URL(string: "https://deckstats.net/api.php?action=get_deck&id_type=saved&owner_id=\(ownerID)&id=\(deckID)&response_type=list") else {
				throw PackError.invalidURL
			}
			
			DispatchQueue.global().async {
				let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
				URLSession.shared.dataTask(with: request) { data, response, error in
					do {
						guard let data = data else {
							throw error!
						}
						
						struct DeckStatsList: Decodable {
							var success: Bool
							var list: String
						}
						
						let decoder = JSONDecoder()
						let deckList = try decoder.decode(DeckStatsList.self, from: data)
						
						DispatchQueue(label: "decklist").async {
							do {
								
								let result: String = try deck(decklist: deckList.list, format: .deckstats, export: export, cardBack: cardBack, allowRetries: autofix)
								print("Success")
								promise.succeed(result: result)
							} catch let error as Debuggable {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									promise.succeed(result: string)
								} catch {
									promise.fail(error: error)
								}
							} catch {
								promise.fail(error: error)
							}
						}
					} catch let error as Debuggable {
						struct ErrorMessage: Codable {
							var error: String
						}
						
						let encoder = JSONEncoder()
						let errorMessage = ErrorMessage(error: error.reason)
						do {
							let data = try encoder.encode(errorMessage)
							let string = String(data: data, encoding: .utf8)!
							promise.succeed(result: string)
						} catch {
							promise.fail(error: error)
						}
					} catch {
						promise.fail(error: error)
					}
				}.resume()
			}
		case "tappedout.net":
			DispatchQueue.global().async {
				let request = URLRequest(url: deckURL, cachePolicy: .reloadIgnoringLocalCacheData)
				URLSession.shared.dataTask(with: request) { data, response, error in
					do {
						if let response = response as? HTTPURLResponse, response.statusCode == 404 {
							throw PackError.privateDeck
						}
						
						guard let data = data, let page = String(data: data, encoding: .utf8) else {
							throw PackError.invalidURL
						}
						
						guard let arenaDecklist = page.matches(forRegex: #"<textarea id="mtga-textarea">(.*)<\/textarea>"#, options: .dotMatchesLineSeparators).first?.groups.first?.value else {
							throw PackError.invalidURL
						}
						
						DispatchQueue(label: "decklist").async {
							do {
								let result: String = try deck(decklist: arenaDecklist, format: .arena, export: export, cardBack: cardBack, allowRetries: autofix)
								print("Success")
								promise.succeed(result: result)
							} catch let error as Debuggable {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									promise.succeed(result: string)
								} catch {
									promise.fail(error: error)
								}
							} catch {
								promise.fail(error: error)
							}
						}
					} catch let error as Debuggable {
						struct ErrorMessage: Codable {
							var error: String
						}
						
						let encoder = JSONEncoder()
						let errorMessage = ErrorMessage(error: error.reason)
						do {
							let data = try encoder.encode(errorMessage)
							let string = String(data: data, encoding: .utf8)!
							promise.succeed(result: string)
						} catch {
							promise.fail(error: error)
						}
					} catch {
						promise.fail(error: error)
					}
				}.resume()
			}
		case "www.mtggoldfish.com":
			DispatchQueue.global().async {
				let request = URLRequest(url: deckURL, cachePolicy: .reloadIgnoringLocalCacheData)
				URLSession.shared.dataTask(with: request) { data, response, error in
					do {
						if let response = response as? HTTPURLResponse, response.statusCode == 404 {
							throw PackError.privateDeck
						}
						
						guard let data = data, let page = String(data: data, encoding: .utf8) else {
							throw PackError.invalidURL
						}
						
						guard let arenaDownloadLink = page.matches(forRegex: #"<a class="btn btn-secondary deck-tools-btn" href="(\/deck\/arena_download\/.+)">"#).first?.groups.first?.value, let arenaDownloadURL = URL(string: "https://www.mtggoldfish.com" + arenaDownloadLink) else {
							throw PackError.invalidURL
						}
						
						let arenaDownloadRequest = URLRequest(url: arenaDownloadURL, cachePolicy: .reloadIgnoringLocalCacheData)
						URLSession.shared.dataTask(with: arenaDownloadRequest) { data, response, error in
							do {
								guard let data = data, let page = String(data: data, encoding: .utf8) else {
									throw PackError.invalidURL
								}
								
								guard let decklist = page.matches(forRegex: #"<textarea class='copy-paste-box'>(.*)<\/textarea>"#, options: .dotMatchesLineSeparators).first?.groups.first?.value.decodingHTMLEntities else {
									throw PackError.invalidURL
								}
								
								DispatchQueue(label: "decklist").async {
									do {
										let result: String = try deck(decklist: decklist, format: .arena, export: export, cardBack: cardBack, allowRetries: autofix)
										print("Success")
										promise.succeed(result: result)
									} catch let error as Debuggable {
										struct ErrorMessage: Codable {
											var error: String
										}
										
										let encoder = JSONEncoder()
										let errorMessage = ErrorMessage(error: error.reason)
										do {
											let data = try encoder.encode(errorMessage)
											let string = String(data: data, encoding: .utf8)!
											promise.succeed(result: string)
										} catch {
											promise.fail(error: error)
										}
									} catch {
										promise.fail(error: error)
									}
								}
								
							} catch let error as Debuggable {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									promise.succeed(result: string)
								} catch {
									promise.fail(error: error)
								}
							} catch {
								promise.fail(error: error)
							}
						}.resume()
//
//						DispatchQueue(label: "decklist").async {
//							do {
//								let result: String = try deck(decklist: arenaDecklist, format: .arena, export: export, cardBack: cardBack, allowRetries: autofix)
//								print("Success")
//								promise.succeed(result: result)
//							} catch let error as PackError {
//								struct ErrorMessage: Codable {
//									var error: String
//								}
//
//								let encoder = JSONEncoder()
//								let errorMessage = ErrorMessage(error: error.reason)
//								do {
//									let data = try encoder.encode(errorMessage)
//									let string = String(data: data, encoding: .utf8)!
//									promise.succeed(result: string)
//								} catch {
//									promise.fail(error: error)
//								}
//							} catch {
//								promise.fail(error: error)
//							}
//						}
					} catch let error as Debuggable {
						struct ErrorMessage: Codable {
							var error: String
						}
						
						let encoder = JSONEncoder()
						let errorMessage = ErrorMessage(error: error.reason)
						do {
							let data = try encoder.encode(errorMessage)
							let string = String(data: data, encoding: .utf8)!
							promise.succeed(result: string)
						} catch {
							promise.fail(error: error)
						}
					} catch {
						promise.fail(error: error)
					}
				}.resume()
			}
		default:
			promise.fail(error: PackError.invalidURL)
		}
		
		return promise.futureResult
	}
	
	func deckstatsDeck(_ req: Request) throws -> Future<String> {
		// https://deckstats.net/api.php?action=get_deck&id_type=saved&owner_id=149419&id=1676048&response_type=list
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let autofix: Bool = (try? req.query.get(Bool.self, at: "autofix")) ?? true
		let cardBack: URL? = (try? req.query.get(String.self, at: "back")).flatMap(URL.init(string:))
		
		let deckURLString = try req.parameters.next(String.self)
		guard let deckURL = URL(string: deckURLString) else {
			throw PackError.invalidURL
		}
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		return try deckFromURL(deckURL, export, cardBack, autofix: autofix, promise)
	}
	
	func fullDeck(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let autofix: Bool = (try? req.query.get(Bool.self, at: "autofix")) ?? true
		let cardBack: URL? = (try? req.query.get(String.self, at: "back")).flatMap(URL.init(string:))
		
		return try req.content.decode(DeckList.self).flatMap { decklist in
			let promise: Promise<String> = req.eventLoop.newPromise()
			
			if let url = URL(string: decklist.deck) {
				return try self.deckFromURL(url, export, cardBack, autofix: autofix, promise)
			}
			
			DispatchQueue.global().async {
				do {
					let result: String = try deck(decklist: decklist.deck, export: export, cardBack: cardBack, allowRetries: autofix)
					promise.succeed(result: result)
				} catch let error as Debuggable {
					struct ErrorMessage: Codable {
						var error: String
					}
					
					let encoder = JSONEncoder()
					let errorMessage = ErrorMessage(error: error.reason)
					do {
						let data = try encoder.encode(errorMessage)
						let string = String(data: data, encoding: .utf8)!
						promise.succeed(result: string)
					} catch {
						promise.fail(error: error)
					}
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
		
		DispatchQueue.global(qos: .userInitiated).async {
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
		
		DispatchQueue.global(qos: .userInitiated).async {
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
		
		DispatchQueue.global(qos: .userInitiated).async {
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
	
	func completeToken(_ req: Request) throws -> Future<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let set = try req.parameters.next(String.self)
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let allTokens = try allTokensForSet(setCode: set)
				let token = try singleCompleteToken(tokens: allTokens, export: export)
				promise.succeed(result: token)
			} catch {
				promise.fail(error: error)
			}
			
		}
		
		return promise.futureResult
	}
	
	func landPacks(_ req: Request) throws -> Future<String> {
		let export: Bool = false
		let set: String? = try? req.query.get(String.self, at: "set")
		
		let promise: Promise<String> = req.eventLoop.newPromise()
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				if let set = set {
					let packs = try generate(input: .scryfallSetCode, inputString: set, output: .landPack, export: export, boxCount: nil, prereleaseIncludePromoCard: nil, prereleaseIncludeLands: nil, prereleaseIncludeSheet: nil, prereleaseIncludeSpindown: nil, prereleaseBoosterCount: nil, includeExtendedArt: false, includeBasicLands: true, includeTokens: false, specialOptions: [], cardBack: nil, autofixDecklist: false)
					promise.succeed(result: packs)
				} else {
					let packs = try allLandPacksSingleJSON(setCards: nil, specialOptions: [], export: export)
					promise.succeed(result: packs)
				}
			} catch {
				promise.fail(error: error)
			}
			
		}
		
		return promise.futureResult
	}
}
