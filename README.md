## API: https://tts-magic-booster.fly.dev

An API to generate _Magic: The Gathering_ cards, booster packs, and prerelease packs for _Tabletop Simulator_.

Packs are meant to have cards that match what you'd really find in booster packs from that set.

|Endpoint|Description|Example|
|---|---|---|
|/pack/:set|Generate a booster pack|https://tts-magic-booster.fly.dev/pack/iko|
|/box/:set|Generate booster boxes|https://tts-magic-booster.fly.dev/box/iko|
|/pre/:set|Generate prerelease packs|https://tts-magic-booster.fly.dev/pre/iko|
|/card/named|Get a specific card|https://tts-magic-booster.fly.dev/card/named?fuzzy=gemrazer|
|/card/:code/:number|Get a specific card|https://tts-magic-booster.fly.dev/card/iko/155|
|/card/random|Get a random card|https://tts-magic-booster.fly.dev/card/random|
|/token/:set|Get a token that can be every token in a set|https://tts-magic-booster.fly.dev/token/iko|
|/landpacks|Get a pack of basic lands|https://tts-magic-booster.fly.dev/landpacks|
|/deck|Load an entire deck list|https://tts-magic-booster.fly.dev/deck|

### POST /pack/:set

Generates a booster pack for a given set.

|Parameter|Type|Required|Details|
|---|---|---|---|
|:set|String|✔︎|The set name or code.|
|export|Boolean||If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|count|Integer||The number of booster packs to generate. The default value is 1.|
|extendedart|Boolean||Whether or not to use extended-art cards, if available, in place of foils. The default value is true.|
|lands|Boolean||Whether or not to include basic lands in the booster packs. The default value is true.|
|token|Boolean||Whether or not to include a token in the booster packs. The default value is true.|

Example: https://tts-magic-booster.fly.dev/pack/iko?count=3

### POST /box/:set

Generates a box of booster packs for a given set.

|Parameter|Type|Required|Details|
|---|---|---|---|
|:set|String|✔︎|The set name or code.|
|export|Boolean||If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|count|Integer||The number of booster packs to generate. The default value depends on the set (usually 36).|
|extendedart|Boolean||Whether or not to use extended-art cards, if available, in place of foils. The default value is true.|
|lands|Boolean||Whether or not to include basic lands in the booster packs. The default value is true.|
|token|Boolean||Whether or not to include a token in the booster packs. The default value is true.|

Example: https://tts-magic-booster.fly.dev/box/thb

### POST /pre/:set

Generates a number of prerelease packs for a given set.

|Parameter|Type|Required|Details|
|---|---|---|---|
|:set|String|✔︎|The set name or code.|
|export|Boolean||If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|count|Integer||The number of prerelease packs to generate. The default value is 1.|
|boosters|Integer||The number of booster packs to include in each prerelease pack. The default value is 6.|
|promo|Boolean||Whether or not to include a promo card in each prerelease pack. The default value is true.|
|sheet|Boolean||Whether or not to include a "Building a Prerelease Deck" sheet in each prerelease pack. The default value is true.|
|lands|Boolean||Whether or not to include a pack of basic lands in each prerelease pack. The default value is true.|
|spindown|Boolean||Whether or not to include a spindown die in each prerelease pack. The default value is true.|
|extendedart|Boolean||Whether or not to use extended-art cards, if available, in place of foils. The default value is true.|

Example: https://tts-magic-booster.fly.dev/pre/eld?count=10&sheet=false

### POST /card/named

Returns a single card with a given name. A value is required for either the `fuzzy` parameter or the `exact` parameter.

|Parameter|Type|Required|Details|
|---|---|---|---|
|export|Boolean||If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|fuzzy|String||A fuzzy name of a card.|
|exact|String||An exact name of a card.|

Example: https://tts-magic-booster.fly.dev/card/named?fuzzy=under+dream

### POST /card/:code/:number

Returns a single card with the given set code and collector number.

|Parameter|Type|Required|Details|
|---|---|---|---|
|export|Boolean||If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|:code|String||The set code.|
|:number|String||The collector number.|

Example: https://tts-magic-booster.fly.dev/card/thb/253

### POST /card/random

Returns a single random card.

|Parameter|Type|Required|Details|
|---|---|---|---|
|export|Boolean||If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|q|String||A scryfall search query. If provided, a random card matching the query will be returned.

Example: https://tts-magic-booster.fly.dev/card/random  
Example: https://tts-magic-booster.fly.dev/card/random?q=cmc:6+type:creature  
Example: https://tts-magic-booster.fly.dev/card/random?q=o:companion+set:iko&export=false

### POST /token/:set

Returns a token that can be right-clicked in Tabletop Simulator to be changed to any token in the specified set.

|Parameter|Type|Required|Details|
|---|---|---|---|
|:set|String|✔︎|The set for which a token should be created.|
|export|Boolean||If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|

Example: https://tts-magic-booster.fly.dev/token/c20

### POST /landpacks/

Returns a pack of 20 of each basic land. The returned JSON can only be used to spawn an object directly via scripting.

|Parameter|Type|Required|Details|
|---|---|---|---|
|set|String||The set for which basic lands should be taken.|

Example: https://tts-magic-booster.fly.dev/landpacks?set=thb

### POST /deck

Returns a deck of cards. The request must have a body containing the requested decklist in plaintext card list or Arena format. The returned JSON can be saved to a file and imported as a Saved Object.

|Parameter|Type|Required|Details|
|---|---|---|---|
|back|URL||The URL of an image to use as the card back.|

Example: https://tts-magic-booster.fly.dev/deck

Body:
```json
{
    "deck": "26 Island\n4 Reliquary Tower (C19) 268\n24 Swamp\n4 Treasure Hunt (C18) 109\n2 Zombie Infestation (C19) 132"
}
```
