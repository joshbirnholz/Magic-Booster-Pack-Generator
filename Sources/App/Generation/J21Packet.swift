import Foundation

struct Weight: ExpressibleByStringLiteral {
	let name: String
	let frequency: Int
	
	init(_ name: String, _ frequency: Int) {
		self.name = name
		self.frequency = frequency
	}
	
	init(stringLiteral value: StringLiteralType) {
		self.init(value, 100)
	}
}

struct Packet {
	struct Slot: ExpressibleByStringLiteral, ExpressibleByArrayLiteral {
		
		
		let cards: [Weight]
		
		init(_ cards: [Weight]) {
			self.cards = cards
		}
		
		init(stringLiteral value: StringLiteralType) {
			self.cards = [Weight(value, 100)]
		}
		
		typealias ArrayLiteralElement = Weight
		
		init(arrayLiteral elements: Weight...) {
			self.cards = elements
		}
		
		func chooseCard() -> String {
			guard !cards.isEmpty else {
				fatalError("Slot cannot be empty")
			}
			guard cards.count > 1 else {
				return cards[0].name
			}
			
			let total = cards.map { $0.frequency }.reduce(0, +) // Should always equal 100
			let rand = (0..<total).randomElement()!
			
			var sum = 0
			for card in cards {
				sum += card.frequency
				if rand < sum {
					return card.name
				}
			}
			
			fatalError("This should never be reached")
		}
	}
	
	let name: String
	let slots: [Slot]
	
	func chooseCards() -> [String] {
		var cards = slots.map { $0.chooseCard() }
		cards.removeAll(where: { $0 == "EMPTY" })
		return cards
	}
}

