//
//  CardIdentifier.swift
//  CardService
//
//  Created by Josh Birnholz on 3/9/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation

public enum MTGCardIdentifier: Codable, Hashable, CustomStringConvertible {
	enum CodingKeys: String, CodingKey {
		case id
		case mtgoID = "mtgo_id"
		case multiverseID = "multiverse_id"
		case oracleID = "oracle_id"
		case illustrationID = "illustration_id"
		case name
		case set
		case collectorNumber = "collector_number"
	}
	
	case id(UUID)
	case mtgoID(Int)
	case multiverseID(Int)
	case oracleID(UUID)
	case illustrationID(UUID)
	case name(String)
	case nameSet(name: String, set: String)
	case collectorNumberSet(collectorNumber: String, set: String)
	
	public func encode(to coder: Encoder) throws {
		var container = coder.container(keyedBy: CodingKeys.self)
	
		switch self {
		case .id(let id):
			try container.encode(id, forKey: .id)
		case .mtgoID(let id):
			try container.encode(id, forKey: .mtgoID)
		case .multiverseID(let id):
			try container.encode(id, forKey: .multiverseID)
		case .oracleID(let id):
			try container.encode(id, forKey: .oracleID)
		case .illustrationID(let id):
			try container.encode(id, forKey: .illustrationID)
		case .name(let name):
			try container.encode(name, forKey: .name)
		case .nameSet(let name, let set):
			try container.encode(name, forKey: .name)
			try container.encode(set, forKey: .set)
		case .collectorNumberSet(let collectorNumber, let set):
			try container.encode(collectorNumber, forKey: .collectorNumber)
			try container.encode(set, forKey: .set)
		}
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let id = try container.decodeIfPresent(UUID.self, forKey: .id) {
			self = .id(id)
			return
		}
		
		if let id = try container.decodeIfPresent(Int.self, forKey: .mtgoID) {
			self = .mtgoID(id)
			return
		}
		
		if let id = try container.decodeIfPresent(Int.self, forKey: .multiverseID) {
			self = .multiverseID(id)
			return
		}
		
		if let oracleID = try container.decodeIfPresent(UUID.self, forKey: .oracleID) {
			self = .oracleID(oracleID)
			return
		}
		
		if let id = try container.decodeIfPresent(UUID.self, forKey: .illustrationID) {
			self = .illustrationID(id)
			return
		}
		
		let name = try container.decodeIfPresent(String.self, forKey: .name)
		let set = try container.decodeIfPresent(String.self, forKey: .set)
		
		if let name = name {
			if let set = set {
				self = .nameSet(name: name, set: set)
				return
			} else {
				self = .name(name)
				return
			}
		}
		
		if let set = set, let collectorNumber = try container.decodeIfPresent(String.self, forKey: .collectorNumber) {
			self = .collectorNumberSet(collectorNumber: collectorNumber, set: set)
			return
		}
		
		let context = DecodingError.Context(codingPath: [], debugDescription: "Could not decode a card identifier")
		throw DecodingError.dataCorrupted(context)
	}
	
	public var description: String {
		switch self {
			
		case .id(let id):
			return "Scryfall ID \(id)"
		case .mtgoID(let id):
			return "MTGO ID \(id)"
		case .multiverseID(let id):
			return "Multiverse ID \(id)"
		case .oracleID(let id):
			return "Oracle ID \(id)"
		case .illustrationID(let id):
			return "Scryfall Illustration ID \(id)"
		case .name(let name):
			return name
		case .nameSet(let name, let set):
			return "\(name) (\(set))"
		case .collectorNumberSet(let collectorNumber, let set):
			return "\(set) \(collectorNumber)"
		}
	}
}
