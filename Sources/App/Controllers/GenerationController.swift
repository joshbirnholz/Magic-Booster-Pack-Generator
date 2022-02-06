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

public enum OutputFormat: String, CaseIterable {
	case tts, cardlist, json
	
	static var `default`: OutputFormat {
		allCases.first!
	}
}

final class GeneratorController {
	func boosterPack(_ req: Request) throws -> EventLoopFuture<String> {
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		if let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters")), count > 1 {
			return try boosterBox(req)
		}

		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let includeExtendedArt: Bool = (try? req.query.get(Bool.self, at: "extendedart")) ?? true
		guard let set = req.parameters.get("set") else {
			promise.fail(PackError.missingSet)
			return promise.futureResult
		}
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		let includeBasicLands: Bool = (try? req.query.get(Bool.self, at: "lands")) ?? true
		let includeTokens: Bool = (try? req.query.get(Bool.self, at: "tokens")) ?? true
		let outputFormat = (try? req.query.get(String.self, at: "outputformat")).flatMap(OutputFormat.init(rawValue:)) ?? .default
		let seed: Seed? = (try? req.query.get(String.self, at: "seed")).flatMap { seed in
			let components = seed.components(separatedBy: "-")
			let code = components[0]
			let name = components[1]
			return SeedOptions.shared.seedOptions(forSetCode: code).first(where: { $0.name == name })
		}

		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterPack, export: export, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat, seed: seed)
				promise.succeed(result)
			} catch {
				promise.fail(error)
			}
		}

		return promise.futureResult
	}
	
	func boosterBox(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters"))
		let includeExtendedArt: Bool = (try? req.query.get(Bool.self, at: "extendedart")) ?? true
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		let includeBasicLands: Bool = (try? req.query.get(Bool.self, at: "lands")) ?? true
		let includeTokens: Bool = (try? req.query.get(Bool.self, at: "tokens")) ?? true
		let outputFormat = (try? req.query.get(String.self, at: "outputformat")).flatMap(OutputFormat.init(rawValue:)) ?? .default

		if count == 1 {
			return try boosterPack(req)
		}
		
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()

//		let set = try req.parameters.next(String.self)
		guard let set = req.parameters.get("set") else {
			promise.fail(PackError.missingSet)
			return promise.futureResult
		}

		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .boosterBox, export: export, boxCount: count, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat)
				promise.succeed(result)
			} catch {
				promise.fail(error)
			}
		}

		return promise.futureResult
	}
	
