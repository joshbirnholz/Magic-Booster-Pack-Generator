## API: https://tts-magic-booster.herokuapp.com

An API to generate _Magic: The Gathering_ cards, booster packs, and prerelease packs for _Tabletop Simulator_.

Packs are meant to have cards that match what you'd really find in booster packs from that set.

|Endpoint|Description|Example|
|---|---|---|
|/:set|Generate a booster pack|https://tts-magic-booster.herokuapp.com/iko|
|/box/:set|Generate booster boxes|https://tts-magic-booster.herokuapp.com/box/iko|
|/pre/:set|Generate prerelease packs|https://tts-magic-booster.herokuapp.com/pre/iko|
|/card/named|Get a specific card|https://tts-magic-booster.herokuapp.com/card/named?fuzzy=gemrazer|
|/card/:code/:number|Get a specific card|https://tts-magic-booster.herokuapp.com/card/iko/155|
|/card/random|Get a random card|https://tts-magic-booster.herokuapp.com/card/random|
|/deck|Load an entire deck list|https://tts-magic-booster.herokuapp.com/deck|

### GET /:set

Generates a booster pack for a given set.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|:set|String||The set name or code.|
|export|Boolean|✔︎|If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|count|Integer|✔︎|The number of booster packs to generate. The default value is 1.|
|extendedart|Boolean|✔︎|Whether or not to use extended-art cards, if available, in place of foils. The default value is true.|

Example: https://tts-magic-booster.herokuapp.com/iko?count=3

### GET /box/:set

Generates a box of booster packs for a given set.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|:set|String||The set name or code.|
|export|Boolean|✔︎|If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|count|Integer|✔︎|The number of booster packs to generate. The default value depends on the set (usually 36).|
|extendedart|Boolean|✔︎|Whether or not to use extended-art cards, if available, in place of foils. The default value is true.|

Example: https://tts-magic-booster.herokuapp.com/box/thb

### GET /pre/:set

Generates a number of prerelease packs for a given set.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|:set|String||The set name or code.|
|export|Boolean|✔︎|If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|count|Integer|✔︎|The number of prerelease packs to generate. The default value is 1.|
|boosters|Integer|✔︎|The number of booster packs to include in each prerelease pack. The default value is 6.|
|promo|Boolean|✔︎|Whether or not to include a promo card in each prerelease pack. The default value is true.|
|sheet|Boolean|✔︎|Whether or not to include a "Building a Prerelease Deck" sheet in each prerelease pack. The default value is true.|
|lands|Boolean|✔︎|Whether or not to include a pack of basic lands in each prerelease pack. The default value is true.|
|spindown|Boolean|✔︎|Whether or not to include a spindown die in each prerelease pack. The default value is true.|
|extendedart|Boolean|✔︎|Whether or not to use extended-art cards, if available, in place of foils. The default value is true.|

Example: https://tts-magic-booster.herokuapp.com/pre/eld?count=10&sheet=false

### GET /card/named

Returns a single card with a given name. A value must be provided for either the `fuzzy` parameter or the `exact` parameter.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|export|Boolean|✔︎|If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|fuzzy|String|✔︎|A fuzzy name of a card.|
|exact|String|✔︎|An exact name of a card.|

Example: https://tts-magic-booster.herokuapp.com/card/named?fuzzy=under+dream

### GET /card/:code/:number

Returns a single card with the given set code and collector number.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|export|Boolean|✔︎|If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|:code|String|✔︎|The set code.|
|:number|String|✔︎|The collector number.|

Example: https://tts-magic-booster.herokuapp.com/card/thb/253

### GET /card/random

Returns a single random card.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|export|Boolean|✔︎|If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|q|String|✔︎|A scryfall search query. If provided, a random card matching the query will be returned.

Example: https://tts-magic-booster.herokuapp.com/card/random  
Example: https://tts-magic-booster.herokuapp.com/card/random?q=cmc:6+type:creature  
Example: https://tts-magic-booster.herokuapp.com/card/random?q=o:companion+set:iko&export=false

### GET /deck

Returns a deck of cards. The request must have a body containing the requested decklist in plaintext card list or Arena format. The returned JSON can be saved to a file and imported as a Saved Object.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|back|URL|✔︎|The URL of an image to use as the card back.|

Example: https://tts-magic-booster.herokuapp.com/deck

Body:
```json
{
    "deck": "26 Island\n4 Reliquary Tower (C19) 268\n24 Swamp\n4 Treasure Hunt (C18) 109\n2 Zombie Infestation (C19) 132"
}
```
