//
//  GenerationController.swift
//  App
//
//  Created by Josh Birnholz on 4/15/20.
//

import Vapor
#if canImport(FoundationNetworking)
import FoundationNetworking
import Foundation
#endif

public enum OutputFormat: String, CaseIterable, Sendable {
	case tts, cardlist, json
	
	static var `default`: OutputFormat {
		allCases.first!
	}
}

extension URLQueryContainer {
	func getBoolValue(at keyPath: CodingKeyRepresentable) -> Bool? {
		guard let stringValue = try? get(String.self, at: keyPath) else { return nil }
		return Bool(stringValue)
	}
}

final class GeneratorController {
	func boosterPack(_ req: Request) throws -> EventLoopFuture<String> {
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		if let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters")), count > 1 {
			return try boosterBox(req)
		}

		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let includeExtendedArt: Bool = req.query.getBoolValue(at: "extendedart") ?? false
		guard let set = req.parameters.get("set") else {
			promise.fail(PackError.missingSet)
			return promise.futureResult
		}
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		let includeBasicLands = req.query.getBoolValue(at: "lands") ?? true
		let includeTokens = req.query.getBoolValue(at: "tokens") ?? true
		let outputFormat = (try? req.query.get(String.self, at: "outputformat")).flatMap(OutputFormat.init(rawValue:)) ?? .default
		let seed: Seed? = (try? req.query.get(String.self, at: "seed")).flatMap { seed in
			let components = seed.components(separatedBy: "-")
			let code = components[0]
			let name = components[1]
			return SeedOptions.shared.seedOptions(forSetCode: code).first(where: { $0.name == name })
		}

    promise.completeWithTask {
      return try await generate(input: .scryfallSetCode, inputString: set, output: .boosterPack, export: export, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat, seed: seed)
		}

		return promise.futureResult
	}
	
	func boosterBox(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters"))
		let includeExtendedArt: Bool = req.query.getBoolValue(at: "extendedart") ?? false
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		let includeBasicLands: Bool = req.query.getBoolValue(at: "lands") ?? true
		let includeTokens: Bool = req.query.getBoolValue(at: "tokens") ?? true
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

    promise.completeWithTask {
      try await generate(input: .scryfallSetCode, inputString: set, output: .boosterBox, export: export, boxCount: count, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat)
		}

		return promise.futureResult
	}
	
