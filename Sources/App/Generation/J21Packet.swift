import Foundation
import Vapor

struct Weight: Codable, ExpressibleByStringLiteral {
	let name: String
	let frequency: Int
	
	init(_ name: String, _ frequency: Int) {
		self.name = name
		self.frequency = frequency
	}
	
	init(stringLiteral value: StringLiteralType) {
		self.init(value, 100)
	}
}

struct Packet: Codable {
	struct Slot: Codable, ExpressibleByStringLiteral, ExpressibleByArrayLiteral {
		
		let cards: [Weight]
		
		init(_ cards: [Weight]) {
			self.cards = cards
		}
		
		init(stringLiteral value: StringLiteralType) {
			self.cards = [Weight(value, 100)]
		}
		
		typealias ArrayLiteralElement = Weight
		
		init(arrayLiteral elements: Weight...) {
			self.cards = elements
		}
		
		func chooseCard() -> String {
			guard !cards.isEmpty else {
				fatalError("Slot cannot be empty")
			}
			guard cards.count > 1 else {
				return cards[0].name
			}
			
			let total = cards.map { $0.frequency }.reduce(0, +) // Should always equal 100
			let rand = (0..<total).randomElement()!
			
			var sum = 0
			for card in cards {
				sum += card.frequency
				if rand < sum {
					return card.name
				}
			}
			
			fatalError("This should never be reached")
		}
	}
	
	let name: String
	let slots: [Slot]
	
	func chooseCards() -> [String] {
		var cards = slots.map { $0.chooseCard() }
		cards.removeAll(where: { $0 == "EMPTY" })
		return cards
	}
	
	static let allPackets: [Packet] = {
		do {      
      let url = urlForResource("j21packets", withExtension: "json")
			
			let decoder = JSONDecoder()
			let data = try Data(contentsOf: url)
			let seeds = try decoder.decode([Packet].self, from: data)
			return seeds
		} catch {
			print("Error loading packets:", error)
			return []
		}
	}()
}
