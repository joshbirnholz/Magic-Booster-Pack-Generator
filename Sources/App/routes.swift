import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
	router.get { req -> Response in
		return req.response(http: HTTPResponse(status: .movedPermanently,
												   version: HTTPVersion(major: 1, minor: 1),
												   headers: HTTPHeaders([("Location", "index.html")])))
	}
	
	let generatorController = GeneratorController()
	
	router.get("card", "named", use: generatorController.singleCardNamed)
	
	router.get("card", String.parameter, String.parameter, use: generatorController.singleCard)
	
	router.get("card", "random", use: generatorController.singleCardRandom)
	
	router.get("landpacks", String.parameter, use: generatorController.landPacks)
	router.get("landpacks", use: generatorController.landPacks)
	
	router.get(String.parameter, use: generatorController.boosterPack)
	router.get("booster", String.parameter, use: generatorController.boosterPack)
	router.get("boosterpack", String.parameter, use: generatorController.boosterPack)
	router.get("pack", String.parameter, use: generatorController.boosterPack)
	
	router.get("boosterbox", String.parameter, use: generatorController.boosterBox)
	router.get("box", String.parameter, use: generatorController.boosterBox)
	
	router.get("prerelease", String.parameter, use: generatorController.prereleasePack)
	router.get("pre", String.parameter, use: generatorController.prereleasePack)
	
	router.get("token", String.parameter, use: generatorController.completeToken)
	
	
	
	router.get("deck", use: generatorController.fullDeck)
	router.post("deck", use: generatorController.fullDeck)
}
