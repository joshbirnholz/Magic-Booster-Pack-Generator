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
import SwiftSoup

public enum OutputFormat: String, CaseIterable, Sendable {
	case tts, cardlist, json
	
	static var `default`: OutputFormat {
		allCases.first!
	}
}

struct ErrorMessage: Codable {
  var error: String
}

extension URLQueryContainer {
	func getBoolValue(at keyPath: CodingKeyRepresentable) -> Bool? {
		guard let stringValue = try? get(String.self, at: keyPath) else { return nil }
		return Bool(stringValue)
	}
}

final class GeneratorController: Sendable {
	func boosterPack(_ req: Request) async throws -> String {
		if let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters")), count > 1 {
			return try await boosterBox(req)
		}

		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let includeExtendedArt: Bool = req.query.getBoolValue(at: "extendedart") ?? false
		guard let set = req.parameters.get("set") else {
      throw PackError.missingSet
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

    return try await generate(input: .scryfallSetCode, inputString: set, output: .boosterPack, export: export, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat, seed: seed)
	}
	
	func boosterBox(_ req: Request) async throws -> String {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let count = (try? req.query.get(Int.self, at: "count")) ?? (try? req.query.get(Int.self, at: "boosters"))
		let includeExtendedArt: Bool = req.query.getBoolValue(at: "extendedart") ?? false
		let specialOptions = (try? req.query.get(String.self, at: "special").components(separatedBy: ",")) ?? []
		let includeBasicLands: Bool = req.query.getBoolValue(at: "lands") ?? true
		let includeTokens: Bool = req.query.getBoolValue(at: "tokens") ?? true
		let outputFormat = (try? req.query.get(String.self, at: "outputformat")).flatMap(OutputFormat.init(rawValue:)) ?? .default

		if count == 1 {
			return try await boosterPack(req)
		}

//		let set = try req.parameters.next(String.self)
		guard let set = req.parameters.get("set") else {
			throw PackError.missingSet
		}

    return try await generate(input: .scryfallSetCode, inputString: set, output: .boosterBox, export: export, boxCount: count, includeExtendedArt: includeExtendedArt, includeBasicLands: includeBasicLands, includeTokens: includeTokens, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat)
	}
	
	func prereleasePack(_ req: Request) async throws -> String {
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

		guard let set = req.parameters.get("set") else {
			throw PackError.missingSet
		}

    return try await generate(input: .scryfallSetCode, inputString: set, output: .prereleaseKit, export: export, boxCount: count, prereleaseIncludePromoCard: includePromo, prereleaseIncludeLands: includeLands, prereleaseIncludeSheet: includeSheet, prereleaseIncludeSpindown: includeSpindown, prereleaseBoosterCount: boosterCount, includeExtendedArt: includeExtendedArt, includeBasicLands: true, includeTokens: true, specialOptions: specialOptions, autofixDecklist: false, outputFormat: outputFormat, seed: seed)
	}
	
	private static let decoder = JSONDecoder()
	
	struct DeckList: Content {
		var deck: String
	}
  
