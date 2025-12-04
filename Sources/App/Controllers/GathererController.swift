//
//  GathererController.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 12/3/25.
//

import Vapor
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
import Foundation
#endif

actor GathererController {
  
  func instanceText(_ req: Request) async throws -> Response {
    
    guard let setCode = req.parameters.get("set"),
          let number = req.parameters.get("number") else {
      throw Abort(.badRequest, reason: "Missing setCode or collectorNumber")
    }
    
    guard let multiverseID = try await Swiftfall.getCard(code: setCode, number: number).multiverseIds.first else {
      throw Abort(.badRequest, reason: "Could not find card on Gatherer")
    }
    
    let lang = "en-us"
    
    let url = URI(string:
                    "https://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=\(multiverseID)"
    )
    
    let response = try await req.client.get(url)
    
    guard let html = response.body?.getString(at: response.body!.readerIndex, length: response.body!.readableBytes) else {
      throw Abort(.internalServerError, reason: "Could not read HTML")
    }
    
    let doc = try SwiftSoup.parse(html)
    
    let scripts = try doc.select("script")
    
    let keys = ["instanceName", "instanceText", "instanceTypeLine"]
    
    var dict: [String: Any] = [:]
    
    for (index, script) in scripts.enumerated() {
      var text = try script.html()
      guard keys.contains(where: { text.contains(($0)) }) else { continue }
      guard text.hasPrefix("self.__next_f.push(") && text.hasSuffix(")") else { continue }
      text = String(text.dropFirst("self.__next_f.push(".count).dropLast())
      
      let object = try JSONSerialization.jsonObject(with: text.data(using: .utf8)!) as? [Any]
      guard let value = object?.last as? String else { continue }
      guard let data = "{\(value.quotingNumericJSONKeys())}".data(using: .utf8) else { continue }
      
      guard let innerObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
      guard let arr = innerObject.values.first as? [Any] else { continue }
      guard let childrenArr = arr.first(where: { $0 is [String: Any] }) as? [String: Any] else { continue }
      guard let children = (childrenArr["children"] as? [Any])?.first(where: { $0 is [String: Any] }) as? [String: Any] else { continue }
      guard let card = children["card"] as? [String: Any] else { continue }
      
//      let instanceText = value["instanceText"] as? String
//      let instanceTypeLine = value["instanceTypeLine"] as? String
      
      let jsonText = String(data: try JSONSerialization.data(withJSONObject: card, options: []), encoding: .utf8) ?? ""
      
      return Response(headers: ["Content-Type": "application/json", "access-control-allow-headers": "Origin", "access-control-allow-origin": "*"], body: .init(string: jsonText))
    }
    
    throw Abort(.internalServerError, reason: "Could not get card from Gatherer")
  }
  
}

extension String {
    /// Wraps bare numeric JSON keys like 39: into "39":
    func quotingNumericJSONKeys() -> String {
      let pattern = #"(?<!")(\d+)\s*:"#   // number not already quoted, followed by colon
      
      guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
      
      let nsRange = NSRange(startIndex..<endIndex, in: self)
      
      // Find only the first occurrence
      guard let match = regex.firstMatch(in: self, range: nsRange),
            let keyRange = Range(match.range(at: 1), in: self) else {
        return self
      }
      
      var result = self
      let key = self[keyRange]
      
      // Replace exact matched region with quoted version
      if let wholeRange = Range(match.range, in: self) {
        let replacement = "\"\(key)\":"
        result.replaceSubrange(wholeRange, with: replacement)
      }
      
      return result
    }
}
