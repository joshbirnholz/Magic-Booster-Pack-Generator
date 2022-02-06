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

	app.post("url", ":deck", use: generatorController.deckstatsDeck)

	app.get("customcards", use: CustomCards.shared.getCustomCards)
	app.get("seeds", use: SeedOptions.shared.getAllSeeds)

	app.get("decks", use: MyDecks.shared.getDecks(_:))

	// Scryfall

	let scryfallController = ScryfallBridgeController()

	app.post("sets", use: scryfallController.getSets)
	
	do {
		let directory = DirectoryConfiguration.detect()
		let configDir = "Sources/App/Generation"
		let customsetcode = "HLW"
		let url = URL(fileURLWithPath: directory.workingDirectory)
			.appendingPathComponent(configDir, isDirectory: true)
			.appendingPathComponent("\(customsetcode).json", isDirectory: false)
		let string = try String(contentsOf: url)
		let cards = try cardsFromCockatriceJSON(json: string)

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		let data = try encoder.encode(cards.cards)
		print("###START###")
		let outputString = String(data: data, encoding: .utf8)!
		print(outputString)
		print("###END###")
	} catch {
		print(error)
	}
}
