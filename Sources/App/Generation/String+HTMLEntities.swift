//
//  String+HTMLEntities.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 10/12/20.
//

import Foundation

// Mapping from XML/HTML character entity reference to character
// From http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
private let characterEntities : [ String : Character ] = [
	// XML predefined entities:
	"&quot;"    : "\"",
	"&amp;"     : "&",
	"&apos;"    : "'",
	"&lt;"      : "<",
	"&gt;"      : ">",
	
	// HTML character entity references:
	"&nbsp;"    : "\u{00a0}",
	// ...
	"&diams;"   : "♦",
]

extension String {
	/// Returns a new string made by replacing in the `String`
	/// all HTML character entity references with the corresponding
	/// character.
	public var decodingHTMLEntities: String {
		
		// ===== Utility functions =====
		
		// Convert the number in the string to the corresponding
		// Unicode character, e.g.
		//    decodeNumeric("64", 10)   --> "@"
		//    decodeNumeric("20ac", 16) --> "€"
		func decodeNumeric(_ string : String, base : Int) -> Character? {
			guard let code = UInt32(string, radix: base),
				let uniScalar = UnicodeScalar(code) else { return nil }
			return Character(uniScalar)
		}
		
		// Decode the HTML character entity to the corresponding
		// Unicode character, return `nil` for invalid input.
		//     decode("&#64;")    --> "@"
		//     decode("&#x20ac;") --> "€"
		//     decode("&lt;")     --> "<"
		//     decode("&foo;")    --> nil
		func decode(_ entity : String) -> Character? {
			
			if entity.hasPrefix("&#x") || entity.hasPrefix("&#X") {
				return decodeNumeric(String(entity[entity.index(entity.startIndex, offsetBy: 3) ..< entity.index(entity.endIndex, offsetBy: -1)]), base: 16)
			} else if entity.hasPrefix("&#") {
				return decodeNumeric(String(entity[entity.index(entity.startIndex, offsetBy: 2) ..< entity.index(entity.endIndex, offsetBy: -1)]), base: 10)
			} else {
				return characterEntities[entity]
			}
		}
		
		// ===== Method starts here =====
		
		var result = ""
		var position = startIndex
		
		// Find the next '&' and copy the characters preceding it to `result`:
		while let ampRange = self.range(of: "&", range: position ..< endIndex) {
			result.append(String(self[position ..< ampRange.lowerBound]))
			position = ampRange.lowerBound
			
			// Find the next ';' and copy everything from '&' to ';' into `entity`
			if let semiRange = self.range(of: ";", range: position ..< endIndex) {
				let entity = self[position ..< semiRange.upperBound]
				position = semiRange.upperBound
				
				if let decoded = decode(String(entity)) {
					// Replace by decoded character:
					result.append(decoded)
				} else {
					// Invalid entity, copy verbatim:
					result.append(String(entity))
				}
			} else {
				// No matching ';'.
				break
			}
		}
		// Copy remaining characters to `result`:
		result.append(String(self[position ..< endIndex]))
		return result
	}
}
