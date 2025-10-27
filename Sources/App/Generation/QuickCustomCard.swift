//
//  QuickCustomCard.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 2/24/21.
//

import Foundation
import Vapor

extension Encodable {
  func encodeResponse(for request: Vapor.Request) -> NIOCore.EventLoopFuture<Vapor.Response> {
    return request.eventLoop.makeCompletedFuture {
      var headers = HTTPHeaders()
      headers.add(name: .contentType, value: "application/json")
      
      let encoder = JSONEncoder()
      let data = try encoder.encode(self)
      let string = String.init(data: data, encoding: .utf8) ?? ""
      
      return .init(
        status: .ok, headers: headers, body: .init(string: string)
      )
    }
  }
}

protocol JSONResponseEncodable: Encodable, ResponseEncodable {
  
}

public extension EventLoop {
  func makeCompletedFuture<Success: Sendable>(withResultOf body: () throws -> Success) -> EventLoopFuture<Success> {
    makeCompletedFuture(Result {
      return try body()
    })
  }
}
