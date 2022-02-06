//
//  CockatriceCardDatabase.swift
//  Cockatrice to Scryfall
//
//  Created by Josh Birnholz on 3/26/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation

struct CockatriceCardDatabase: Decodable {
	struct Set: Decodable {
		var name: String
		var longname: String
		var settype: String
	}
	
	struct Card: Codable {
		struct SetInfo: Codable {
			var rarity: String?
			var picURL: String?
			var picURLHq: String?
			var picURLSt: String?
			var shortName: String
			
			enum CodingKeys: String, CodingKey {
				case rarity = "@rarity"
				case picURL = "@picURL"
				case picURLHq = "@picURLHq"
				case picURLSt = "@picURLSt"
				case shortName = "#text"
			}
			
			init(from decoder: Decoder) throws {
				do {
					let container = try decoder.container(keyedBy: CodingKeys.self)
					self.rarity = try container.decodeIfPresent(String.self, forKey: .rarity)
					self.picURL = try container.decodeIfPresent(String.self, forKey: .picURL)
					self.picURLHq = try container.decodeIfPresent(String.self, forKey: .picURLHq)
					self.picURLSt = try container.decodeIfPresent(String.self, forKey: .picURLSt)
					self.shortName = try container.decode(String.self, forKey: .shortName)
				} catch {
					let container = try decoder.singleValueContainer()
					var set = try container.decode(String.self)
					set = "T" + set
					self.shortName = set
				}
			}
		}
		
		struct ReverseRelated: Codable {
			var count: String?
			var text: String
			
			enum CodingKeys: String, CodingKey {
				case count = "@count"
				case text = "#text"
			}
			
			init(_ text: String) {
				self.text = text
				self.count = nil
			}
			
			init(from decoder: Decoder) throws {
				do {
					let container = try decoder.container(keyedBy: CodingKeys.self)
					self.count = try container.decode(String.self, forKey: .count)
					self.text = try container.decode(String.self, forKey: .text)
				} catch {
					let container = try decoder.singleValueContainer()
					self.text = try container.decode(String.self)
				}
			}
		}
		
		var name: String
		var set: SetInfo
		var color: String
		var manacost: String?
		var cmc: String?
		var type: String
		var pt: String?
		var loyalty: String?
		var text: String?
		var token: Bool
		var reverseRelated: [ReverseRelated]?
		
		private enum CodingKeys: String, CodingKey {
			case name, set, color, manacost, cmc, type, pt, loyalty, text, token
			case reverseRelated = "reverse-related"
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.name = try container.decode(String.self, forKey: .name)
			self.set = try container.decode(SetInfo.self, forKey: .set)
			
			do {
				self.color = try container.decode(String.self, forKey: .color)
			} catch {
				let array = try container.decode([String].self, forKey: .color)
				self.color = array.joined()
			}
			
			do {
				self.manacost = try container.decodeIfPresent(String.self, forKey: .manacost)
			} catch {
				let array = try container.decodeIfPresent([String].self, forKey: .manacost)
				self.manacost = array?.joined()
			}
			
			do {
				self.cmc = try container.decodeIfPresent(String.self, forKey: .cmc)
			} catch {
				let array = try container.decodeIfPresent([String].self, forKey: .cmc)
				self.cmc = array?.joined()
			}
			
			self.type = try container.decode(String.self, forKey: .type)
			self.pt = try container.decodeIfPresent(String.self, forKey: .pt)
			self.loyalty = try container.decodeIfPresent(String.self, forKey: .loyalty)
			
			do {
				self.text = try container.decode(String.self, forKey: .text)
			} catch {
				let array = try container.decode([String].self, forKey: .text)
				self.text = array.joined()
			}
			
			if let tokenNum = try container.decodeIfPresent(String.self, forKey: .token), tokenNum == "1" {
				self.token = true
			} else {
				self.token = false
			}
			
			if let reverseRelated = try? container.decodeIfPresent([ReverseRelated].self, forKey: .reverseRelated) {
				self.reverseRelated = reverseRelated
			} else if let single = try? container.decodeIfPresent(ReverseRelated.self, forKey: .reverseRelated) {
				self.reverseRelated = [single]
			}
			
		}
	}
	
	var sets: [String: Set]
	
	var cards: [Card]
}
