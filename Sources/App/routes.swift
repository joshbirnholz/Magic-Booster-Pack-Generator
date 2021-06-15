import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
	router.get { req -> Response in
		return req.response(http: HTTPResponse(status: .movedPermanently,
												   version: HTTPVersion(major: 1, minor: 1),
												   headers: HTTPHeaders([("Location", "index.html")])))
	}
	
	let generatorController = GeneratorController()
	
	router.post("card", "named", use: generatorController.singleCardNamed)
	
	router.post("card", String.parameter, String.parameter, use: generatorController.singleCard)
	
	router.post("card", "random", use: generatorController.singleCardRandom)
	
	router.post("landpacks", String.parameter, use: generatorController.landPacks)
	router.post("landpacks", use: generatorController.landPacks)
	
	router.post(String.parameter, use: generatorController.boosterPack)
	router.post("booster", String.parameter, use: generatorController.boosterPack)
	router.post("boosterpack", String.parameter, use: generatorController.boosterPack)
	router.post("pack", String.parameter, use: generatorController.boosterPack)
	
	router.post("boosterbox", String.parameter, use: generatorController.boosterBox)
	router.post("box", String.parameter, use: generatorController.boosterBox)
	
	router.post("boxingleague", String.parameter, use: generatorController.commanderBoxingLeagueBox)
	
	router.post("prerelease", String.parameter, use: generatorController.prereleasePack)
	router.post("pre", String.parameter, use: generatorController.prereleasePack)
	
	router.post("token", String.parameter, use: generatorController.completeToken)
	
	router.post("deck", use: generatorController.fullDeck)
	
	router.post("url", String.parameter, use: generatorController.deckstatsDeck)
	
	router.get("customcards", use: CustomCards.shared.getCustomCards)
	router.get("seeds", use: SeedOptions.shared.getAllSeeds)
	
	router.get("decks", use: MyDecks.shared.getDecks(_:))
	
	// Scryfall
	
	let scryfallController = ScryfallBridgeController()
	
	router.post("sets", use: scryfallController.getSets)
	
//	do {
//		let directory = DirectoryConfig.detect()
//		let configDir = "Sources/App/Generation"
//		let customsetcode = "HLW"
//		let url = URL(fileURLWithPath: directory.workDir)
//			.appendingPathComponent(configDir, isDirectory: true)
//			.appendingPathComponent("\(customsetcode).json", isDirectory: false)
//		let string = try String(contentsOf: url)
//		let cards = try cardsFromCockatriceJSON(json: string)
//
//		let encoder = JSONEncoder()
//		encoder.outputFormatting = .prettyPrinted
//		let data = try encoder.encode(cards.cards)
//		print("###START###")
//		let outputString = String(data: data, encoding: .utf8)!
//		print(outputString)
//		print("###END###")
//	} catch {
//		print(error)
//	}
}
