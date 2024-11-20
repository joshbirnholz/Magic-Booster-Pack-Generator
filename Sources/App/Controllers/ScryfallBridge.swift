//
//  ScryfallBridge.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 11/6/20.
//

import Vapor
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Swiftfall.ScryfallSet: Content {
	
}

final class ScryfallBridgeController {
	
	static let customSets = [
    Swiftfall.ScryfallSet(code: "sjm", mtgo: nil, name: "SuperJump! (Magic Online)", uri: "", scryfallUri: "", searchUri: "", releasedAt: nil, setType: "expansion", cardCount: 0, digital: true, foilOnly: false, blockCode: "sjm", block: "sjm", printedSize: nil, iconSvgUri: nil),
	]
	
	func getSets(_ req: Request) throws -> EventLoopFuture<[Swiftfall.ScryfallSet]> {
		let promise: EventLoopPromise<[Swiftfall.ScryfallSet]> = req.eventLoop.makePromise()
		
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				let allowedSetTypes: Set<String> = [
					"core",
					"expansion",
					"masters",
					"draft_innovation"
				]
        
        let disallowedSetCodes: Set<String> = [
          "plist", "h1r", "j21", "slx", "uplist", "scd", "tscd", "sis", "mat", "mom", "who", "rvr", "lci"
        ]
        
        let setsFromScryfall: [[Swiftfall.ScryfallSet]] = try Swiftfall.getSetList().data.compactMap {
          guard allowedSetTypes.contains($0.setType),
                let code = $0.code,
                !disallowedSetCodes.contains(code)
          else { return [] }
          
          var set = $0
          
          if $0.code == "sir" {
            set.name += " (Weekly)"
            
            return [set] + (1...4).compactMap {
              customSet(forSetCode: "sir\($0)")
            }
          }
          
          if set.code == "mb1" {
            set.code = "cmb1"
            set.name = "Mystery Booster (Convention Edition)"
          }
          
          if set.code == "fmb1" {
            set.name = "Mystery Booster (Retail Edition)"
          }
          
          if ["clu", "j25"].contains(set.code) {
            return [set]
          }
          
          if let size = set.printedSize, set.cardCount < size {
            return nil
          }
          
          let cutoff = Date(timeIntervalSince1970: 1677646800)
          if let date = set.releasedAt, date > cutoff {
            return nil
          }
          
          return [set]
        }
                
                var sets = Array(setsFromScryfall.joined())
				
				sets.append(contentsOf: Self.customSets)
				
				promise.succeed(sets)
			} catch {
				promise.fail(error)
			}
		}
		
		return promise.futureResult
	}
	
}
