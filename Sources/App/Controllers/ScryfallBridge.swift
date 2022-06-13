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
		Swiftfall.ScryfallSet(code: "net", mtgo: nil, name: "Netropolis (Custom Set)", uri: "", scryfallUri: "", searchUri: "", releasedAt: nil, setType: "expansion", cardCount: 0, digital: true, foilOnly: false, blockCode: "net", block: "net", printedSize: nil, iconSvgUri: nil),
//	Swiftfall.ScryfallSet(code: "hlw", mtgo: nil, name: "Hollows of Lordran (Custom Set)", uri: "", scryfallUri: "", searchUri: "", releasedAt: nil, setType: "expansion", cardCount: 0, digital: true, foilOnly: false, blockCode: "hlw", block: "hlw", iconSvgUri: nil),
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
					"plist", "h1r", "j21", "slx", "2x2", "dmu", "bro"
				]
				
				var sets: [Swiftfall.ScryfallSet] = try Swiftfall.getSetList().data.compactMap {
					guard allowedSetTypes.contains($0.setType),
						  let code = $0.code,
						  !disallowedSetCodes.contains(code)
					else { return nil }
					
					var set = $0
					
					if set.code == "mb1" {
						set.code = "cmb1"
						set.name = "Mystery Booster (Convention Edition)"
					}
					
					if set.code == "fmb1" {
						set.name = "Mystery Booster (Retail Edition)"
					}
					
					if let size = set.printedSize, set.cardCount < size {
						return nil
					}
					
					return set
				}
				
				sets.append(contentsOf: Self.customSets)
				
				promise.succeed(sets)
			} catch {
				promise.fail(error)
			}
		}
		
		return promise.futureResult
	}
	
}
