//
//  MTGSet.swift
//  App
//
//  Created by Josh Birnholz on 8/13/20.
//

import Foundation

public struct MTGSet: Codable, Equatable {
	
	public var cards: [MTGCard]
	public var name: String
	public var code: String
	
}