  /// This one is used in the Convert endpoint
  fileprivate func deckFromURL(_ deckURL: URL, autofix: Bool, omenpath: Bool) async throws -> Deck {
    guard let components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else {
      throw PackError.invalidURL
    }
    
    switch components.host {
    case "www.archidekt.com", "archidekt.com":
      guard deckURL.pathComponents.count >= 2, deckURL.pathComponents[1] == "decks", let decklistURL = URL(string: "https://archidekt.com/api/decks/\(deckURL.pathComponents[2])/") else {
        throw PackError.invalidURL
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
          let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
          URLSession.shared.dataTask(with: request) { data, response, error in
            do {
              guard let data1 = data else {
                throw error!
              }
              
              let decoder = JSONDecoder()
              let archidektDeck = try decoder.decode(ArchidektDeck.self, from: data1)
              
              DispatchQueue(label: "decklist").async {
                continuation.resume(with: .success(.archidekt(archidektDeck)))
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
                continuation.resume(with: .failure(PackError.reason(string)))
                return
              } catch {
                continuation.resume(with: .failure(error))
                return
              }
            } catch {
              continuation.resume(with: .failure(error))
              return
            }
          }.resume()
        }
      }
    case "moxfield.com", "www.moxfield.com":
      guard deckURL.pathComponents.count >= 2, deckURL.pathComponents[1] == "decks", let decklistURL = URL(string: "https://api.moxfield.com/v2/decks/all/\(deckURL.pathComponents[2])") else {
        throw PackError.invalidURL
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
          let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
          URLSession.shared.dataTask(with: request) { data, response, error in
            do {
              guard let data1 = data else {
                throw error!
              }
              
              let decoder = JSONDecoder()
              let moxfieldDeck = try decoder.decode(MoxfieldDeck.self, from: data1)
              
              DispatchQueue(label: "decklist").async {
                continuation.resume(with: .success(.moxfield(moxfieldDeck)))
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
                continuation.resume(with: .failure(PackError.reason(string)))
                return
              } catch {
                continuation.resume(with: .failure(error))
                return
              }
            } catch {
              continuation.resume(with: .failure(error))
              return
            }
          }.resume()
        }
      }
      
    case "deckstats.net", "www.deckstats.net":
      guard var components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else {
        throw PackError.invalidURL
      }
      components.queryItems = [
        URLQueryItem(name: "export_dec", value: "1"),
        URLQueryItem(name: "include_comments", value: "1"),
        URLQueryItem(name: "include_collector_numbers", value: "1"),
        URLQueryItem(name: "include_maybeboard", value: "1")
      ]
      
