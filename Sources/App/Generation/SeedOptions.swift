//
//  QuickCustomCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 2/24/21.
//

import Foundation
import Vapor

public struct Seed: Codable, Content, Sendable {
	enum PackType: String, Codable, CaseIterable {
		case stx, grnRna, snc
	}
	
	let set: String
	let name: String
	let packtype: PackType
	let colors: [MTGColor]
	
	func contains(_ card: MTGCard) -> Bool {
		if let watermark = (card.cardFaces?.first?.watermark ?? card.watermark)?.lowercased() {
			return watermark == self.name.lowercased()
		}
		
		let colors: Set<MTGColor> = Set(card.colorIdentity ?? [])
		guard !colors.isEmpty else { return false }
		return colors.isSubset(of: self.colors)
	}
	
	func matchesExactly(_ card: MTGCard) -> Bool {		
		let colors: Set<MTGColor> = Set(card.colorIdentity ?? [])
		return colors == Set(self.colors)
	}
}

final class SeedOptions: Sendable {
	static let shared = SeedOptions()
	
	private let seeds: [String: [String: String]] = {
		do {      
      let url = urlForResource("seeds", withExtension: "json")
			
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
		guard var list = seeds[setCode.lowercased()] else { return [] }
		let typeRawValue = list["type"] ?? Seed.PackType.allCases.first!.rawValue
		let packType = Seed.PackType(rawValue: typeRawValue) ?? Seed.PackType.allCases.first!
		list["type"] = nil
		
		return list.compactMap { key, value in
			let colors = key.compactMap { MTGColor(rawValue: $0.uppercased()) }
			return Seed(set: setCode.lowercased(), name: value, packtype: packType, colors: colors)
		}.sorted(on: \.name)
	}
	
	func getAllSeeds(_ req: Request) throws -> EventLoopFuture<[String: [Seed]]> {
		let promise: EventLoopPromise<[String: [Seed]]> = req.eventLoop.makePromise()
		
		var dict: [String: [Seed]] = [:]
		
		for setCode in self.seeds.keys {
			dict[setCode] = seedOptions(forSetCode: setCode)
		}
		
		promise.succeed(dict)
		
		return promise.futureResult
	}
}