let packets: [Packet] = [
	Packet(name: "Above the Clouds", slots: [
		"Spectral Sailor",
		["Kitesail Corsair", "Keen Glidemaster", "Mentor of Evos Isle"],
		"Waterkin Shaman",
		"Ghost-Lit-Drifter",
		["Tide Skimmer", "Windstorm Drake"],
		"Aeromoeba",
		"Wonder",
		["Roaming Ghostlight", "Windcaller Aven", "Ojutai's Summons", "Inniaz, the Gale Force"],
		[Weight("Capture Sphere", 60), Weight("Tightening Coils", 40)]
	]),
	Packet(name: "Animated", slots: [
		"Floodhound",
		[Weight("Burdened Aerialist", 50), Weight("Sailor of Means", 25), Weight("Aviation Pioneer", 25)],
		"Animating Faerie",
		"Skilled Animator",
		"Hard Evidence",
		"Rise and Shine",
		"Resculpt",
		["Witching Well", "Weapon Rack"],
		"Giant's Amulet",
		["Icy Manipulator", "Turn into a Pumpkin"],
		[Weight("Ethereal Grasp", 67), Weight("Tome of the Infinite", 33)]
	]),
	Packet(name: "Bears", slots: [
		"Mother Bear",
		["Grizzly Bears", "Runeclaw Bear", "Bear Cub"],
		[Weight("Vivien's Grizzly", 50), Weight("Awaken the Bear", 25), Weight("Titanic Growth", 25)],
		"Bloodline Pretender",
		["Professor of Zoomancy", "Striped Bears", "Owlbear"],
		["Littjara Glade-Warden", "Exuberant Wolfbear"],
		"Webweaver Changeling",
		"Ayula, Queen Among Bears",
		[Weight("Incremental Growth", 75), Weight("Enlarge", 25)],
		["Faceless Agent", "Veteran Charger", "Goreclaw, Terror of Qal Sisma"],
		["Skyshroud Ambush", "Savage Swipe"]
	]),
	Packet(name: "Cycling", slots: [
		"Flourishing Fox",
		"Drannith Healer",
		"Snare Tactician",
		"Oketra's Attendant",
		["Imposing Vantasaur", "Winged Shepherd", "Yoked Plowbeast"],
		"Valiant Rescuer",
		["Forsake the Worldly", "Gilded Light", "Coordinated Charge", "Djeru's Renunciation", "EMPTY"],
		[Weight("Pacifism", 60), Weight("Cast Out", 30), Weight("Radiant's Judgment", 10)],
		"Leonin Sanctifier",
		["Wingsteed Trainer", "Splendor Mare"],
		"Benalish Partisan"
	]),
	Packet(name: "Davriel", slots: [
		"Davriel, Rogue Shadowmage",
		["Drainpipe Vermin", "Liliana's Steward"],
		["Black Cat", "Burglar Rat", "Elderfang Disciple"],
		"Fell Specter",
		[Weight("Goremand", 75), Weight("Urgoros, the Empty One", 25)],
		[Weight("Reaper of Night", 40), Weight("Davriel's Shadowfugue", 20), Weight("Tourach's Canticle", 20), Weight("Mind Rake", 20)],
		"Pelakka Predation",
		"Murder",
		[Weight("Plaguecrafter's Familiar", 67), Weight("Subversive Acolyte", 33)],
		[Weight("Manor Guardian", 100), Weight("Plaguecrafter", 0)],
		"Davriel's Withering",
		"Davriel, Soul Broker"
	]),
	Packet(name: "Delirium", slots: [
		["Foul Watcher", "Oraed of Mountain's Blaze"],
		"Raving Visionary",
		["Gouged Zealot", "Storm-God's Oracle"],
		"Dragon's Rage Channeler",
		"Bloodbraid Marauder",
		"Prophetic Titan",
		[Weight("Unholy Heat", 75), Weight("Omen of the Forge", 25)],
		["Thrill of Possibility", "Implement of Examination", "Omen of the Sea"],
		["Chromatic Sphere", "Lightning Spear"],
		[Weight("Scuttletide", 50), Weight("Scour the Laboratory", 25), Weight("Manic Scribe", 25)],
		["Sarkhan's Scorn", "Ethereal Grasp"],
		"Cycling Land"
	]),
	Packet(name: "Enchanted", slots: [
		["Setessan Skirmisher", "Pious Wayfarer", "Starfield Mystic"],
		"Destiny Spinner",
		"Lagonna-Band Storyteller",
		["Captivating Unicorn", "Nylea's Forerunner"],
		[Weight("Sythis, Harvest's Hand", 60), Weight("Sanctum Weaver", 30), Weight("Sterling Grove", 10)],
		["Squirrel Sanctuary", "Skyblade's Boon", "Alseid of Life's Bounty"],
		"Omen of the Sun",
		"Reprobation",
		"Captured by Lagacs",
		"Veteran Charger",
		[Weight("Fall of the Imposter", 50), Weight("Baffling End", 25), Weight("Seal Away", 25)],
		"Cycling Land"
	]),
	Packet(name: "Energy", slots: [
		[Weight("Servant of the Conduit", 60), Weight("Longtusk Cub", 40)],
		"Sage of Shaila's Claim",
		["Thriving Rhino", "Aetherstream Leopard"],
		["Peema Aether-Seer", "Evolution Sage"],
		["Urban Daggertooth", "Riparian Tiger", "Bloom Hulk", "Bristling Hydra"],
		"Wren's Run Hydra",
		["Courage in Crisis", "Highspire Infusion", "Snakeskin Veil"],
		[Weight("Smell Fear", 60), Weight("Skyshroud Ambush", 40)],
		"Longtusk Stalker",
		"Veteran Charger",
		[Weight("Pool of Vigorous Growth", 80), Weight("Sylvan Anthem", 20)]
	]),
	Packet(name: "Evolving", slots: [
		[Weight("Sauroform Hybrid", 60), Weight("Pool of Vigorous Growth", 10), Weight("Lonis, Cryptozoologist", 30)],
		[Weight("Shambleshark", 50), Weight("Bettering Krasis", 25), Weight("Crocanura", 25)],
		["Elusive Krasis", "Skatewing Spy"],
		"Urban Daggertooth",
		"Sharktocrab",
		["Adaptive Snapjaw", "Scuttlegator"],
		[Weight("Wren's Run Hydra", 75), Weight("Nimbus Swimmer", 25)],
		["Smell Fear", "Applied Biomancy"],
		"Simic Ascendancy",
		"Bred for the Hunt",
		["Mentor of Evos Isle", "Aeromunculus", "Veteran Charger"],
		"Cycling Land"
	]),
	Packet(name: "Flickering", slots: [
		"Restoration Angel",
		"Soulherder",
		["Vesperlark", "Wispweaver Angel"],
		["Specimen Collector", "Aliros, Enraptured", "Spire Patrol"],
		["Irregular Cohort", "Aven Eternal", "Aviation Pioneer", "Sandsteppe Outcast", "EMPTY"],
		["Faerie Seer", "Thraben Inspector"],
		"Monoskelion",
		"Cloudshift",
		["Pacifism", "Ethereal Grasp"],
		[Weight("Leonin Sanctifier", 66), Weight("Charming Prince", 33)],
		"Baffling Defenses",
		"Cycling Land"
	]),
	Packet(name: "Freyalise", slots: [
		"Llanowar Elves",
		[Weight("Paradise Druid", 75), Weight("Dwynen's Elite", 25)],
		["Ghirapur Guide", "Llanowar Tribe", "Taunting Arbormage", "Tireless Provisioner"],
		"Wildheart Invoker",
		"Elderleaf Mentor",
		[Weight("Grizzled Outrider", 50), Weight("Lifecraft Cavalry", 25), Weight("Tajuru Pathwarden", 25)],
		["Arbor Armament", "Gift of Growth", "Titanic Growth", "Snakeskin Veil"],
		"Song of Freyalise",
		"Skyshroud Lookout",
		["Faceless Agent", "Llanowar Visionary", "Veteran Charger", "Marwyn, the Nurturer"],
		"Skyshroud Ambush",
		"Freyalise, Skyshroud Partisan"
	]),
	Packet(name: "Goblins", slots: [
		["Fissure Wizard", "Ornery Goblin", "Goblin Bird-Grabber", "Managorger Phoenix"],
		["Gempalm Incinerator", "Volley Veteran"],
		[Weight("Battle-Rattle Shaman", 75), Weight("Goblin Wizardry", 25)],
		"Battle Squadron",
		"Goblin Dark-Dwellers",
		"Dragon Fodder",
		"Krenko's Command",
		["Hordeling Outburst", "You See a Pair of Goblins"],
		["Goblin Oriflamme", "Goblin Morningstar"],
		["Reckless Ringleader", "Foundry Street Denizen", "Weaselback Redcap"],
		[Weight("Sarkhan's Scorn", 75), Weight("Goblin Barrage", 25)]
	]),
	Packet(name: "Goblin Fodder", slots: [
		"Pashalik Mons",
		["Sling-Gang Lieutenant", "Beetleback Chief"],
		"Munitions Expert",
		[Weight("Warteye Witch", 50), Weight("Facevaulter", 25), Weight("Dark-Dweller Oracle", 25)],
		"Goblin Rally",
		[Weight("Krenko's Command", 50), Weight("Goblin Arsonist", 25), Weight("Shambling Goblin", 25)],
		["Goatnap", "Shock"],
		["Mob", "Bone Shards"],
		"Raise the Draugr",
		["Sure Strike", "Barge In", "Burn Bright"],
		"Reckless Ringleader",
		"Cycling Land"
	]),
	Packet(name: "Humans", slots: [
		["Anointed Chorister", "Thraben Inspector", "Star Pupil", "Codespell Cleric"],
		"Thalia's Lieutenant",
		["Zhalfirin Decoy", "Fencing Ace", "Shepherd of the Flock"],
		[Weight("Steadfast Sentry", 50), Weight("Makeshift Battalion", 25), Weight("Sandsteppe Outcast", 25)],
		["Dueling Coach", "Abzan Battle Priest", "Sigiled Contender"],
		"Disciple of the Sun",
		["Battlefield Promotion", "Light of Hope", "Feat of Resistance"],
		[Weight("Fight as One", 40), Weight("Gird for Battle", 20), Weight("Valorous Stance", 20), Weight("Triumph of Gerrard", 20)],
		"Bonds of Faith",
		[Weight("Faceless Agent", 60), Weight("Hanweir Militia Captain", 20), Weight("Elite Spellbinder", 20)],
		"Wingsteed Trainer"
	]),
	Packet(name: "In the Machine", slots: [
		[Weight("Arcbound Mouser", 50), Weight("Sparring Construct", 25), Weight("Arcbound Prototype", 25)],
		[Weight("Fairgrounds Patrol", 75), Weight("Cogworker's Puzzleknot", 25)],
		"Chrome Courier",
		[Weight("Steelfin Whale", 50), Weight("Myr Enforcer", 20), Weight("Thought Monitor", 30)],
		["Etherium Spinner", "Parcel Myr", "Foundry Inspector"],
		[Weight("Barbed Spike", 67), Weight("Batterbone", 33)],
		[Weight("Nettlecyst", 60), Weight("Esper Sentinel", 40)],
		"Glass Casket",
		"Icy Manipulator",
		"Baffling Defenses",
		"Filligree Attendent",
		"Cycling Land"
	]),
	Packet(name: "Junkyard", slots: [
		[Weight("Sparring Construct", 50), Weight("Lightning-Core Excavator", 25), Weight("Bonded Construct", 25)],
		["Ravenous Intruder", "Orcish Vandal", "Rust Monster"],
		[Weight("Myr Sire", 75), Weight("Ornithopter of Paradise", 25)],
		[Weight("Breya's Apprentice", 60), Weight("Goblin Engineer", 40)],
		[Weight("Destructive Digger", 67), Weight("Scrap Trawler", 33)],
		["Treasure Keeper", "Arcbound Whelp"],
		"Slag Strider",
		"Kuldotha Flamefiend",
		"Lightning Spear",
		[Weight("Ichor Wellspring", 50), Weight("Chromatic Sphere", 25), Weight("Implement of Combustion", 25)],
		"Sarkhan's Scorn"
	]),
	Packet(name: "Kiora", slots: [
		"Sigiled Starfish",
		["Coralhelm Guide", "Skyclave Squid", "Glimmerbell"],
		"Man-o'-War",
		"Oneirophage",
		[Weight("Tolarian Kraken", 40), Weight("Waker of Waves", 30), Weight("Wormhole Serpent", 30)],
		["Waterknot", "Bubble Snare"],
		["Tightening Coils", "Into the Roil"],
		["Shoreline Scout", "Floodhound", "Hard Evidence"],
		["Mentor of Evos Isle", "Mistwalker"],
		"Kiora, the Tide's Fury",
		[Weight("Bounty of the Deep", 67), Weight("Tome of the Infinite", 33)]
	]),
	Packet(name: "Legion", slots: [
		[Weight("Thraben Inspector", 40), Weight("Doomed Traveler", 20), Weight("Codespell Cleric", 20), Weight("Selfless Cathar", 20)],
		["Selfless Savior", "Boros Elite", "Alseid of Life's Bounty", "Dauntless Bodyguard"],
		["Anointed Chorister", "Sea Gate Banneret"],
		["Healer's Hawk", "Segovian Angel", "Battlefield Raptor", "Faerie Guidemother"],
		"Law-Rune Enforcer",
		"Ranger-Captain of Eos",
		[Weight("Thraben Watcher", 60), Weight("Battle Screech", 20), Weight("Healer's Flock", 20)],
		["Stirring Address", "Return to the Ranks", "Fortify"],
		"Abiding Grace",
		[Weight("Conclave Tribunal", 67), Weight("Devouring Light", 33)],
		"Lumbering Lightshield"
	]),
	Packet(name: "Lost and Found", slots: [
		["Necrogoyf", "Bazaar Trademage"],
		[Weight("Cabal Initiate", 75), Weight("Miasmic Mummy", 25)],
		"Lazotep Chancellor",
		"Gilt-Blade Prowler",
		["Hell Mongrel", "Kitchen Imp"],
		"Raving Visionary",
		["Necromancer's Familiar", "Stitchwing Skaab", "Haunted Dead"],
		"Bone Shards",
		["Recalibrate", "Just the Wind"],
		"Rain of Revelation",
		[Weight("Rousing Read", 66), Weight("Champion of Wits", 34)],
		"Cycling Land"
	]),
	Packet(name: "Madness", slots: [
		["Cabal Initiate", "Viashino Lashclaw", "Insolent Neonate"],
		["Skophos Reaver", "Kitchen Imp", "Asylum Visitor"],
		"Revolutionist",
		"Hell Mongrel",
		"Chainer, Nightmare Adept",
		"Blazing Rootwalla",
		["Rakdos Headliner", "Furyblade Vampire", "Heir of Falkenrath", "Ravenous Bloodseeker"],
		["Macabre Waltz", "Faithless Salvaging", "Thrill of Possibility"],
		"Terminal Agony",
		"Static Discharge",
		"Static Discharge",
		"Cycling Land"
	]),
	Packet(name: "Many Faced", slots: [
		"Irregular Cohort",
		[Weight("King of the Pride", 50), Weight("Dregscape Sliver", 25), Weight("Throatseeker", 25)],
		"Graveshifter",
		["Venomous Changeling", "Faceless Agent"],
		[Weight("Changeling Outcast", 75), Weight("Universal Automaton", 25)],
		"Blade Splicer",
		[Weight("Thwart the Grave", 50), Weight("Allied Assault", 25), Weight("Birthing Boughs", 25)],
		["Deadly Alliance", "Journey to Oblivion"],
		"Etchings of the Chosen",
		[Weight("Imposter of the Sixth Pride", 50), Weight("Enduring Sliver", 25), Weight("Sentinel Sliver", 25)],
		[Weight("Davriel's Withering", 67), Weight("Dire Fleet Poisoner", 33)],
		"Cycling Land"
	]),
	Packet(name: "Merfolk", slots: [
		[Weight("Raving Visionary", 40), Weight("Merfolk Trickster", 30), Weight("Silvergill Adept", 30)],
		["Shaper Apprentice", "Tazeem Roilmage", "Master of the Pearl Trident", "Coralhelm Guilde"],
		"Merrow Reejerey",
		["Expedition Diviner", "Storm Sculptor"],
		"Merfolk Falconer",
		"Svyelun of Sea and Sky",
		[Weight("Phantasmal Form", 50), Weight("Choking Tethers", 25), Weight("Unsummon", 25)],
		"Into the Roil",
		"Shoreline Scout",
		[Weight("Faceless Agent", 60), Weight("Watertrap Weaver", 40)],
		[Weight("Ethereal Grasp", 60), Weight("Bubble Snare", 40)]
	]),
	Packet(name: "Modular", slots: [
		["Arcbound Mouser", "Myr Scrapling", "Sparring Construct"],
		["Arcbound Prototype", "Ainok Bond-Kin", "Martyr for the Cause", "Hobblefiend"],
		["Steadfast Sentry", "Arcbound Tracker", "Iron Bully"],
		"Arcbound Slasher",
		["Dueling Coach", "Arcbound Whelp", "Aethershield Artificer"],
		"Arcbound Shikari",
		"Zabaz, the Glimmerwasp",
		[Weight("Destructive Digger", 66), Weight("Gadrak, the Crown Scourge", 34)],
		["Battlefield Promotion", "Light of Hope"],
		"Static Discharge",
		"Static Discharge",
		"Cycling Land"
	]),
	Packet(name: "Ninjas", slots: [
		["Faerie Seer", "Changeling Outcast"],
		[Weight("Passwall Adept", 80), Weight("Phantom Ninja", 20)],
		"Throatseeker",
		["Venomous Changeling", "Azra Smokeshaper"],
		["Moonblade Shinobi", "Ninja of the Deep Hours"],
		"Ingenious Infiltrator",
		"Mist-Syndicate Naga",
		[Weight("Choking Tethers", 75), Weight("Ghostform", 25)],
		["Feed the Serpent", "Ethreal Grasp"],
		["Sudden Edict", "Unsubstantiate"],
		"Plaguecrafter's Familiar",
		"Cycling Land"
	]),
	Packet(name: "On the Draw", slots: [
		"Faerie Vandal",
		[Weight("Pondering Mage", 50), Weight("Tome Anima", 25), Weight("Mulldrifter", 25)],
		["Oneirophage", "Mad Ratter", "Tolarian Kraken"],
		"Seasoned Pyromancer",
		"Thundering Djinn",
		["Spinehorn Minotaur", "Merchant of the Vale"],
		["Bloodhaze Wolverine", "Eyekite"],
		["Scour All Possibilities", "Faithless Salvaging", "Parcel Myr"],
		["Fists of Flame", "Mantle of Tides"],
		[Weight("Fire Prophecy", 75), Weight("Irencrag Pyromancer", 30)],
		"Improbable Alliance",
		[Weight("Ethereal Grasp", 75), Weight("Sarkhan's Scorn", 25)],
		"Cycling Land"
	]),
	Packet(name: "Plague", slots: [
		["Shambling Goblin", "Typhoid Rats", "Blight Keeper"],
		["Plague Wight", "Blighted Bat", "Deathbloom Thallid", "Eyeblight Assassin"],
		"Plaguecrafter",
		["First-Sphere Gargantua", "Blitz Leech"],
		["Archfiend of Sorrows", "Kraul Swarm"],
		"Yawgmoth, Thran Physician",
		"Ob Nixilis's Cruelty",
		[Weight("Plaguecrafter's Familiar", 66), Weight("Subversive Acolyte", 34)],
		"Manor Guardian",
		"Boneyard Aberration",
		[Weight("Davriel's Withering", 50), Weight("Death Wind", 25), Weight("Strangling Spores", 25)]
	]),
	Packet(name: "Pumped Up", slots: [
		"Rishkar, Peema Renegade",
		"Good-Fortune Unicorn",
		["Herd Baloth", "Armorcraft Judge", "Abzan Falconer", "Mowu, Loyal Companion"],
		[Weight("Arcus Acolyte", 50), Weight("Nessian Hornbeetle", 25), Weight("Monoskelion", 25)],
		[Weight("Wildwood Scourge", 75), Weight("Wren's Run Hydra", 25)],
		"Knight of Autumn",
		["Pollenbright Druid", "Kujar Seedsculptor", "Duskshell Crawler"],
		["Hunter's Edge", "Titanic Brawl", "Smell Fear", "Skyshroud Ambush"],
		["Wild Onslaught", "Biogenic Upgrade"],
		"Captured by Lagacs",
		["Leonin Sanctifier", "Veteran Charger"],
		"Cycling Land"
	]),
	Packet(name: "Rats", slots: [
		["Drainpipe Vermin", "Typhoid Rats", "Rat Colony", "Ruin Rat"],
		"Rat Colony",
		"Rat Colony",
		"Graveshifter",
		"Marrow-Gnawer",
		["Feed the Swarm", "Supernatural Stamina", "Piper of the Swarm"],
		"Raise the Draugr",
		"Mob",
		["Plaguecrafter's Familiar", "Nezumi Cutthroat", "Skullsnatcher", "Rat Colony"],
		[Weight("Faceless Agent", 75), Weight("Echoing Return", 25)],
		"Boneyard Aberration"
	]),
	Packet(name: "Reanimated", slots: [
		"Young Necromancer",
		"Archfiend of Sorrows",
		"Priest of Fell Rites",
		"Breathless Knight",
		"Void Beckoner",
		["Miasmic Mummy", "Cabal Initiate", "Thraben Standard Bearer"],
		["Imposing Vantasaur", "Yoked Plowbeast"],
		[Weight("Late to Dinner", 66), Weight("Nullpriest of Oblivion", 34)],
		[Weight("Graceful Restoration", 40), Weight("Bond of Revival", 20), Weight("Unbreakable Bond", 20), Weight("Ascent of the Worthy", 20)],
		"Bone Shards",
		["Baffling Defenses", "Davriel's Withering"],
		"Cycling Land"
	]),
	Packet(name: "Relentless", slots: [
		["Excavating Anurid", "Murasa Behemoth", "Lord of Extinction"],
		"Mother Bear",
		"Rotwidow Pack",
		["Jungle Creeper", "Glowspore Shaman", "Skull Prophet", "Clattering Augur"],
		["Cabal Initiate", "Sinister Starfish"],
		["Timeless Witness", "Acolyte of Affliction"],
		["Ransack the Lab", "Discerning Taste", "Corpse Churn"],
		"Winding Way",
		["Feed the Serpent", "Skyshroud Ambush"],
		"Altar of the Goyf",
		["Pool of Vigorous Growth", "Nether Spirit"],
		"Cycling Land"
	]),
	Packet(name: "Sarkhan", slots: [
		["Kargan Dragonrider", "Dragon Hatchling"],
		["Bogardan Dragonheart", "Thunderbreak Regent", "Sparktongue Dragon"],
		[Weight("Dragon Egg", 75), Weight("Sarkhan's Whelp", 25)],
		[Weight("Rapacious Dragon", 75), Weight("Furnace Whelp", 25)],
		"Volcanic Dragon",
		[Weight("Hellkite Punisher", 75), Weight("Shiv's Embrace", 25)],
		[Weight("Dragon Fodder", 50), Weight("Tormenting Voice", 25), Weight("Dragon Mantle", 25)],
		["Scorching Dragonfire", "Flame Sweep", "Shivan Fire", "Sarkhan's Rage"],
		"Scion of Shiv",
		"Sarkhan's Scorn",
		"Sarkhan, Wanderer to Shiv"
	]),
	Packet(name: "Scaled Up", slots: [
		["Myr Scrapling", "Servant of the Scale", "Snakeskin Veil"],
		["Duskshell Crawler", "Gnarlid Colony", "Guardian Gladewalker", "Pollenbright Druid"],
		[Weight("Deepwood Denizen", 50), Weight("Trufflesnout", 20), Weight("Oran-Rief Ooze", 30)],
		"Sabertooth Mauler",
		"Bannerhide Krushok",
		["Herd Baloth", "Iridescent Hornbeetle"],
		"Wren's Run Hydra",
		["Smell Fear", "Titanic Brawl", "Hunter's Edge"],
		["Scale Up", "Invigorating Surge", "Inspiring Call", "Wild Onslaught"],
		"Vastwood Fortification",
		"Hardened Scales",
		"Veteran Charger"
	]),
	Packet(name: "Scavenger", slots: [
		[Weight("Blazing Rootwalla", 50), Weight("Flameblade Adept", 25), Weight("Furyblade Vampire", 25)],
		["Fissure Wizard", "Oread of Mountain's Blaze", "Insolent Neonate", "Conspiracy Theorist"],
		[Weight("Hollowhead Sliver", 60), Weight("Reckless Racer", 20), Weight("Fast", 20)],
		[Weight("Merchant of the Vale", 75), Weight("Burning-Tree Vandal", 25)],
		["Mad Prophet", "Keldon Raider"],
		["Incorrigible Youths", "Instatiable Gorgers", "Reckless Wurm"],
		"Revolutionist",
		"Lightning Axe",
		[Weight("Fiery Temper", 75), Weight("Alchemist's Greeting", 25)],
		[Weight("Faithless Salvaging", 50), Weight("Thrill of Possibility", 25), Weight("Cathartic Reunion", 25)],
		"Managorger Phoenix"
	]),
	Packet(name: "Scorched Earth", slots: [
		[Weight("Ruination Rioter", 75), Weight("Nantuko Cultivator", 25)],
		[Weight("Territorial Kavu", 75), Weight("Reap the Past", 25)],
		[Weight("Springbloom Druid", 60), Weight("Skola Grovedancer", 40)],
		"Igneous Elemental",
		[Weight("Excavating Anurid", 60), Weight("Squirrel Wrangler", 20), Weight("Pool of Vigorous Growth", 20)],
		"Murasa Behemoth",
		["Timeless Witness", "Ore-Scale Guardian"],
		"Throes of Chaos",
		[Weight("Harrow", 50), Weight("Geomancer's Gambit", 25), Weight("Winding Way", 25)],
		["Sarkhan's Scorn", "Skyshroud Ambush"],
		"Fast // Furious",
		"Cycling Land"
	]),
	Packet(name: "Serra's Realm", slots: [
		"Segovian Angel",
		"Youthful Valkyrie",
		["Angelheart Protector", "Sandsteppe Outcast", "Celestial Enforcer"],
		[Weight("Stalwart Valkyrie", 40), Weight("Seraph of Dawn", 20), Weight("Sustainer of the Realm", 20), Weight("Righteous Valkyrie", 20)],
		"Serra Angel",
		["Soul of Migration", "Winged Shepherd", "Angel of the Dawn", "Anoniter of Valor"],
		[Weight("Valkyrie's Sword", 40), Weight("Herald of the Sun", 20), Weight("Glorious Enforcer", 20), Weight("Angel of the God-Pharoah", 20)],
		[Weight("Pacifism", 50), Weight("Angelic Purge", 25), Weight("Angelic Edict", 25)],
		[Weight("On Serra's Wings", 60), Weight("Angelic Exaltation", 40)],
		"Leonin Sanctifier",
		[Weight("Serra, the Benevolent", 70), Weight("Serra's Emissary", 30)]
	]),
	Packet(name: "Sliver Assault", slots: [
		["Bladeback Sliver", "Striking Sliver", "Sentinel Sliver"],
		["Cleaving Sliver", "Bonescythe Sliver", "Spiteful Sliver"],
		"Cloudshredder Sliver",
		"Enduring Sliver",
		"First Sliver's Chosen",
		["Hollowhead Sliver", "Steelform Sliver", "Belligerent Sliver"],
		["Lancer Sliver", "Blur Sliver", "Hive Stirrings"],
		"Lavabelly Sliver",
		["Rip Apart", "Justice Strike", "Integrity"],
		["Pacifism", "Sarkhan's Scorn"],
		["Baffling Defenses", "Amorphous Axe"],
		"Cycling Land"
	]),
	Packet(name: "Sliver Hive", slots: [
		"Manaweft Sliver",
		["Diffusion Sliver", "Leeching Sliver"],
		["Dregscape Sliver", "Predatory Sliver", "Enduring Sliver"],
		["Hollowhead Sliver", "Tempered Sliver", "Scuttlign Sliver"],
		["Cleaving Sliver", "Blur Sliver", "Lancer Sliver"],
		"First Sliver's Chosen",
		"The First Sliver",
		["Heartless Act", "Lava Coil"],
		"Raise the Draugr",
		"Prophetic Prism",
		"Sliver Hive",
		"Evolving Wilds",
		"Unknown Shores",
		"Rupture Spire",
		"Plains",
		"Island",
		"Swamp",
		"Mountain",
		"Forest",
		"Faceless Agent"
	]),
	Packet(name: "Spellcasting", slots: [
		[Weight("Lightning Visionary", 60), Weight("Goblin Arsonist", 40)],
		[Weight("Thermo-Alchemist", 50), Weight("Young Pyromancer", 25), Weight("Incendiary Oracle", 25)],
		[Weight("Storm Caller", 60), Weight("Seasoned Pyromancer", 20), Weight("Blisterstick Shaman", 20)],
		"Rage Forger",
		["Living Lightning", "Guttersnipe", "Kinetic Augur"],
		[Weight("Battle-Rattle Shaman", 75), Weight("Clamor Shaman", 25)],
		"Harmonic Prodigy",
		["Reckless Charge", "Sure Strike", "Fists of Flame", "Renegade Tactics"],
		"Faithless Salvaging",
		"Static Discharge"
	]),
	Packet(name: "Squirrels", slots: [
		"Squirrel Sovereign",
		["Ravenous Squirrel", "Squirrel Sanctuary"],
		["Nested Shambler", "Scurrid Colony", "Chatter of the Squirrel", "Verdant Command"],
		"Scurry Oak",
		["Chatterfang, Squirrel General", "Chitterspitter"],
		"Drey Keeper",
		"Webweaver Changeling",
		[Weight("Bone Shards", 50), Weight("Skyshroud Ambush", 25), Weight("Davriel's Withering", 25)],
		["Might of the Masses", "Squirrel Mob", "Pack's Favor", "Gift of Growth"],
		"Mob",
		"Faceless Agent",
		"Cycling Land"
	]),
	Packet(name: "Storm", slots: [
		[Weight("Goblin Anarchomancer", 67), Weight("Birgi, God of Storytelling", 33)],
		[Weight("Captain Ripley Vance", 60), Weight("Grinning Ignus", 20), Weight("Storm-Kiln Artist", 20)],
		["Dragonsguard Elite", "Aeve, Progenitor Ooze"],
		[Weight("Chatterstorm", 75), Weight("Galvanic Relay", 25)],
		"Trumpeting Herd",
		"Strike It Rich",
		"Spreading Insurrection",
		["Faithless Salvaging", "Charge Through", "Warlord's Fury", "EMPTY"],
		"Hunting Pack",
		["Prey's Vengeance", "Shock"],
		"Sarkhan's Scorn",
		"Cycling Land"
	]),
	Packet(name: "Teyo", slots: [
		"Teyo, the Shieldmage",
		"Thraben Inspector",
		"Kor Skyfisher",
		"Roc Egg",
		"Wall of One Thousand Cuts",
		["Scour the Desert", "Gauntlets of Light"],
		"Pacifism",
		"Lumbering Lightshield",
		"Wingsteed Trainer",
		"Teyo, Aegis Adept",
		[Weight("Baffling Defenses", 40), Weight("Valorous Stance", 20), Weight("Moment of Heroism", 20), Weight("Shelter", 20)]
	]),
	Packet(name: "Tinkerer", slots: [
		["Mother Bear", "Jewel-Eyed Cobra", "Twin-Silk Spider", "Burdened Aerialist"],
		[Weight("Lonis, Cryptozoologist", 70), Weight("Aeve, Progenitor Ooze", 30)],
		"Specimen Collector",
		["Junk Winder", "Combine Chrysalis"],
		["Glimmer Bairn", "Floodhound"],
		"Wavesifter",
		["Funnel-Web Recluse", "Trumpeting Herd", "Prosperous Pirates", "Fierce Witchstalker"],
		"Tireless Provisioner",
		["Sanctuary Raptor", "Witch's Oven", "Ulvenwald Mysteries", "Birthing Sloughs"],
		"Hard Evidence",
		"So Shiny",
		[Weight("Cycling Land", 80), Weight("Khalni Garden", 20)],
		[Weight("Skyshroud Ambush", 80), Weight("Pool of Vigorous Growth", 20)]
	]),
	Packet(name: "Undone", slots: [
		"Floodhound",
		["Burrog Befuddler", "Faerie Duelist"],
		"Brineborn Cutthroat",
		"Exclusion Mage",
		[Weight("Vexing Gull", 40), Weight("Breaching Hippocamp", 20), Weight("Mentor of Evos Isle"), Weight("Crookclaw Transmuter", 20)],
		["Pondering Mage", "Living Tempest", "Windcaller Aven", "Voracious Greatshark"],
		"Aeromoeba",
		"Archmage's Charm",
		["Supreme Will", "Hypnotic Sprite", "Censor", "Neutralize"],
		["Exclude", "Essence Capture", "Dismiss", "Rewind"],
		"Jwari Disruption",
		"Ethereal Grasp"
	]),
	Packet(name: "Vampire", slots: [
		"Vampire of the Dire Moon",
		["Blood Artist", "Carrier Thrall", "Legion Vanguard", "Indulgent Aristocrat"],
		["Vermin Gorger", "Blood Burglar"],
		["Skymarch Bloodletter", "Marauding Blight-Priest", "Callous Bloodmage"],
		[Weight("Graveshifter", 50), Weight("Deathles Ancient", 25), Weight("Markov Crusader", 25)],
		["Blood Glutton", "Epicure of Blood", "Anointed Deacon", "Queen's Agent"],
		"Cordial Vampire",
		"Bloodchief's Thirst",
		["Mark of the Vampire", "Abnormal Endurance", "Subtle Strike", "Unexpected Fangs"],
		"Faceless Agent",
		[Weight("Davriel's Withering", 75), Weight("Moment of Craving", 25)]
	]),
	Packet(name: "Zombie", slots: [
		[Weight("Nested Shambler", 40), Weight("Grim Physician", 20), Weight("Shambling Goblin", 20), Weight("Liliana's Steward", 20)],
		[Weight("Putrid Goblin", 50), Weight("Maurading Boneslasher", 25), Weight("Plague Wight", 25)],
		"Undead Augur",
		[Weight("Mire Triton", 50), Weight("Eternal Taskmaster", 25), Weight("Liliana's Devotee", 25)],
		["Lord of the Accursed", "Accursed Horde", "Liliana's Elite"],
		"Fleshbag Marauder",
		[Weight("Endling", 50), Weight("Diregraf Colossus", 25), Weight("Dark Salvation", 25)],
		["Karfell Kennel-Master", "Boneclad Necromancer"],
		["Abnormal Endurance", "Village Rites", "Alchemist's Gift"],
		["Raise the Draugr", "Cemetary Recruitment"],
		["Davriel's Withering", "Mob", "Murderous Rider"]
	]),
	Packet(name: "Zoologist", slots: [
		["Glimmer Bairn", "Saproling Migration"],
		"Mother Bear",
		"Woodland Champion",
		["Yavimaya Sapherd", "Ferocious Pup", "Jungleborn Pioneer", "Penumbra Bobcat"],
		["Scurry Oak", "Sprouting Renewal", "Spore Swarm"],
		[Weight("Trumpeting Herd", 70), Weight("Esika's Chariot", 30)],
		"Bestial Menace",
		"Overcome",
		[Weight("Chitterspitter", 50), Weight("Verdant Command", 20), Weight("Parallel Lives", 30)],
		["Squirrel Sanctuary", "Elven Bow", "Flaxen Intruder"],
		"Skyshroud Ambush"
	])
]
