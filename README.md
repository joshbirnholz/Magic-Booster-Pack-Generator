<p align="center">
    <a href="http://docs.vapor.codes/3.0/">
        <img src="http://img.shields.io/badge/read_the-docs-2196f3.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor">
        <img src="https://img.shields.io/discord/431917998102675485.svg" alt="Team Chat">
    </a>
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://circleci.com/gh/vapor/api-template">
        <img src="https://circleci.com/gh/vapor/api-template.svg?style=shield" alt="Continuous Integration">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.1-brightgreen.svg" alt="Swift 5.1">
    </a>
</p>

## API: https://tts-magic-booster.herokuapp.com

An API to generate _Magic: The Gathering_ cards, booster packs, and prerelease packs for _Tabletop Simulator_.

### GET /:set

Generates a booster pack for a given set.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|:set|String||The set name or code.|
|export|Boolean|✔︎|If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|count|Integer|✔︎|The number of booster packs to generate. The default value is 1.|

Example: https://tts-magic-booster.herokuapp.com/iko?count=3&export=false

### GET /box/:set

Generates a box of booster packs for a given set.

|Parameter|Type|Optional|Details|
|---|---|---|---|
|:set|String||The set name or code.|
|export|Boolean|✔︎|If true, the returned JSON can be saved to a file and imported as a Saved Object. If false, the returned JSON can be used to spawn an object directly via scripting. The default value is true.|
|count|Integer|✔︎|The number of booster packs to generate. The default value depends on the set (usually 36).|

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
|deck|Object||The deck list.|

Example: https://tts-magic-booster.herokuapp.com/deck

Body:
```json
{
    "deck": "26 Island\n4 Reliquary Tower (C19) 268\n24 Swamp\n4 Treasure Hunt (C18) 109\n2 Zombie Infestation (C19) 132"
}
```