      guard let decklistURL = components.url else {
        throw PackError.invalidURL
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
          let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
          URLSession.shared.dataTask(with: request) { data, response, error in
            do {
              guard let data1 = data else {
                throw error!
              }
              
              if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
                continuation.resume(with: .failure(PackError.privateDeck))
                return
              }
              
              guard let decklist = String(data: data1, encoding: .utf8) else {
                continuation.resume(with: .failure(PackError.invalidURL))
                return
              }
              
              DispatchQueue(label: "decklist").async {
                continuation.resume(with: .success(.deckstats(decklist)))
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
                continuation.resume(with: .failure(PackError.reason(string)))
                return
              } catch {
                continuation.resume(with: .failure(error))
                return
              }
            } catch {
              continuation.resume(with: .failure(error))
              return
            }
          }.resume()
        }
      }
    case "www.tappedout.net", "tappedout.net":
      var newComponents = components
      var queryItems = newComponents.queryItems ?? []
      queryItems.append(.init(name: "fmt", value: "txt"))
      newComponents.queryItems = queryItems
      
      guard let decklistURL = newComponents.url else {
        throw PackError.invalidURL
      }
      
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
          let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
          URLSession.shared.dataTask(with: request) { data, response, error in
            do {
              guard let data1 = data else {
                throw error!
              }
              
              if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
                throw PackError.privateDeck
              }
              
              guard let decklist = String(data: data1, encoding: .utf8) else {
                continuation.resume(with: .failure(PackError.invalidURL))
                return
              }
              
              DispatchQueue(label: "decklist").async {
                continuation.resume(with: .success(.deckstats(decklist)))
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
                continuation.resume(with: .failure(PackError.reason(string)))
                return
              } catch {
                continuation.resume(with: .failure(error))
                return
              }
            } catch {
              continuation.resume(with: .failure(error))
              return
            }
          }.resume()
        }
      }
    case "www.mtggoldfish.com", "mtggoldfish.com":
      return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global().async {
          let request = URLRequest(url: deckURL, cachePolicy: .reloadIgnoringLocalCacheData)
          URLSession.shared.dataTask(with: request) { data, response, error in
            do {
              if let response = response as? HTTPURLResponse, response.statusCode == 404 {
                continuation.resume(with: .failure(PackError.privateDeck))
                return
              }
              
              guard let data1 = data, let page = String(data: data1, encoding: .utf8) else {
                continuation.resume(with: .failure(PackError.invalidURL))
                return
              }
              
              guard let arenaDownloadLink = page.matches(forRegex: #"<a class="btn btn-secondary deck-tools-btn" href="(\/deck\/arena_download\/.+)">"#).first?.groups.first?.value, let arenaDownloadURL = URL(string: "https://www.mtggoldfish.com" + arenaDownloadLink) else {
                continuation.resume(with: .failure(PackError.invalidURL))
                return
              }
              
              let arenaDownloadRequest = URLRequest(url: arenaDownloadURL, cachePolicy: .reloadIgnoringLocalCacheData)
              URLSession.shared.dataTask(with: arenaDownloadRequest) { data2, response1, error in
                do {
                  guard let data1 = data2, let page = String(data: data1, encoding: .utf8) else {
                    continuation.resume(with: .failure(PackError.privateDeck))
                    return
                  }
                  
                  guard let decklist = page.matches(forRegex: #"<textarea class='copy-paste-box'>(.*)<\/textarea>"#, options: .dotMatchesLineSeparators).first?.groups.first?.value.decodingHTMLEntities else {
                    continuation.resume(with: .failure(PackError.privateDeck))
                    return
                  }
                  
                  DispatchQueue(label: "decklist").async {
                    continuation.resume(with: .success(.arena(decklist)))
                    return
                  }
                  
                }
              }.resume()
            }
          }.resume()
        }
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
        throw PackError.reason(string)
      } catch {
        throw error
      }
    }
  }
	
  /// This one is used in the main deck importer
  fileprivate func deckFromURL(_ deckURL: URL, _ export: Bool, _ cardBack: URL?, autofix: Bool, omenpath: Bool) async throws -> String {
    guard let components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else {
      throw PackError.invalidURL
    }
    
    switch components.host {
    case "www.archidekt.com", "archidekt.com":
      guard deckURL.pathComponents.count >= 2, deckURL.pathComponents[1] == "decks", let decklistURL = URL(string: "https://archidekt.com/api/decks/\(deckURL.pathComponents[2])/") else { throw PackError.invalidURL }
      
      let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
      let (data, _) = try await URLSession.shared.data(for: request)
      
      let decoder = JSONDecoder()
      let archidektDeck = try decoder.decode(ArchidektDeck.self, from: data)
      
      let result: String = try await deck(.archidekt(archidektDeck), export: export, cardBack: cardBack, autofix: autofix, outputName: archidektDeck.name, omenpath: omenpath)
      print("Success")
      return result
    case "moxfield.com", "www.moxfield.com":
      guard deckURL.pathComponents.count >= 2, deckURL.pathComponents[1] == "decks", let decklistURL = URL(string: "https://api.moxfield.com/v2/decks/all/\(deckURL.pathComponents[2])") else { throw PackError.invalidURL }
      
      var request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
      
      if let apiKey = Environment.get("MoxfieldAgent") {
        request.setValue(apiKey, forHTTPHeaderField: "User-Agent")
        print("Added Moxfield API key to header")
      }
      
      let (data, _) = try await URLSession.shared.data(for: request)
      let decoder = JSONDecoder()
      let moxfieldDeck = try decoder.decode(MoxfieldDeck.self, from: data)
      
      let result: String = try await deck(.moxfield(moxfieldDeck), export: export, cardBack: cardBack, autofix: autofix, outputName: moxfieldDeck.name, omenpath: omenpath)
      print("Success")
      return result
      
    case "deckstats.net", "www.deckstats.net":
      guard var components = URLComponents(url: deckURL, resolvingAgainstBaseURL: false) else { throw PackError.invalidURL  }
      components.queryItems = [
        URLQueryItem(name: "export_dec", value: "1"),
        URLQueryItem(name: "include_comments", value: "1"),
        URLQueryItem(name: "include_collector_numbers", value: "1")
      ]
      
      guard let decklistURL = components.url else { throw PackError.invalidURL }
      
      var request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
      request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
      let (data, response) = try await URLSession.shared.data(for: request)
      
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
        throw PackError.privateDeck
      }
      
      guard let decklist = String(data: data, encoding: .utf8) else {
        throw PackError.invalidURL
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
      
      do {
        let result: String = try await deck(.deckstats(decklist), export: export, cardBack: cardBack, autofix: autofix, outputName: deckName, omenpath: omenpath)
        print("Success")
        return result
      } catch {
        // Importing failed for some reason, fallback to parsing the page.
        let (data, _) = try await URLSession.shared.data(from: deckURL)
        guard let html = String(data: data, encoding: .utf8) else { throw PackError.emptyInput }
        let doc = try SwiftSoup.parse(html)
        
        let deckstatsDeck: DeckstatsDeck = try parse(doc: doc)
        
        let list = deckstatsDeck.sections.map(\.cards).joined().sorted(on: \.cardPosition).map {
          "\($0.amount) \($0.name)"
        }.joined(separator: "\n")
        
        let result: String = try await deck(.arena(list), export: export, cardBack: cardBack, autofix: autofix, outputName: deckName, omenpath: omenpath)
        print("Success")
        return result
      }
    case "www.tappedout.net", "tappedout.net":
      var newComponents = components
      var queryItems = newComponents.queryItems ?? []
      queryItems.append(.init(name: "fmt", value: "txt"))
      newComponents.queryItems = queryItems
      
      guard let decklistURL = newComponents.url else { throw PackError.invalidURL }
      let request = URLRequest(url: decklistURL, cachePolicy: .reloadIgnoringLocalCacheData)
      let (data, response) = try await URLSession.shared.data(for: request)
      
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
        throw PackError.privateDeck
      }
      
      guard let decklist = String(data: data, encoding: .utf8) else {
        throw PackError.invalidURL
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
      
      let result: String = try await deck(.deckstats(decklist), export: export, cardBack: cardBack, autofix: autofix, outputName: deckName, omenpath: omenpath)
      print("Success")
      return result
    case "www.mtggoldfish.com", "mtggoldfish.com":
      let request = URLRequest(url: deckURL, cachePolicy: .reloadIgnoringLocalCacheData)
      var (data, response) = try await URLSession.shared.data(for: request)
      
      if let response = response as? HTTPURLResponse, response.statusCode == 404 {
        throw PackError.privateDeck
      }
      
      guard let page = String(data: data, encoding: .utf8) else {
        throw PackError.invalidURL
      }
      
      guard let arenaDownloadLink = page.matches(forRegex: #"<a class="btn btn-secondary deck-tools-btn" href="(\/deck\/arena_download\/.+)">"#).first?.groups.first?.value, let arenaDownloadURL = URL(string: "https://www.mtggoldfish.com" + arenaDownloadLink) else {
        throw PackError.invalidURL
      }
      
      let arenaDownloadRequest = URLRequest(url: arenaDownloadURL, cachePolicy: .reloadIgnoringLocalCacheData)
      (data, response) = try await URLSession.shared.data(for: arenaDownloadRequest)
      
      guard let page = String(data: data, encoding: .utf8) else {
        throw PackError.invalidURL
      }
      
      guard let decklist = page.matches(forRegex: #"<textarea class='copy-paste-box'>(.*)<\/textarea>"#, options: .dotMatchesLineSeparators).first?.groups.first?.value.decodingHTMLEntities else {
        throw PackError.invalidURL
      }
      
      let result: String = try await deck(.arena(decklist), export: export, cardBack: cardBack, autofix: autofix, omenpath: omenpath)
      print("Success")
      return result
    default:
      let encoder = JSONEncoder()
      let errorMessage = ErrorMessage(error: PackError.invalidURL.reason)
      let data = try encoder.encode(errorMessage)
      let string = String(data: data, encoding: .utf8)!
      return string
    }
	}
  
  struct DeckstatsDeck: Codable {
    struct Section: Codable {
      let name: String
      let cards: [Card]
      
    }
    struct Card: Codable {
      struct CardData: Codable {
        let collectorNumber: String
        let displaySetId: Int
      }
      let name: String
      let amount: Int
      let data: CardData
      let cardPosition: Int
    }
    let sections: [Section]
  }
  
  func parse(doc: SwiftSoup.Document) throws -> DeckstatsDeck {
    guard let script = try doc.select("script").first(where: { $0.data().contains("init_deck_data(") }) else {
      fatalError("init_deck_data not found")
    }
    
    let scriptContent = script.data()
    
    // Find the start of the JSON object
    guard let startRange = scriptContent.range(of: "init_deck_data(") else {
      fatalError("Couldn't find init_deck_data(")
    }
    guard let jsonStart = scriptContent[startRange.upperBound...].firstIndex(of: "{") else {
      fatalError("Couldn't find JSON start")
    }
    
    // --- Bracket matching to find the end of JSON object ---
    var braceCount = 0
    var jsonEnd: String.Index? = nil
    for i in scriptContent[jsonStart...].indices {
      let ch = scriptContent[i]
      if ch == "{" {
        braceCount += 1
      } else if ch == "}" {
        braceCount -= 1
        if braceCount == 0 {
          jsonEnd = i
          break
        }
      }
    }
    
    guard let jsonEnd else {
      fatalError("Could not find end of JSON object")
    }
    
    // Extract JSON substring
    var jsonString = String(scriptContent[jsonStart...jsonEnd])
    jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
    
    // Decode JSON
    let data = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(DeckstatsDeck.self, from: data)
  }
	
	func deckstatsDeck(_ req: Request) async throws -> String {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let autofix: Bool = req.query.getBoolValue(at: "autofix") ?? true
    let omenpath: Bool = req.query.getBoolValue(at: "omenpath") ?? false
		let cardBack: URL? = (try? req.query.get(String.self, at: "back")).flatMap(URL.init(string:))
		
		guard let deckURLString = req.parameters.get("deck"), let deckURL = URL(string: deckURLString) else {
			throw PackError.invalidURL
		}

    return try await deckFromURL(deckURL, export, cardBack, autofix: autofix, omenpath: omenpath)
	}
	
	func fullDeck(_ req: Request) async throws -> String {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let autofix: Bool = req.query.getBoolValue(at: "autofix") ?? true
    let omenpath: Bool = req.query.getBoolValue(at: "omenpath") ?? false
		let cardBack: URL? = (try? req.query.get(String.self, at: "back")).flatMap(URL.init(string:))
		
		let decklist = try req.content.decode(DeckList.self)
		
    do {
      if let url = URL(string: decklist.deck), url.absoluteString.lowercased().hasPrefix("http") {
        return try await self.deckFromURL(url, export, cardBack, autofix: autofix, omenpath: omenpath)
      }
      
      let d: Deck = decklist.deck.contains("[") || decklist.deck.contains("]") ? .deckstats(decklist.deck) : .arena(decklist.deck)
      return try await deck(d, export: export, cardBack: cardBack, autofix: autofix, omenpath: omenpath)
    } catch let error as DebuggableError {
      let encoder = JSONEncoder()
      let errorMessage = ErrorMessage(error: error.reason)
      let data = try encoder.encode(errorMessage)
      let string = String(data: data, encoding: .utf8)!
      return string
    }
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
  
  func convert(_ req: Request) async -> DeckResponse {
    do {
      let autofix: Bool = req.query.getBoolValue(at: "autofix") ?? true
      let format: String = try req.query.get(String.self, at: "format")
      let omenpath: Bool = req.query.getBoolValue(at: "omenpath") ?? false
      let decklist = try req.content.decode(DeckList.self)
      
      if let url = URL(string: decklist.deck), url.absoluteString.lowercased().hasPrefix("http") {
        do {
          let result = try await self.deckFromURL(url, autofix: autofix, omenpath: omenpath)
          return .init(deck: result)
        } catch {
          return .init(error: (error as? DebuggableError)?.reason ?? error.localizedDescription)
        }
      } else {
        let deck: Deck = decklist.deck.contains("[") || decklist.deck.contains("]") ? .deckstats(decklist.deck) : .arena(decklist.deck)
        return .init(deck: deck)
      }
    } catch {
      return .init(error: (error as? DebuggableError)?.reason ?? error.localizedDescription)
    }
  }
	
  func singleCardNamed(_ req: Request) async throws -> Response {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let facedown: Bool = req.query.getBoolValue(at: "facedown") ?? false
		
		let fuzzy = try? req.query.get(String.self, at: "fuzzy")
		let exact = try? req.query.get(String.self, at: "exact")
    
    if let name = fuzzy ?? exact {
      let match = name.matches(forRegex: #"(.+)\((.+)\)(.+)?"#)
      if let groups = match.first?.groups {
        let result: String = try await {
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
        }()
        
        return Response(headers: ["Content-Type": "application/json", "access-control-allow-headers": "Origin", "access-control-allow-origin": "*"], body: .init(string: result))
      }
    }
		
    let result: String = try await {
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
		}()
		
    return Response(headers: ["Content-Type": "application/json", "access-control-allow-headers": "Origin", "access-control-allow-origin": "*"], body: .init(string: result))
	}
  
  func singleCardNamed_Scryfall(_ req: Request) async throws -> Response {
    let fuzzy = try? req.query.get(String.self, at: "fuzzy")
    let exact = try? req.query.get(String.self, at: "exact")
    
    let headers: HTTPHeaders = ["Content-Type": "application/json", "access-control-allow-headers": "Origin", "access-control-allow-origin": "*"]
    
    let mtgCard: MTGCard = try await {
      if let fuzzy, let card = await DraftmancerSetCache.shared.cardNamed(fuzzy: fuzzy) {
        return card
      } else if let exact, let card = await DraftmancerSetCache.shared.cardNamed(exact: exact) {
        return card
      } else {
        throw Abort(.notFound, headers: headers, reason: "No card found")
      }
    }()
    
    let data = try Swiftfall.encoder.encode(Swiftfall.Card(mtgCard))
    let result = String(data: data, encoding: .utf8)!
    
    return Response(headers: headers, body: .init(string: result))
  }
	
	func singleCard(_ req: Request) async throws -> String {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let facedown: Bool = req.query.getBoolValue(at: "facedown") ?? false

		guard let code = req.parameters.get("code"), let number = req.parameters.get("number") else {
			throw PackError.emptyInput
		}

    return try await singleCardCodeNumber(code: code, number: number, facedown: facedown, export: export)
	}
	
	func singleCardRandom(_ req: Request) async throws -> String {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true
		let facedown: Bool = req.query.getBoolValue(at: "facedown") ?? false
		
		let query = try? req.query.get(String.self, at: "q")
		
    if let query = query {
      return try await singleCardScryfallQuery(query: query, facedown: facedown, export: export)
    } else {
      return try await singleCardRand(facedown: facedown, export: export)
    }
	}
	
	func completeToken(_ req: Request) async throws -> String {
		let export: Bool = req.query.getBoolValue(at: "export") ?? true

		guard let set = req.parameters.get("set") else {
      throw PackError.missingSet
		}

    let allTokens = try await allTokensForSet(setCode: set)
    let token = try singleCompleteToken(tokens: allTokens, export: export)
    return token
	}
	
	func landPacks(_ req: Request) async throws -> String {
		let export: Bool = false
//		let set: String? = try? req.query.get(String.self, at: "set")
		let set = req.parameters.get("set")
		
		if let set = set {
      let packs = try await generate(input: .scryfallSetCode, inputString: set, output: .landPack, export: export, boxCount: nil, prereleaseIncludePromoCard: nil, prereleaseIncludeLands: nil, prereleaseIncludeSheet: nil, prereleaseIncludeSpindown: nil, prereleaseBoosterCount: nil, includeExtendedArt: false, includeBasicLands: true, includeTokens: false, specialOptions: [], cardBack: nil, autofixDecklist: false, outputFormat: .default)
      return packs
    } else {
      let packs = try await allLandPacksSingleJSON(setCards: nil, specialOptions: [], export: export)
      return packs
    }
	}
}
