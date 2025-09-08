//
//  String+Regex.swift
//  Magic Board
//
//  Created by Josh Birnholz on 2/15/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation

internal typealias Match = (range: Range<String.Index>, value: String)

internal struct RegexResult {
  public var fullMatch: Match
  public var groups: [Match]
  
  fileprivate var getGroupWithName: (String) -> Match?
  
  public subscript(_ groupName: String) -> Match? {
    return getGroupWithName(groupName)
  }
}

internal extension String {
  func matches(forRegex regex: String, options: NSRegularExpression.Options = []) -> [RegexResult] {
    do {
      let regex = try NSRegularExpression(pattern: regex, options: options)
      let results = regex.matches(in: self, range: NSRange(startIndex..., in: self))
      return results.map { result in
        let fullMatchRange = Range(result.range, in: self)!
        let groups: [Match]
        
        if result.numberOfRanges > 1 {
          groups = (1 ..< result.numberOfRanges).compactMap { i in
            guard let range = Range(result.range(at: i), in: self) else {
              return nil
            }
            let value = String(self[range])
            return (range: range, value: value)
          }
        } else {
          groups = []
        }
        
        let fullMatch = (range: fullMatchRange, value: String(self[fullMatchRange]))
        
        func getGroupWithName(name: String) -> Match? {
          guard let range = Range(result.range(withName: name), in: self) else {
            return nil
          }
          
          let value = String(self[range])
          return (range: range, value: value)
        }
        
        return RegexResult(fullMatch: fullMatch, groups: groups, getGroupWithName: getGroupWithName(name:))
      }
    } catch {
      return []
    }
  }
}


extension Array {
	/// Removes all the elements that satisfy the given predicate, and returns a new array containing the removed elements.
	/// - Parameter shouldBeRemoved: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be removed from the array.
	/// - Returns: The removed elements.
	mutating func separateAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows -> [Element] {		
		var separation: [Element] = []
		for (index, element) in enumerated().reversed() {
			if try shouldBeRemoved(element) {
				separation.insert(remove(at: index), at: 0)
			}
		}
		return separation
	}
	
	public func chunked(by chunkSize: Int) -> [[Element]] {
		guard !isEmpty else { return [] }
		return stride(from: 0, to: self.count, by: chunkSize).map {
			Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
		}
	}
	
	public func choose(_ n: Int) -> ArraySlice<Element> {
		guard n >= 0 else { return [] }
		let n = Swift.min(n, count)
		
		var copy = self
		for i in stride(from: count - 1, to: count - n - 1, by: -1) {
			copy.swapAt(i, Int.random(in: 0..<(i+1)))
		}
		return copy.suffix(n)
	}
  
  public func choose(_ n: Int, where predicate: (Element) throws -> Bool) rethrows -> ArraySlice<Element> {
    guard n >= 0 else { return [] }
    return try filter(predicate).choose(n)
  }
}

extension Optional where Wrapped: StringProtocol {
	func contains<T: StringProtocol>(_ other: T) -> Bool {
		guard let value = self else { return false }
		return value.contains(other)
	}
}

extension Optional where Wrapped: Collection, Wrapped.Element: Equatable {
	func contains(_ element: Wrapped.Element) -> Bool {
		guard let value = self else { return false }
		return value.contains(element)
	}
}

extension Optional where Wrapped: Collection {
  func contains(where predicate: (Wrapped.Element) throws -> Bool) rethrows -> Bool {
    guard let value = self else { return false }
    return try value.contains(where: predicate)
  }
}

extension Int {
  var withCommas: String {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    return numberFormatter.string(from: NSNumber(value:self)) ?? String(describing: self)
  }
}

extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self {
    return min(max(self, limits.lowerBound), limits.upperBound)
  }
}

//#if swift(<5.1)
//extension Strideable where Stride: SignedInteger {
//  func clamped(to limits: CountableClosedRange<Self>) -> Self {
//    return min(max(self, limits.lowerBound), limits.upperBound)
//  }
//}
//#endif
