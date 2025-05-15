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

extension Swiftfall.ScryfallError: DebuggableError {
  public var reason: String {
		return self.details
	}
	
  public var identifier: String {
		return self.code
	}
}

extension PackError: DebuggableError {
	var identifier: String {
		return String(code)
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
		case .noName:
			return "A value must be provided for either the 'fuzzy' or 'exact' parameter."
		case .noCardFound(let identifier):
			return "No cards found with identifiers: \(identifier)"
		case .emptyInput:
			return "The input is empty."
		case .invalidJumpStartName:
			return "There isn't a pack with that name."
		case .invalidURL:
			return "The URL is invalid."
		case .privateDeck:
			return "There was an error loading the deck. Check that the deck is set to public."
		case .couldNotLoadCards(let names):
			return "An internal server error occurred while attempting to load the following cards: \(names)"
		case .missingSet:
			return "There was no specified set."
		case .failedToBuildPack:
			return "A problem occured trying to select cards for the pack."
    case .reason(let string):
      return string
		}
	}
	
	
}
