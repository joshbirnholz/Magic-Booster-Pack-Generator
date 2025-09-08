/*
 This source file is part of the Swift.org open source project
 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception
 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

import Foundation

// https://github.com/apple/swift-package-manager/blob/5d05348c6fd072ae7989ed8b55ac2b017486acf4/Sources/Basic/OrderedSet.swift

/// An ordered set is an ordered collection of instances of `Element` in which
/// uniqueness of the objects is guaranteed.
public struct OrderedSet<E: Hashable>: Equatable, Collection {
  public typealias Element = E
  public typealias Index = Int
  
#if swift(>=4.1.50)
  public typealias Indices = Range<Int>
#else
  public typealias Indices = CountableRange<Int>
#endif
  
  private var array: [Element]
  private var set: Set<Element>
  
  /// Creates an empty ordered set.
  public init() {
    self.array = []
    self.set = Set()
  }
  
  /// Creates an ordered set with the contents of `array`.
  ///
  /// If an element occurs more than once in `element`, only the first one
  /// will be included.
  public init(_ array: [Element]) {
    self.init()
    for element in array {
      append(element)
    }
  }
  
  // MARK: Working with an ordered set
  /// The number of elements the ordered set stores.
  public var count: Int { return array.count }
  
  /// Returns `true` if the set is empty.
  public var isEmpty: Bool { return array.isEmpty }
  
  /// Returns the contents of the set as an array.
  public var contents: [Element] { return array }
  
  /// Returns the contents of the set as a set.
  public var setContents: Set<Element> { return set }
  
  /// Returns `true` if the ordered set contains `member`.
  public func contains(_ member: Element) -> Bool {
    return set.contains(member)
  }
  
  /// Adds an element to the ordered set.
  ///
  /// If it already contains the element, then the set is unchanged.
  ///
  /// - returns: True if the item was inserted.
  @discardableResult
  public mutating func append(_ newElement: Element) -> Bool {
    let inserted = set.insert(newElement).inserted
    if inserted {
      array.append(newElement)
    }
    return inserted
  }
  
  public mutating func append<T: Sequence>(contentsOf sequence: T) where T.Element == Element {
    set.formUnion(sequence)
    array.append(contentsOf: sequence)
  }
  
  public mutating func formUnion<T: Sequence>(_ other: T) where T.Element == Element {
    append(contentsOf: other)
  }
  
  /// Modifies the element at the given index.
  public mutating func modify(_ newElement: Element, at index: Int) {
    let oldItem = array[index]
    set.remove(oldItem)
    set.insert(newElement)
    array[index] = newElement
  }
  
  /// Remove and return the element at the beginning of the ordered set.
  public mutating func removeFirst() -> Element {
    let firstElement = array.removeFirst()
    set.remove(firstElement)
    return firstElement
  }
  
  /// Remove and return the element at the end of the ordered set.
  public mutating func removeLast() -> Element {
    let lastElement = array.removeLast()
    set.remove(lastElement)
    return lastElement
  }
  
  /// Remove all elements.
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    array.removeAll(keepingCapacity: keepCapacity)
    set.removeAll(keepingCapacity: keepCapacity)
  }
  
  @discardableResult
  public mutating func remove(at index: Int) -> Element? {
    let member = array.remove(at: index)
    set.remove(member)
    return member
  }
  
  public mutating func remove(atOffsets offsets: IndexSet) {
    let members = offsets.map { array[$0] }
    for member in members {
      set.remove(member)
    }
    for offset in offsets.sorted(by: >) {
      array.remove(at: offset)
    }
  }
  
  /// Removes the given element and any elements subsumed by the given element.
  @discardableResult
  public mutating func remove(_ member: Element) -> Element? {
    let element = set.remove(member)
    while let index = array.firstIndex(of: member) {
      array.remove(at: index)
    }
    return element
  }
  
  public mutating func formSymmetricDifference<T: Sequence>(_ other: T) where T.Element == Element {
    for item in other {
      if set.contains(item) {
        remove(item)
      } else {
        append(item)
      }
    }
  }
  
  public mutating func swapAt(_ i: Int, _ j: Int) {
    array.swapAt(i, j)
  }
}

extension OrderedSet: ExpressibleByArrayLiteral {
  /// Create an instance initialized with `elements`.
  ///
  /// If an element occurs more than once in `element`, only the first one
  /// will be included.
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension OrderedSet: RandomAccessCollection {
  public var startIndex: Int { return contents.startIndex }
  public var endIndex: Int { return contents.endIndex }
  public subscript(index: Int) -> Element {
    get {
      return contents[index]
    }
    set {
      modify(newValue, at: index)
    }
  }
}

public func == <T>(lhs: OrderedSet<T>, rhs: OrderedSet<T>) -> Bool {
  return lhs.contents == rhs.contents
}

extension OrderedSet: Hashable where Element: Hashable { }

extension OrderedSet: CustomStringConvertible {
  public var description: String {
    return contents.description
  }
}

extension OrderedSet: CustomDebugStringConvertible {
  public var debugDescription: String {
    return contents.debugDescription
  }
}

extension OrderedSet: Encodable where E: Encodable {
  public func encode(to encoder: Encoder) throws {
    try array.encode(to: encoder)
  }
}

extension OrderedSet: Decodable where E: Decodable {
  public init(from decoder: Decoder) throws {
    let arr = try [E].init(from: decoder)
    self.init(arr)
  }
}
