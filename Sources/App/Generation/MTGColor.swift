//
//  MTGColor.swift
//  CardService
//
//  Created by Josh Birnholz on 3/9/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public extension Array where Element == MTGColor {
	var ordered: [MTGColor] {
		return self.sorted {
			switch ($0.orderNumber, $1.orderNumber) {
			case (let first?, let second?): return first < second
			case (.some, nil): return true
			case (nil, .some): return false
			case (nil, nil): return true
			}
		}
	}
}

public enum MTGColor: String, Codable, CaseIterable, Sendable {
	case white = "W"
	case blue = "U"
	case black = "B"
	case red = "R"
	case green = "G"
	case multicolor
	case artifact
	case colorless
	
	public var name: String {
		switch self {
		case .white:
			return "white"
		case .blue:
			return "blue"
		case .black:
			return "black"
		case .red:
			return "red"
		case .green:
			return "green"
		case .multicolor:
			return "multicolor"
		case .artifact:
			return "artifact"
		case .colorless:
			return "colorless"
		}
	}
	
	public var orderNumber: Int? {
		switch self {
		case .white: return 0
		case .blue: return 1
		case .black: return 2
		case .red: return 3
		case .green: return 4
		default: return nil
		}
	}
	
	public var land: String? {
		switch self {
		case .white:
			return "plains"
		case .blue:
			return "island"
		case .black:
			return "swamp"
		case .red:
			return "mountain"
		case .green:
			return "forest"
		case .multicolor:
			return nil
		case .artifact:
			return nil
		case .colorless:
			return "wastes"
		}
	}
	
	public init?(landName: String) {
		for color in MTGColor.allCases where color.land == landName.lowercased() {
			self = color
			return
		}
		return nil
	}
	
	#if canImport(UIKit)
	public var symbolColor: UIColor {
		return UIColor(named: "\(name) mana")!
	}
	
	public var borderColor: UIColor {
		return UIColor(named: "\(name) border")!
	}
	
	public var textBackgroundColor: UIColor {
		return UIColor(named: "\(name) background")!
	}
	
	public var boxBackgroundColor: UIColor {
		return UIColor(named: "\(name) box background")!
	}
	
	public var cardEdgeColor: UIColor {
		return UIColor(named: "\(name) edge")!
	}
	
	public var cardEdgeImage: UIImage {
		return UIImage(named: "bg-\(name)")!
	}
	#endif
	
}
