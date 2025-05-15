import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {
	
	app.get { req -> Response in
		req.redirect(to: "index.html", type: .permanent)
	}
	
	let generatorController = GeneratorController()
	
	app.post("card", "named", use: generatorController.singleCardNamed)

	app.post("card", ":code", ":number", use: generatorController.singleCard)

	app.post("card", "random", use: generatorController.singleCardRandom)

	app.post("landpacks", ":set", use: generatorController.landPacks)
	app.post("landpacks", use: generatorController.landPacks)

	app.post(":set", use: generatorController.boosterPack)
	app.post("booster", ":set", use: generatorController.boosterPack)
	app.post("boosterpack", ":set", use: generatorController.boosterPack)
	app.post("pack", ":set", use: generatorController.boosterPack)

	app.post("boosterbox", ":set", use: generatorController.boosterBox)
	app.post("box", ":set", use: generatorController.boosterBox)

//	app.post("boxingleague", ":set", use: generatorController.commanderBoxingLeagueBox)

	app.post("prerelease", ":set", use: generatorController.prereleasePack)
	app.post("pre", ":set", use: generatorController.prereleasePack)

	app.post("token", ":set", use: generatorController.completeToken)

	app.post("deck", use: generatorController.fullDeck)
  
  app.post("convert", use: generatorController.convert)

	app.post("url", ":deck", use: generatorController.deckstatsDeck)

	app.get("seeds", use: SeedOptions.shared.getAllSeeds)
  
  app.get("draftmancercards", use: getBuiltinDraftmancerCards)

	app.get("decks", use: MyDecks.shared.getDecks(_:))

	// Scryfall

	let scryfallController = ScryfallBridgeController()

	app.post("sets", use: scryfallController.getSets)
  
  app.post("collectionremove", use: collectionRemove(_:))
  
  app.routes.defaultMaxBodySize = .init(stringLiteral: "4mb")
	
//	do {
//		let file = URL(fileURLWithPath: "/Users/compc/iCloud Drive (Archive) - 1/Documents/Xcode/TabletopSimulatorMagicBoosterPackServer/Sources/App/Generation/xmltojson.json")
//		let json = try String(contentsOf: file)
//		let cards = try cardsFromCockatriceJSON(json: json)
//		let set = MTGSet(cards: cards.cards, name: cards.setName, code: cards.setCode ?? "")
//		let encoder = JSONEncoder()
//		encoder.outputFormatting = .prettyPrinted
//		let data = try encoder.encode(set)
//		if let string = String(data: data, encoding: .utf8) {
//			print(string)
//		}
//	} catch {
//		print(error)
//	}
}
