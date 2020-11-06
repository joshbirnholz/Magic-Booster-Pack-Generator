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
	
	
	// Scryfall
	
	let scryfallController = ScryfallBridgeController()
	
	router.post("sets", use: scryfallController.getSets)
}