//	func commanderBoxingLeagueBox(_ req: Request) throws -> EventLoopFuture<String> {
//		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
//		let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters"))
//		let includeExtendedArt: Bool = (try? req.query.get(Bool.self, at: "extendedart")) ?? true
//		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
//		let outputFormat = (try? req.query.get(String.self, at: "outputformat")).flatMap(OutputFormat.init(rawValue:)) ?? .default
//
//		let set = try req.parameters.next(String.self)
//
//		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
//
//		DispatchQueue.global(qos: .userInitiated).async {
//			do {
//				let result = try generate(input: .scryfallSetCode, inputString: set, output: .commanderBoxingLeagueBox, export: export, boxCount: count, includeExtendedArt: includeExtendedArt, includeBasicLands: false, includeTokens: false, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat)
//				promise.succeed(result)
//			} catch {
//				promise.fail(error)
//			}
//		}
//
//		return promise.futureResult
//	}
	
	func prereleasePack(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let includeExtendedArt: Bool = (try? req.query.get(Bool.self, at: "extendedart")) ?? true
		let count = try? req.query.get(Int.self, at: "count")
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		let seed: Seed? = (try? req.query.get(String.self, at: "seed")).flatMap { seed in
			let components = seed.components(separatedBy: "-")
			let code = components[0]
			let name = components[1]
			return SeedOptions.shared.seedOptions(forSetCode: code).first(where: { $0.name == name })
		}

		let includePromo: Bool = (try? req.query.get(Bool.self, at: "promo")) ?? true
		let includeLands: Bool = (try? req.query.get(Bool.self, at: "lands")) ?? true
		let includeSheet: Bool = (try? req.query.get(Bool.self, at: "sheet")) ?? true
		let includeSpindown: Bool = (try? req.query.get(Bool.self, at: "spindown")) ?? true
		let boosterCount = try? req.query.get(Int.self, at: "boosters")

		let outputFormat = (try? req.query.get(String.self, at: "outputformat")).flatMap(OutputFormat.init(rawValue:)) ?? .default

		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		guard let set = req.parameters.get("set") else {
			promise.fail(PackError.missingSet)
			return promise.futureResult
		}

		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let result = try generate(input: .scryfallSetCode, inputString: set, output: .prereleaseKit, export: export, boxCount: count, prereleaseIncludePromoCard: includePromo, prereleaseIncludeLands: includeLands, prereleaseIncludeSheet: includeSheet, prereleaseIncludeSpindown: includeSpindown, prereleaseBoosterCount: boosterCount, includeExtendedArt: includeExtendedArt, includeBasicLands: true, includeTokens: true, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat, seed: seed)
				promise.succeed(result)
			} catch {
				promise.fail(error)
			}
		}

		return promise.futureResult
	}
	
	private static let decoder = JSONDecoder()
	
	struct DeckList: Content {
		var deck: String
	}
	
	fileprivate func deckFromURL(_ deckURL: URL, _ export: Bool, _ cardBack: URL?, autofix: Bool, customOverrides: String, _ promise: EventLoopPromise<String>) throws -> EventLoopFuture<String> {
		guard let components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else {
			throw PackError.invalidURL
		}
		
		switch components.host {
		case "www.archidekt.com", "archidekt.com":
			guard deckURL.pathComponents.count >= 2, deckURL.pathComponents[1] == "decks", let decklistURL = URL(string: "https://archidekt.com/api/decks/\(deckURL.pathComponents[2])/") else { throw PackError.invalidURL }
			
			DispatchQueue.global(qos: .userInitiated).async {
				let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
				URLSession.shared.dataTask(with: request) { data, response, error in
					do {
						guard let data = data else {
							throw error!
						}
						
						let decoder = JSONDecoder()
						let archidektDeck = try decoder.decode(ArchidektDeck.self, from: data)
						
						DispatchQueue(label: "decklist").async {
							do {
								let result: String = try deck(.archidekt(archidektDeck), export: export, cardBack: cardBack, autofix: autofix, outputName: archidektDeck.name, customOverrides: [customOverrides])
								print("Success")
								promise.succeed(result)
							} catch let error as DebuggableError {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									promise.succeed(string)
								} catch {
									promise.fail(error)
								}
							} catch {
								promise.fail(error)
							}
						}
					} catch let error as DebuggableError {
						struct ErrorMessage: Codable {
							var error: String
						}
						
						let encoder = JSONEncoder()
						let errorMessage = ErrorMessage(error: error.reason)
						do {
							let data = try encoder.encode(errorMessage)
							let string = String(data: data, encoding: .utf8)!
							promise.succeed(string)
						} catch {
							promise.fail(error)
						}
					} catch {
						promise.fail(error)
					}
				}.resume()
			}
		case "moxfield.com", "www.moxfield.com":
			guard deckURL.pathComponents.count >= 2, deckURL.pathComponents[1] == "decks", let decklistURL = URL(string: "https://api.moxfield.com/v2/decks/all/\(deckURL.pathComponents[2])") else { throw PackError.invalidURL }
			
			DispatchQueue.global(qos: .userInitiated).async {
				let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
				URLSession.shared.dataTask(with: request) { data, response, error in
					do {
						guard let data = data else {
							throw error!
						}
						
						let decoder = JSONDecoder()
						let moxfieldDeck = try decoder.decode(MoxfieldDeck.self, from: data)
						
						DispatchQueue(label: "decklist").async {
							do {
								let result: String = try deck(.moxfield(moxfieldDeck), export: export, cardBack: cardBack, autofix: autofix, outputName: moxfieldDeck.name, customOverrides: [customOverrides])
								print("Success")
								promise.succeed(result)
							} catch let error as DebuggableError {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									promise.succeed(string)
								} catch {
									promise.fail(error)
								}
							} catch {
								promise.fail(error)
							}
						}
					} catch let error as DebuggableError {
						struct ErrorMessage: Codable {
							var error: String
						}
						
						let encoder = JSONEncoder()
						let errorMessage = ErrorMessage(error: error.reason)
						do {
							let data = try encoder.encode(errorMessage)
							let string = String(data: data, encoding: .utf8)!
							promise.succeed(string)
						} catch {
							promise.fail(error)
						}
					} catch {
						promise.fail(error)
					}
				}.resume()
			}
			
		case "deckstats.net", "www.deckstats.net":
			guard var components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else { throw PackError.invalidURL  }
			
			components.queryItems = [URLQueryItem(name: "export_mtgarena", value: "1")]
			
			guard let decklistURL = components.url else { throw PackError.invalidURL }
			
			let page = (try? Data(contentsOf: deckURL)).flatMap { String(data: $0, encoding: .utf8) }
			
			let commentCustomOverrides: String? = {
				guard let page = page else { return nil }
				
				if let comment = page.matches(forRegex: #"<p>!custom=(.+)<\/p>"#).first?.groups.first?.value.trimmingCharacters(in: .whitespacesAndNewlines), !comment.isEmpty {
					return comment
				}
				
				return nil
			}()
			
			let alters: [String] = page?.matches(forRegex: #"<a href="(.+)">alter:(.+)<\/a>"#).compactMap { match -> (String, URL)? in
				guard match.groups.count == 2, let url = URL(string: match.groups[0].value) else { return nil }
				return (match.groups[1].value, url)
			}.compactMap { "\($0.0):\($0.1.absoluteString)" } ?? []
			
			DispatchQueue.global(qos: .userInitiated).async {
				let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
				URLSession.shared.dataTask(with: request) { data, response, error in
					do {
						guard let data = data else {
							throw error!
						}
						
						if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
							throw PackError.privateDeck
						}
						
						guard let decklist = String(data: data, encoding: .utf8) else {
							promise.fail(PackError.invalidURL)
							return
						}
						
						let deckName: String?
						
						if let response = response as? HTTPURLResponse, let disposition: String = response.allHeaderFields["Content-Disposition"] as? String, let range = disposition.range(of: "attachment; filename=\"") {
							print(disposition)
							var name: String = disposition
							name.replaceSubrange(range, with: "")
							deckName = String(name.dropLast(5))
						} else {
							deckName = nil
						}
						
						DispatchQueue(label: "decklist").async {
							do {
								
								let result: String = try deck(.arena(decklist), export: export, cardBack: cardBack, autofix: autofix, outputName: deckName, customOverrides: [commentCustomOverrides ?? "", customOverrides] + alters)
								print("Success")
								promise.succeed(result)
							} catch let error as DebuggableError {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									promise.succeed(string)
								} catch {
									promise.fail(error)
								}
							} catch {
								promise.fail(error)
							}
						}
					} catch let error as DebuggableError {
						struct ErrorMessage: Codable {
							var error: String
						}
						
						let encoder = JSONEncoder()
						let errorMessage = ErrorMessage(error: error.reason)
						do {
							let data = try encoder.encode(errorMessage)
							let string = String(data: data, encoding: .utf8)!
							promise.succeed(string)
						} catch {
							promise.fail(error)
						}
					} catch {
						promise.fail(error)
					}
				}.resume()
			}
		case "www.tappedout.net", "tappedout.net":
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
								let result: String = try deck(.arena(arenaDecklist), export: export, cardBack: cardBack, autofix: autofix, customOverrides: [customOverrides])
								print("Success")
								promise.succeed(result)
							} catch let error as DebuggableError {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									promise.succeed(string)
								} catch {
									promise.fail(error)
								}
							} catch {
								promise.fail(error)
							}
						}
					} catch let error as DebuggableError {
						struct ErrorMessage: Codable {
							var error: String
						}
						
						let encoder = JSONEncoder()
						let errorMessage = ErrorMessage(error: error.reason)
						do {
							let data = try encoder.encode(errorMessage)
							let string = String(data: data, encoding: .utf8)!
							promise.succeed(string)
						} catch {
							promise.fail(error)
						}
					} catch {
						promise.fail(error)
					}
				}.resume()
			}
		case "www.mtggoldfish.com", "mtggoldfish.com":
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
										let result: String = try deck(.arena(decklist), export: export, cardBack: cardBack, autofix: autofix, customOverrides: [customOverrides])
										print("Success")
										promise.succeed(result)
									} catch let error as DebuggableError {
										struct ErrorMessage: Codable {
											var error: String
										}
										
										let encoder = JSONEncoder()
										let errorMessage = ErrorMessage(error: error.reason)
										do {
											let data = try encoder.encode(errorMessage)
											let string = String(data: data, encoding: .utf8)!
											promise.succeed(string)
										} catch {
											promise.fail(error)
										}
									} catch {
										promise.fail(error)
									}
								}
								
							} catch let error as DebuggableError {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									promise.succeed(string)
								} catch {
									promise.fail(error)
								}
							} catch {
								promise.fail(error)
							}
						}.resume()
					} catch let error as DebuggableError {
						struct ErrorMessage: Codable {
							var error: String
						}
						
						let encoder = JSONEncoder()
						let errorMessage = ErrorMessage(error: error.reason)
						do {
							let data = try encoder.encode(errorMessage)
							let string = String(data: data, encoding: .utf8)!
							promise.succeed(string)
						} catch {
							promise.fail(error)
						}
					} catch {
						promise.fail(error)
					}
				}.resume()
			}
		default:
			struct ErrorMessage: Codable {
				var error: String
			}
			
			let encoder = JSONEncoder()
			let errorMessage = ErrorMessage(error: PackError.invalidURL.reason)
			do {
				let data = try encoder.encode(errorMessage)
				let string = String(data: data, encoding: .utf8)!
				promise.succeed(string)
			} catch {
				promise.fail(error)
			}
		}
		
		return promise.futureResult
	}
	
	func deckstatsDeck(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let autofix: Bool = (try? req.query.get(Bool.self, at: "autofix")) ?? true
		let cardBack: URL? = (try? req.query.get(String.self, at: "back")).flatMap(URL.init(string:))
		let customOverrides: String = (try? req.query.get(String.self, at: "customoverrides")) ?? ""

		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		guard let deckURLString = req.parameters.get("deck"), let deckURL = URL(string: deckURLString) else {
			throw PackError.invalidURL
		}

		return try deckFromURL(deckURL, export, cardBack, autofix: autofix, customOverrides: customOverrides, promise)
	}
	
	func fullDeck(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let autofix: Bool = (try? req.query.get(Bool.self, at: "autofix")) ?? true
		let cardBack: URL? = (try? req.query.get(String.self, at: "back")).flatMap(URL.init(string:))
		let customOverrides: String = (try? req.query.get(String.self, at: "customoverrides")) ?? ""
		
		let decklist = try req.content.decode(DeckList.self)
		
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		if let url = URL(string: decklist.deck) {
			return try self.deckFromURL(url, export, cardBack, autofix: autofix, customOverrides: customOverrides, promise)
		}
		
		DispatchQueue.global().async {
			do {
				let d: Deck = decklist.deck.contains("[") || decklist.deck.contains("]") ? .deckstats(decklist.deck) : .arena(decklist.deck)
				let result: String = try deck(d, export: export, cardBack: cardBack, autofix: autofix, customOverrides: [customOverrides])
				promise.succeed(result)
			} catch let error as DebuggableError {
				struct ErrorMessage: Codable {
					var error: String
				}
				
				let encoder = JSONEncoder()
				let errorMessage = ErrorMessage(error: error.reason)
				do {
					let data = try encoder.encode(errorMessage)
					let string = String(data: data, encoding: .utf8)!
					promise.succeed(string)
				} catch {
					promise.fail(error)
				}
			} catch {
				promise.fail(error)
			}
		}
		
		return promise.futureResult
	}
	
	func singleCardNamed(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let facedown: Bool = (try? req.query.get(Bool.self, at: "facedown")) ?? false
		
		let fuzzy = try? req.query.get(String.self, at: "fuzzy")
		let exact = try? req.query.get(String.self, at: "exact")
		
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				if let fuzzy = fuzzy {
					let result = try singleCardFuzzy(name: fuzzy, facedown: facedown, export: export)
					promise.succeed(result)
				} else if let exact = exact {
					let result = try singleCardExact(name: exact, facedown: facedown, export: export)
					promise.succeed(result)
				} else {
					throw PackError.noName
				}
			} catch {
				promise.fail(error)
			}
		}
		
		return promise.futureResult
	}
	
	func singleCard(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let facedown: Bool = (try? req.query.get(Bool.self, at: "facedown")) ?? false

		guard let code = req.parameters.get("code"), let number = req.parameters.get("number") else {
			throw PackError.emptyInput
		}

		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()

		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let result = try singleCardCodeNumber(code: code, number: number, facedown: facedown, export: export)
				promise.succeed(result)
			} catch {
				promise.fail(error)
			}
		}

		return promise.futureResult
	}
	
	func singleCardRandom(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true
		let facedown: Bool = (try? req.query.get(Bool.self, at: "facedown")) ?? false
		
		let query = try? req.query.get(String.self, at: "q")
		
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				if let query = query {
					let result = try singleCardScryfallQuery(query: query, facedown: facedown, export: export)
					promise.succeed(result)
				} else {
					let result = try singleCardRand(facedown: facedown, export: export)
					promise.succeed(result)
				}
			} catch {
				promise.fail(error)
			}
		}
		
		return promise.futureResult
	}
	
	func completeToken(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = (try? req.query.get(Bool.self, at: "export")) ?? true

		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		guard let set = req.parameters.get("set") else {
			promise.fail(PackError.missingSet)
			return promise.futureResult
		}

		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let allTokens = try allTokensForSet(setCode: set)
				let token = try singleCompleteToken(tokens: allTokens, export: export)
				promise.succeed(token)
			} catch {
				promise.fail(error)
			}

		}

		return promise.futureResult
	}
	
	func landPacks(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = false
//		let set: String? = try? req.query.get(String.self, at: "set")
		let set = req.parameters.get("set")
		
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				if let set = set {
					let packs = try generate(input: .scryfallSetCode, inputString: set, output: .landPack, export: export, boxCount: nil, prereleaseIncludePromoCard: nil, prereleaseIncludeLands: nil, prereleaseIncludeSheet: nil, prereleaseIncludeSpindown: nil, prereleaseBoosterCount: nil, includeExtendedArt: false, includeBasicLands: true, includeTokens: false, specialOptions: [], cardBack: nil, autofixDecklist: false, outputFormat: .default)
					promise.succeed(packs)
				} else {
					let packs = try allLandPacksSingleJSON(setCards: nil, specialOptions: [], export: export)
					promise.succeed(packs)
				}
			} catch {
				promise.fail(error)
			}
			
		}
		
		return promise.futureResult
	}
}
