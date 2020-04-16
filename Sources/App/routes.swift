import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
	let generatorController = GeneratorController()
	router.get(String.parameter, use: generatorController.boosterPack)
	router.get("booster", String.parameter, use: generatorController.boosterPack)
	router.get("boosterpack", String.parameter, use: generatorController.boosterPack)
	router.get("pack", String.parameter, use: generatorController.boosterPack)
	
	router.get("boosterbox", String.parameter, use: generatorController.boosterBox)
	router.get("box", String.parameter, use: generatorController.boosterBox)
	
	router.get("prerelease", String.parameter, use: generatorController.prereleasePack)
	router.get("pre", String.parameter, use: generatorController.prereleasePack)
	
	router.get("deck", use: generatorController.fullDeck)
}
