//
//  Option.swift
//  Spellbook
//
//  Created by Josh Birnholz on 8/13/22.
//  Copyright © 2022 iowncode. All rights reserved.
//

import Foundation

struct Option: Equatable, Hashable, ExpressibleByStringLiteral {
  let title: String
  let value: String
  let description: String?
  typealias StringLiteralType = String
  
  init(_ title: String, value: String? = nil, description: String? = nil) {
    self.title = title
    self.value = value ?? title
    self.description = description
  }
  
  init(stringLiteral value: String) {
    self.init(value)
  }
}