//	func commanderBoxingLeagueBox(_ req: Request) throws -> EventLoopFuture<String> {
//		let export: Bool = req.query.getBoolValue(at: "export") ?? true
//		let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters"))
//		let includeExtendedArt: Bool = req.query.getBoolValue(at: "extendedart") ?? true
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
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let includeExtendedArt: Bool = req.query.getBoolValue(at: "extendedart") ?? false
		let count = try? req.query.get(Int.self, at: "count")
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		let seed: Seed? = (try? req.query.get(String.self, at: "seed")).flatMap { seed in
			let components = seed.components(separatedBy: "-")
			let code = components[0]
			let name = components[1]
			return SeedOptions.shared.seedOptions(forSetCode: code).first(where: { $0.name == name })
		}

		let includePromo: Bool = req.query.getBoolValue(at: "promo") ?? true
		let includeLands: Bool = req.query.getBoolValue(at: "lands") ?? true
		let includeSheet: Bool = req.query.getBoolValue(at: "sheet") ?? true
		let includeSpindown: Bool = req.query.getBoolValue(at: "spindown") ?? true
		let boosterCount = try? req.query.get(Int.self, at: "boosters")

		let outputFormat = (try? req.query.get(String.self, at: "outputformat")).flatMap(OutputFormat.init(rawValue:)) ?? .default

		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		guard let set = req.parameters.get("set") else {
			promise.fail(PackError.missingSet)
			return promise.futureResult
		}

    promise.completeWithTask {
      return try await generate(input: .scryfallSetCode, inputString: set, output: .prereleaseKit, export: export, boxCount: count, prereleaseIncludePromoCard: includePromo, prereleaseIncludeLands: includeLands, prereleaseIncludeSheet: includeSheet, prereleaseIncludeSpindown: includeSpindown, prereleaseBoosterCount: boosterCount, includeExtendedArt: includeExtendedArt, includeBasicLands: true, includeTokens: true, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat, seed: seed)
		}

		return promise.futureResult
	}
	
	private static let decoder = JSONDecoder()
	
	struct DeckList: Content {
		var deck: String
	}
  
  fileprivate func deckFromURL(_ deckURL: URL, autofix: Bool, _ completion: @Sendable @escaping (Result<Deck, Error>) -> Void) {
    guard let components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else {
      completion(.failure(PackError.invalidURL))
      return
    }
    
    switch components.host {
    case "www.archidekt.com", "archidekt.com":
      guard deckURL.pathComponents.count >= 2, deckURL.pathComponents[1] == "decks", let decklistURL = URL(string: "https://archidekt.com/api/decks/\(deckURL.pathComponents[2])/") else {
        completion(.failure(PackError.invalidURL))
        return
      }
      
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
              completion(.success(.archidekt(archidektDeck)))
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
              completion(.failure(PackError.reason(string)))
              return
            } catch {
              completion(.failure(error))
              return
            }
          } catch {
            completion(.failure(error))
            return
          }
        }.resume()
      }
    case "moxfield.com", "www.moxfield.com":
      guard deckURL.pathComponents.count >= 2, deckURL.pathComponents[1] == "decks", let decklistURL = URL(string: "https://api.moxfield.com/v2/decks/all/\(deckURL.pathComponents[2])") else {
        completion(.failure(PackError.invalidURL))
        return
      }
      
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
              completion(.success(.moxfield(moxfieldDeck)))
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
              completion(.failure(PackError.reason(string)))
              return
            } catch {
              completion(.failure(error))
              return
            }
          } catch {
            completion(.failure(error))
            return
          }
        }.resume()
      }
      
    case "deckstats.net", "www.deckstats.net":
      guard var components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else {
        completion(.failure(PackError.invalidURL))
        return
      }
      components.queryItems = [
        URLQueryItem(name: "export_dec", value: "1"),
        URLQueryItem(name: "include_comments", value: "1"),
        URLQueryItem(name: "include_collector_numbers", value: "1"),
        URLQueryItem(name: "include_maybeboard", value: "1")
      ]
      
      guard let decklistURL = components.url else {
        completion(.failure(PackError.invalidURL))
        return
      }
      
      DispatchQueue.global(qos: .userInitiated).async {
        let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
        URLSession.shared.dataTask(with: request) { data, response, error in
          do {
            guard let data = data else {
              throw error!
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
              completion(.failure(PackError.privateDeck))
              return
            }
            
            guard let decklist = String(data: data, encoding: .utf8) else {
              completion(.failure(PackError.invalidURL))
              return
            }
            
            DispatchQueue(label: "decklist").async {
              completion(.success(.deckstats(decklist)))
              return
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
              completion(.failure(PackError.reason(string)))
              return
            } catch {
              completion(.failure(error))
              return
            }
          } catch {
            completion(.failure(error))
            return
          }
        }.resume()
      }
    case "www.tappedout.net", "tappedout.net":
      var newComponents = components
      var queryItems = newComponents.queryItems ?? []
      queryItems.append(.init(name: "fmt", value: "txt"))
      newComponents.queryItems = queryItems
      
      guard let decklistURL = newComponents.url else {
        completion(.failure(PackError.invalidURL))
        return
      }
      
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
              completion(.failure(PackError.invalidURL))
              return
            }
            
            DispatchQueue(label: "decklist").async {
              completion(.success(.deckstats(decklist)))
              return
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
              completion(.failure(PackError.reason(string)))
              return
            } catch {
              completion(.failure(error))
              return
            }
          } catch {
            completion(.failure(error))
            return
          }
        }.resume()
      }
    case "www.mtggoldfish.com", "mtggoldfish.com":
      DispatchQueue.global().async {
        let request = URLRequest(url: deckURL, cachePolicy: .reloadIgnoringLocalCacheData)
        URLSession.shared.dataTask(with: request) { data, response, error in
          do {
            if let response = response as? HTTPURLResponse, response.statusCode == 404 {
              completion(.failure(PackError.privateDeck))
              return
            }
            
            guard let data = data, let page = String(data: data, encoding: .utf8) else {
              completion(.failure(PackError.invalidURL))
              return
            }
            
            guard let arenaDownloadLink = page.matches(forRegex: #"<a class="btn btn-secondary deck-tools-btn" href="(\/deck\/arena_download\/.+)">"#).first?.groups.first?.value, let arenaDownloadURL = URL(string: "https://www.mtggoldfish.com" + arenaDownloadLink) else {
              completion(.failure(PackError.invalidURL))
              return
            }
            
            let arenaDownloadRequest = URLRequest(url: arenaDownloadURL, cachePolicy: .reloadIgnoringLocalCacheData)
            URLSession.shared.dataTask(with: arenaDownloadRequest) { data, response, error in
              do {
                guard let data = data, let page = String(data: data, encoding: .utf8) else {
                  completion(.failure(PackError.privateDeck))
                  return
                }
                
                guard let decklist = page.matches(forRegex: #"<textarea class='copy-paste-box'>(.*)<\/textarea>"#, options: .dotMatchesLineSeparators).first?.groups.first?.value.decodingHTMLEntities else {
                  completion(.failure(PackError.privateDeck))
                  return
                }
                
                DispatchQueue(label: "decklist").async {
                  completion(.success(.arena(decklist)))
                  return
                }
                
              }
            }.resume()
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
        completion(.failure(PackError.reason(string)))
        return
      } catch {
        completion(.failure(error))
        return
      }
    }
  }
	
	fileprivate func deckFromURL(_ deckURL: URL, _ export: Bool, _ cardBack: URL?, autofix: Bool, _ promise: EventLoopPromise<String>) throws -> EventLoopFuture<String> {
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
						
            promise.completeWithTask {
							do {
								let result: String = try await deck(.archidekt(archidektDeck), export: export, cardBack: cardBack, autofix: autofix, outputName: archidektDeck.name)
								print("Success")
								return result
							} catch let error as DebuggableError {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									return string
								} catch {
									throw error
								}
							} catch {
								throw error
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
				var request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
        
        if let apiKey = Environment.get("MoxfieldAgent") {
          request.setValue(apiKey, forHTTPHeaderField: "User-Agent")
          print("Added Moxfield API key to header")
        }
        
				URLSession.shared.dataTask(with: request) { data, response, error in
					do {
						guard let data = data else {
							throw error!
						}
						
						let decoder = JSONDecoder()
						let moxfieldDeck = try decoder.decode(MoxfieldDeck.self, from: data)
						
            promise.completeWithTask {
							do {
								let result: String = try await deck(.moxfield(moxfieldDeck), export: export, cardBack: cardBack, autofix: autofix, outputName: moxfieldDeck.name)
								print("Success")
								return result
							} catch let error as DebuggableError {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									return string
								} catch {
									throw error
								}
							} catch {
								throw error
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
              print("Moxfield error:", error)
              if let data = data, let response = String(data: data, encoding: .utf8) {
                print("Moxfield response:", response)
              }
						}
					} catch {
						promise.fail(error)
            print("Moxfield error:", error)
            if let data = data, let response = String(data: data, encoding: .utf8) {
              print("Moxfield response:", response)
            }
					}
				}.resume()
			}
			
		case "deckstats.net", "www.deckstats.net":
			guard var components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else { throw PackError.invalidURL  }
			components.queryItems = [
				URLQueryItem(name: "export_dec", value: "1"),
				URLQueryItem(name: "include_comments", value: "1"),
				URLQueryItem(name: "include_collector_numbers", value: "1")
			]
			
			guard let decklistURL = components.url else { throw PackError.invalidURL }
			
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
						
            promise.completeWithTask {
							do {
								
								let result: String = try await deck(.deckstats(decklist), export: export, cardBack: cardBack, autofix: autofix, outputName: deckName)
								print("Success")
								return result
							} catch let error as DebuggableError {
								struct ErrorMessage: Codable {
									var error: String
								}
								
								let encoder = JSONEncoder()
								let errorMessage = ErrorMessage(error: error.reason)
								do {
									let data = try encoder.encode(errorMessage)
									let string = String(data: data, encoding: .utf8)!
									return string
								} catch {
									throw error
								}
							} catch {
								throw error
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
      var newComponents = components
      var queryItems = newComponents.queryItems ?? []
      queryItems.append(.init(name: "fmt", value: "txt"))
      newComponents.queryItems = queryItems
      
      guard let decklistURL = newComponents.url else { throw PackError.invalidURL }
      
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
            
            if let response = response as? HTTPURLResponse, let disposition: String = response.allHeaderFields["Content-Disposition"] as? String, let range = disposition.range(of: "attachment;filename=") {
              print(disposition)
              var name: String = disposition
              name.replaceSubrange(range, with: "")
              deckName = String(name.dropLast(4))
            } else {
              deckName = nil
            }
            
            promise.completeWithTask {
              do {
                
                let result: String = try await deck(.deckstats(decklist), export: export, cardBack: cardBack, autofix: autofix, outputName: deckName)
                print("Success")
                return result
              } catch let error as DebuggableError {
                struct ErrorMessage: Codable {
                  var error: String
                }
                
                let encoder = JSONEncoder()
                let errorMessage = ErrorMessage(error: error.reason)
                do {
                  let data = try encoder.encode(errorMessage)
                  let string = String(data: data, encoding: .utf8)!
                  return string
                } catch {
                  throw error
                }
              } catch {
                throw error
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
								
                promise.completeWithTask {
									do {
										let result: String = try await deck(.arena(decklist), export: export, cardBack: cardBack, autofix: autofix)
										print("Success")
										return result
									} catch let error as DebuggableError {
										struct ErrorMessage: Codable {
											var error: String
										}
										
										let encoder = JSONEncoder()
										let errorMessage = ErrorMessage(error: error.reason)
										do {
											let data = try encoder.encode(errorMessage)
											let string = String(data: data, encoding: .utf8)!
											return string
										} catch {
											throw error
										}
									} catch {
										throw error
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
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let autofix: Bool = req.query.getBoolValue(at: "autofix") ?? true
		let cardBack: URL? = (try? req.query.get(String.self, at: "back")).flatMap(URL.init(string:))

		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		guard let deckURLString = req.parameters.get("deck"), let deckURL = URL(string: deckURLString) else {
			throw PackError.invalidURL
		}

		return try deckFromURL(deckURL, export, cardBack, autofix: autofix, promise)
	}
	
	func fullDeck(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let autofix: Bool = req.query.getBoolValue(at: "autofix") ?? true
		let cardBack: URL? = (try? req.query.get(String.self, at: "back")).flatMap(URL.init(string:))
		
		let decklist = try req.content.decode(DeckList.self)
		
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
    if let url = URL(string: decklist.deck), url.absoluteString.lowercased().hasPrefix("http") {
			return try self.deckFromURL(url, export, cardBack, autofix: autofix, promise)
		}
		
    promise.completeWithTask {
			do {
				let d: Deck = decklist.deck.contains("[") || decklist.deck.contains("]") ? .deckstats(decklist.deck) : .arena(decklist.deck)
				let result: String = try await deck(d, export: export, cardBack: cardBack, autofix: autofix)
				return result
			} catch let error as DebuggableError {
				struct ErrorMessage: Codable {
					var error: String
				}
				
				let encoder = JSONEncoder()
				let errorMessage = ErrorMessage(error: error.reason)
				do {
					let data = try encoder.encode(errorMessage)
					let string = String(data: data, encoding: .utf8)!
					return string
				} catch {
					throw error
				}
			} catch {
				throw error
			}
		}
		
		return promise.futureResult
	}
  
  struct DeckResponse: Codable, Content {
    struct Board: Codable, Content {
      let name: String
      let string: String
    }
    
    var boards: [Board]?
    var error: String?
    
    init(deck: Deck) {
      var mainGroups = DeckParser.parse(deck, autofixArena: false, keepOriginalDeckstatsGroups: true)
      let sideboardGroups = mainGroups.separateAll(where: { DeckParser.CardGroup.name(for: $0.name ?? "", defaultToMain: true) == DeckParser.CardGroup.GroupName.sideboard.rawValue })
      let consideringGroups = mainGroups.separateAll(where: { DeckParser.CardGroup.name(for: $0.name ?? "", defaultToMain: true) == DeckParser.CardGroup.GroupName.maybeboard.rawValue })
      let tokenGroups = mainGroups.separateAll(where: { $0.name == "Tokens" })
      
      
      var boards: [Board] = []
      
      if !mainGroups.isEmpty {
        boards.append(.init(name: "Main", string: moxfieldString(from: mainGroups)))
      }
      
      if !sideboardGroups.isEmpty {
        boards.append(.init(name: "Sideboard", string: moxfieldString(from: sideboardGroups)))
      }
      
      if !consideringGroups.isEmpty {
        boards.append(.init(name: "Considering", string: moxfieldString(from: consideringGroups)))
      }
      
      if !tokenGroups.isEmpty {
        boards.append(.init(name: "Tokens", string: moxfieldString(from: tokenGroups)))
      }
      
      self.boards = boards
    }
    
    init(error: String) {
      self.error = error
    }
  }
  
  func convert(_ req: Request) throws -> EventLoopFuture<DeckResponse> {
    let promise: EventLoopPromise<DeckResponse> = req.eventLoop.makePromise()
    do {
      let autofix: Bool = req.query.getBoolValue(at: "autofix") ?? true
      let format: String = try req.query.get(String.self, at: "format")
      let decklist = try req.content.decode(DeckList.self)
      
      if let url = URL(string: decklist.deck), url.absoluteString.lowercased().hasPrefix("http") {
        self.deckFromURL(url, autofix: autofix) { result in
          do {
            let deck = try result.get()
            promise.succeed(.init(deck: deck))
          } catch {
            promise.succeed(.init(error: (error as? DebuggableError)?.reason ?? error.localizedDescription))
          }
        }
      } else {
        let deck: Deck = decklist.deck.contains("[") || decklist.deck.contains("]") ? .deckstats(decklist.deck) : .arena(decklist.deck)
        
        DispatchQueue.global().async {
          promise.succeed(.init(deck: deck))
        }
      }
    } catch {
      promise.succeed(.init(error: (error as? DebuggableError)?.reason ?? error.localizedDescription))
    }
    
    return promise.futureResult
  }
	
	func singleCardNamed(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let facedown: Bool = req.query.getBoolValue(at: "facedown") ?? false
		
		let fuzzy = try? req.query.get(String.self, at: "fuzzy")
		let exact = try? req.query.get(String.self, at: "exact")
    
    let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
    
    if let name = fuzzy ?? exact {
      let match = name.matches(forRegex: #"(.+)\((.+)\)(.+)?"#)
      if let groups = match.first?.groups {
        promise.completeWithTask({
          let cardName = groups[0].value.trimmingCharacters(in: .whitespaces)
          let setCode = groups[1].value.trimmingCharacters(in: .whitespaces)
          let collectorNumber = groups.count == 3 ? groups[2].value.trimmingCharacters(in: .whitespaces) : nil
          
          if let collectorNumber {
            do {
              let card = try await Swiftfall.getCard(code: setCode, number: collectorNumber)
              var mtgCard = MTGCard(card)
              
              if !card.games.contains("paper"), let fixed = await DraftmancerSetCache.shared.loadedDraftmancerCards?.first(where: { $0.name?.lowercased() == card.name.lowercased() && $0.set.lowercased() == card.set.lowercased() && $0.collectorNumber.lowercased() == card.collectorNumber.lowercased()
              }) {
                mtgCard = fixed
              }
              
              return try await App.singleCard(mtgCard, facedown: facedown, export: export)
            } catch {
              if let card = await DraftmancerSetCache.shared.loadedDraftmancerCards?[.collectorNumberSet(collectorNumber: collectorNumber, set: setCode, name: cardName)] {
                return try await App.singleCard(card, facedown: facedown, export: export)
              } else {
                throw error
              }
            }
          } else {
            do {
              let card = try await Swiftfall.getCard(name: cardName, set: setCode)
              
              var mtgCard = MTGCard(card)
              
              if !card.games.contains("paper"), let fixed = await DraftmancerSetCache.shared.loadedDraftmancerCards?.first(where: { $0.name?.lowercased() == card.name.lowercased() && $0.set.lowercased() == card.set.lowercased() && $0.collectorNumber.lowercased() == card.collectorNumber.lowercased()
              }) {
                mtgCard = fixed
              }
              
              return try await App.singleCard(mtgCard, facedown: facedown, export: export)
            } catch {
              if let card = await DraftmancerSetCache.shared.loadedDraftmancerCards?[.nameSet(name: cardName, set: setCode)] {
                return try await App.singleCard(card, facedown: facedown, export: export)
              } else {
                throw error
              }
            }
          }
        })
        return promise.futureResult
      }
    }
		
    promise.completeWithTask {
			do {
				if let fuzzy = fuzzy {
					let result = try await singleCardFuzzy(name: fuzzy, facedown: facedown, export: export)
					return result
				} else if let exact = exact {
					let result = try await singleCardExact(name: exact, facedown: facedown, export: export)
					return result
				} else {
					throw PackError.noName
				}
			} catch {
				throw error
			}
		}
		
		return promise.futureResult
	}
	
	func singleCard(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let facedown: Bool = req.query.getBoolValue(at: "facedown") ?? false

		guard let code = req.parameters.get("code"), let number = req.parameters.get("number") else {
			throw PackError.emptyInput
		}

		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()

    promise.completeWithTask {
      return try await singleCardCodeNumber(code: code, number: number, facedown: facedown, export: export)
		}

		return promise.futureResult
	}
	
	func singleCardRandom(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let facedown: Bool = req.query.getBoolValue(at: "facedown") ?? false
		
		let query = try? req.query.get(String.self, at: "q")
		
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
    promise.completeWithTask {
      if let query = query {
        return try await singleCardScryfallQuery(query: query, facedown: facedown, export: export)
      } else {
        return try await singleCardRand(facedown: facedown, export: export)
      }
		}
		
		return promise.futureResult
	}
	
	func completeToken(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true

		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
		guard let set = req.parameters.get("set") else {
			promise.fail(PackError.missingSet)
			return promise.futureResult
		}

    promise.completeWithTask {
      let allTokens = try await allTokensForSet(setCode: set)
      let token = try singleCompleteToken(tokens: allTokens, export: export)
      return token
		}

		return promise.futureResult
	}
	
	func landPacks(_ req: Request) throws -> EventLoopFuture<String> {
		let export: Bool = false
//		let set: String? = try? req.query.get(String.self, at: "set")
		let set = req.parameters.get("set")
		
		let promise: EventLoopPromise<String> = req.eventLoop.makePromise()
		
    promise.completeWithTask {
			do {
				if let set = set {
					let packs = try await generate(input: .scryfallSetCode, inputString: set, output: .landPack, export: export, boxCount: nil, prereleaseIncludePromoCard: nil, prereleaseIncludeLands: nil, prereleaseIncludeSheet: nil, prereleaseIncludeSpindown: nil, prereleaseBoosterCount: nil, includeExtendedArt: false, includeBasicLands: true, includeTokens: false, specialOptions: [], cardBack: nil, autofixDecklist: false, outputFormat: .default)
					return packs
				} else {
					let packs = try await allLandPacksSingleJSON(setCards: nil, specialOptions: [], export: export)
					return packs
				}
			} catch {
				throw error
			}
			
		}
		
		return promise.futureResult
	}
}
