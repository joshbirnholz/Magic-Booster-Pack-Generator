//
//  Errors.swift
//  App
//
//  Created by Josh Birnholz on 4/16/20.
//

import Foundation
#if canImport(Vapor)
import Vapor
#endif

extension Swiftfall.ScryfallError: Debuggable {
	var reason: String {
		return self.details
	}
	
	var identifier: String {
		return self.code
	}
}

extension PackError: Debuggable {
	var identifier: String {
		return String(rawValue)
	}
	
	var reason: String {
		switch self {
		case .wrongNumberOfCards:
			return "A booster pack with the correct number of cards couldn't be generated."
		case .noImage:
			return "There is no image for the specified card."
		case .noValidPromo:
			return "A valid promo card couldn't be found."
		case .notInBoosters:
			return "The specified set doesn't contain any cards found in booster packs."
		case .notEnoughLands:
			return "There aren't enough basic lands to create a land pack."
		case .noCards:
			return "There are no cards in the specified set."
		case .unsupported:
			return "Generating an object of the specified type for the specified set is unsupported."
		}
	}
	
	
}
