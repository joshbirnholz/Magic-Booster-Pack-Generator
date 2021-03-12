//
//  QuickCustomCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 2/24/21.
//

import Foundation
import Vapor

struct Seed: Codable, Content {
	let set: String
	let name: String
	let colors: [MTGColor]
}

final class SeedOptions {
	static let shared = SeedOptions()
	
	private let seeds: [String: [String: String]] = {
		do {
			let url: URL = {
				#if canImport(Vapor)
				let directory = DirectoryConfig.detect()
				let configDir = "Sources/App/Generation"
				return URL(fileURLWithPath: directory.workDir)
					.appendingPathComponent(configDir, isDirectory: true)
					.appendingPathComponent("seeds.json", isDirectory: false)
				#else
				return Bundle.main.url(forResource: "seeds", withExtension: "json")
				#endif
			}()
			
			let decoder = JSONDecoder()
			let data = try Data(contentsOf: url)
			let seeds = try decoder.decode([String: [String: String]].self, from: data)
			return seeds
		} catch {
			print("Error loading seeds:", error)
			return [:]
		}
	}()
	
	func seedOptions(forSetCode setCode: String) -> [Seed] {
		guard let list = seeds[setCode.lowercased()] else { return [] }
		
		return list.compactMap { key, value in
			let colors = key.compactMap { MTGColor(rawValue: $0.uppercased()) }
			return Seed(set: setCode.lowercased(), name: value, colors: colors)
		}
	}
	
	func getAllSeeds(_ req: Request) throws -> EventLoopFuture<[String: [Seed]]> {
		let promise: Promise<[String: [Seed]]> = req.eventLoop.newPromise()
		
		var dict: [String: [Seed]] = [:]
		
		for setCode in self.seeds.keys {
			dict[setCode] = seedOptions(forSetCode: setCode)
		}
		
		promise.succeed(result: dict)
		
		return promise.futureResult
	}
}
