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
		case mtgoId
		case multiverseId
		case oracleId
		case illustrationId
		case name
		case set
		case collectorNumber
	}
	
	case id(UUID)
	case mtgoID(Int)
	case multiverseID(Int)
	case oracleID(UUID)
	case illustrationID(UUID)
	case name(String)
	case nameSet(name: String, set: String)
	case collectorNumberSet(collectorNumber: String, set: String, name: String?)
	
	var id: UUID? {
		if case .id(let id) = self {
			return id
		} else {
			return nil
		}
	}

	var mtgoID: Int? {
		if case .mtgoID(let id) = self {
			return id
		} else {
			return nil
		}
	}
	
	var multiverseID: Int? {
		if case .multiverseID(let id) = self {
			return id
		} else {
			return nil
		}
	}
	
	var oracleID: UUID? {
		if case .oracleID(let id) = self {
			return id
		} else {
			return nil
		}
	}
	
	var illustrationID: UUID? {
		if case .illustrationID(let id) = self {
			return id
		} else {
			return nil
		}
	}
	
	var name: String? {
		switch self {
		case .name(let name), .nameSet(name: let name, set: _), .collectorNumberSet(collectorNumber: _, set: _, name: let name?):
			return name
		default:
			return nil
		}
	}
	
	var set: String? {
		switch self {
		case .nameSet(name: _, set: let set), .collectorNumberSet(collectorNumber: _, set: let set, name: _):
			return set
		default:
		return nil
		}
	}
	
	var collectorNumber: String? {
		if case .collectorNumberSet(let collectorNumber, _, _) = self {
			return collectorNumber
		} else {
			return nil
		}
	}
	
	public func encode(to coder: Encoder) throws {
		var container = coder.container(keyedBy: CodingKeys.self)
	
		switch self {
		case .id(let id):
			try container.encode(id.uuidString.lowercased(), forKey: .id)
		case .mtgoID(let id):
			try container.encode(id, forKey: .mtgoId)
		case .multiverseID(let id):
			try container.encode(id, forKey: .multiverseId)
		case .oracleID(let id):
			try container.encode(id, forKey: .oracleId)
		case .illustrationID(let id):
			try container.encode(id, forKey: .illustrationId)
		case .name(let name):
			try container.encode(name, forKey: .name)
		case .nameSet(let name, let set):
			try container.encode(name, forKey: .name)
			try container.encode(set, forKey: .set)
		case .collectorNumberSet(let collectorNumber, let set, _):
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
		
		if let id = try container.decodeIfPresent(Int.self, forKey: .mtgoId) {
			self = .mtgoID(id)
			return
		}
		
		if let id = try container.decodeIfPresent(Int.self, forKey: .multiverseId) {
			self = .multiverseID(id)
			return
		}
		
		if let oracleID = try container.decodeIfPresent(UUID.self, forKey: .oracleId) {
			self = .oracleID(oracleID)
			return
		}
		
		if let id = try container.decodeIfPresent(UUID.self, forKey: .illustrationId) {
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
			self = .collectorNumberSet(collectorNumber: collectorNumber, set: set, name: name)
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
		case .collectorNumberSet(let collectorNumber, let set, let name):
			var desc = "\(set) #\(collectorNumber)"
			if let name = name {
				desc += " (\(name))"
			}
			return desc
		}
	}
}
