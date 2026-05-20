//
//  MoodSwings.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 5/19/26.
//
import Foundation
import Vapor

func makeMoodSwingsXML(_ req: Request) async throws -> Response {
  var headers = HTTPHeaders()
  headers.add(name: .contentType, value: "text/xml")
  headers.add(name: .contentDisposition, value: "attachment; filename=\"moodswings.xml\"")
  
  let string = buildMoodSwingsOrder()
  
  return .init(
    status: .ok, headers: headers, body: .init(string: string)
  )
}

func moodSwingsDeck(_ req: Request) async throws -> String {
  let export: Bool = req.query.getBoolValue(at: "export") ?? true
  let cardBack = "https://josh.birnholz.com/tts/moodswings/back.jpg"
  let baseURL = "https://josh.birnholz.com/tts/moodswings/"

  let commons   = allCards.filter { $0.rarity == .common   }
  let uncommons = allCards.filter { $0.rarity == .uncommon }
  let rares     = allCards.filter { $0.rarity == .rare     }
  let mythics   = allCards.filter { $0.rarity == .mythic   }

  let chosen = (
    Array(commons.choose(23)) +
    Array(uncommons.choose(14)) +
    Array(rares.choose(6)) +
    Array(mythics.choose(2))
  ).shuffled()

  func moodSwingsURL(_ filename: String) -> String {
    baseURL + (filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename)
  }

  func customDeck(faceURL: String, backURL: String) -> String {
    """
    {
      "FaceURL": "\(faceURL)",
      "BackURL": "\(backURL)",
      "NumWidth": 1,
      "NumHeight": 1,
      "BackIsHidden": true,
      "UniqueBack": false
    }
    """
  }

  func cardObject(num: Int, faceURL: String, backURL: String, nickname: String) -> String {
    let id = num * 100
    let deck = customDeck(faceURL: faceURL, backURL: backURL)
    return """
    {
      "Name": "CardCustom",
      "Transform": {
        "posX": 0.5254047,
        "posY": 1.21068287,
        "posZ": 0.19025977,
        "rotX": -0.0008576067,
        "rotY": 180.000061,
        "rotZ": 179.9986,
        "scaleX": 1.0,
        "scaleY": 1.0,
        "scaleZ": 1.0
      },
      "Nickname": "\(nickname)",
      "Description": "",
      "GMNotes": "",
      "ColorDiffuse": {
        "r": 0.713235259,
        "g": 0.713235259,
        "b": 0.713235259
      },
      "Locked": false,
      "Grid": true,
      "Snap": true,
      "IgnoreFoW": false,
      "Autoraise": true,
      "Sticky": true,
      "Tooltip": true,
      "GridProjection": false,
      "HideWhenFaceDown": true,
      "Hands": true,
      "CardID": \(id),
      "SidewaysCard": false,
      "CustomDeck": {
        "\(num)": \(deck)
      },
      "XmlUI": "",
      "LuaScript": "",
      "LuaScriptState": "",
      "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
    }
    """
  }

  struct DeckEntry {
    let num: Int
    let faceURL: String
    let backURL: String
    let nickname: String
    var id: Int { num * 100 }
  }

  var entries: [DeckEntry] = []

  // Chosen cards
  for (index, card) in chosen.enumerated() {
    entries.append(DeckEntry(
      num: index + 1,
      faceURL: moodSwingsURL("\(card.name).jpg"),
      backURL: cardBack,
      nickname: card.name
    ))
  }

  // Hurt Feelings
  entries.append(DeckEntry(
    num: chosen.count + 1,
    faceURL: moodSwingsURL(hurtFeelingsFront.name),
    backURL: moodSwingsURL("Mood Swings.jpg"),
    nickname: "Hurt Feelings"
  ))
  
  // Rules card
  entries.append(DeckEntry(
    num: 0,
    faceURL: moodSwingsURL("Mood Swings Rules 1.jpg"),
    backURL: moodSwingsURL("Mood Swings Rules 2.jpg"),
    nickname: "Mood Swings Rules"
  ))

  let deckJSON = """
  {
    "Name": "Deck",
    "Transform": {
      "posX": 0.1779872,
      "posY": 3.08887124,
      "posZ": 0.29411754,
      "rotX": 358.469971,
      "rotY": 179.966263,
      "rotZ": 1.77417183,
      "scaleX": 1.0,
      "scaleY": 1.0,
      "scaleZ": 1.0
    },
    "Nickname": "Mood Swings",
    "Description": "",
    "GMNotes": "",
    "ColorDiffuse": {
      "r": 0.713235259,
      "g": 0.713235259,
      "b": 0.713235259
    },
    "Locked": false,
    "Grid": true,
    "Snap": true,
    "IgnoreFoW": false,
    "Autoraise": true,
    "Sticky": true,
    "Tooltip": true,
    "GridProjection": false,
    "HideWhenFaceDown": true,
    "Hands": false,
    "SidewaysCard": false,
    "DeckIDs": \(entries.map(\.id)),
    "CustomDeck": {
      \(entries.map { "\"\($0.num)\": \(customDeck(faceURL: $0.faceURL, backURL: $0.backURL))" }.joined(separator: ",\n    "))
    },
    "XmlUI": "",
    "LuaScript": "",
    "LuaScriptState": "",
    "ContainedObjects": [
      \(entries.map { cardObject(num: $0.num, faceURL: $0.faceURL, backURL: $0.backURL, nickname: $0.nickname) }.joined(separator: ",\n    "))
    ],
    "GUID": "\(UUID().uuidString.prefix(6).lowercased())"
  }
  """

  if !export {
    return deckJSON
  }

  return """
  {
    "SaveName": "",
    "GameMode": "",
    "Gravity": 0.5,
    "PlayArea": 0.5,
    "Date": "",
    "Table": "",
    "Sky": "",
    "Note": "",
    "Rules": "",
    "XmlUI": "",
    "LuaScript": "",
    "LuaScriptState": "",
    "ObjectStates": [
      \(deckJSON)
    ],
    "TabStates": {},
    "VersionNumber": ""
  }
  """
}

struct MoodSwingsCard {
  let name: String
  let id: String
  let query: String
  let rarity: Rarity
  
  enum Rarity {
    case common, uncommon, rare, mythic
  }
}

private let allCards: [MoodSwingsCard] = [
  // MARK: White
  .init(name: "Altruism",        id: "1HMqulyFBGodB5SFg7OetojTrgmdeHMj2", query: "altruism",        rarity: .rare),
  .init(name: "Benevolence",     id: "1myEh-IkQ-935elxr1719tWkrfWqsas2j", query: "benevolence",     rarity: .uncommon),
  .init(name: "Charity",         id: "1sg43t6_RbGg8CgNd1Ywuwc2_h2fQFhIa", query: "charity",         rarity: .common),
  .init(name: "Chivalry",        id: "1Jwn4l3tUZN0BmOe1kYOFByHtl_6h5_FZ", query: "chivalry",        rarity: .common),
  .init(name: "Complacency",     id: "1kAcoXtNAMHzLrYlCQ3X8PQiFRZerRgm2", query: "complacency",     rarity: .common),
  .init(name: "Conviction",      id: "1GynpBuKhczVoeDkai25ZdPTbJ30G6lT8", query: "conviction",      rarity: .uncommon),
  .init(name: "Courage",         id: "1fwh9qLOhy939WocgqIC38mw4y7SReDqL", query: "courage",         rarity: .common),
  .init(name: "Dignity",         id: "1zUqckfQSbNdVLL5-5p1xVZoMPT10IPbp", query: "dignity",         rarity: .common),
  .init(name: "Discipline",      id: "1BMS6rcXSXTb1iFMQ1Cqb5eHoBqXBv8yX", query: "discipline",      rarity: .common),
  .init(name: "Disillusionment", id: "1Nw-qyGP9vuPg_0MLq-OFiWtYzfxGTlsd", query: "disillusionment", rarity: .rare),
  .init(name: "Encouragement",   id: "1-pE2oRrN4UeFsvoCkK1Xwf6Ne4k_AZ_l", query: "encouragement",   rarity: .uncommon),
  .init(name: "Faith",           id: "1sXaUZBPqfEcIzqpOXrTr1agVQo3aU5Cf", query: "faith",           rarity: .uncommon),
  .init(name: "Friendliness",    id: "1t8vNXo6HjIK2FR8L2Yj8hA22YIHsqoXJ", query: "friendliness",    rarity: .uncommon),
  .init(name: "Guilt",           id: "1u0udE27gX_zne6TFYeXNdPMXCXySnlOG", query: "guilt",           rarity: .uncommon),
  .init(name: "Honor",           id: "1M6y-QVzGnJvCVmuqHxn6epoy1UtbuGRu", query: "honor",           rarity: .rare),
  .init(name: "Idealism",        id: "1nQ5I6PlEgw3QqDURZEQKe7bhYiL2HtGS", query: "idealism",        rarity: .mythic),
  .init(name: "Kindness",        id: "1U9tsDV77XgVEJOUMFTATu7h2KRpFstkR", query: "kindness",        rarity: .uncommon),
  .init(name: "Loyalty",         id: "1VDbRU_nQWPz8gwQsuFp9VOcPxl5gLcHz", query: "loyalty",         rarity: .common),
  .init(name: "Meekness",        id: "1Wds4F0IzcmZ_hc0j5LGWk2Eu3Loy3Gmj", query: "meekness",        rarity: .rare),
  .init(name: "Pacifism",        id: "10IYqu3a-yIlLnv3Hw1M40Jkv_gk6zaSh", query: "pacifism",        rarity: .common),
  .init(name: "Patience",        id: "1MFVZcg6YbLUu4ETOE5TLmmYQKoAmUeWu", query: "patience",        rarity: .common),
  .init(name: "Pride",           id: "1tSxz8cJAI9CTDG5KLry_EiwxgqGP4zOs", query: "pride",           rarity: .rare),
  .init(name: "Repentance",      id: "1i2PGyMNRJFZ5ywEtpV54GVMRdBByxqa8", query: "repentance",      rarity: .uncommon),
  .init(name: "Scorn",           id: "1YlX4c-lm9SRxerWsPPFanhqJnoXOjf2l", query: "scorn",           rarity: .mythic),
  .init(name: "Shame",           id: "1b6qIIDf0m48OpwSnjd4m1Jrfn2GUH9o5", query: "shame",           rarity: .rare),
  .init(name: "Validation",      id: "1i1tt5rA2S1yYf5W-abWP0d1CI_Kou8N2", query: "validation",      rarity: .mythic),
  
  // MARK: Blue
  .init(name: "Ambivalence",     id: "1t8S0BqV0DL1zsPK_5CR1IDbr_XlZfQwH", query: "ambivalence",     rarity: .common),
  .init(name: "Anxiety",         id: "1gUOUg0OKXizCAY3xVd-wVUAZgYoXvXRT", query: "anxiety",         rarity: .common),
  .init(name: "Avoidance",       id: "1IEqSPkebWQsbs-FEr8rH8wapyriIvdq1", query: "avoidance",       rarity: .rare),
  .init(name: "Bashfulness",     id: "1jxhe8I7QsQgJXZ5YfebZjDzEYx2-xsUL", query: "bashfulness",     rarity: .common),
  .init(name: "Confusion",       id: "19PrZA-1b0bQCBgU3-nd74MaTyxtr2ry2", query: "confusion",       rarity: .uncommon),
  .init(name: "Creativity",      id: "1NnetYkvQ9ZY8CEY7l05LsYqIv0L81EJ8", query: "creativity",      rarity: .rare),
  .init(name: "Curiosity",       id: "1c_2__UaBuTWylRMxjCXaOc89iDn9wjJj", query: "curiosity",       rarity: .common),
  .init(name: "Denial",          id: "1B8ZfGAgBuU1N06QsrJD0vi1AnqEKFk6g", query: "denial",          rarity: .rare),
  .init(name: "Disorientation",  id: "1B2mkn_oK9hfTJd6fEJ8YAVprf45bpeD1", query: "disorientation",  rarity: .rare),
  .init(name: "Doubt",           id: "1An-EJwn2vqiMIrjwzbmS9pM0CaVj-hcj", query: "doubt",           rarity: .uncommon),
  .init(name: "Duplicity",       id: "1aLSbDFw6T4G29f1oGBEyu4xersx-zOTU", query: "duplicity",       rarity: .mythic),
  .init(name: "Fear",            id: "1DadKl2sb87NT3aqy3nQQvZ8DbHnJwneO", query: "fear",            rarity: .common),
  .init(name: "Fickleness",      id: "1aD-xrQJniEA9x3Qmfa5WiDDsA-wBw2rS", query: "fickleness",      rarity: .uncommon),
  .init(name: "Guile",           id: "1b8rQ-lhNfLwn-Tl-xIJW-8a2kQQV2XPi", query: "guile",           rarity: .mythic),
  .init(name: "Hesitation",      id: "1X0mfWDYsOieX8yQMfK7OGWbsHatNk_OM", query: "hesitation",      rarity: .uncommon),
  .init(name: "Imagination",     id: "1zYb8KhRvd-E044r-OZo8VjCRpTFLIFUI", query: "imagination",     rarity: .uncommon),
  .init(name: "Indecisiveness",  id: "1ytmoNk0cSrygjA7NZyRnXGgpPTAwM1NA", query: "indecisiveness",  rarity: .uncommon),
  .init(name: "Indifference",    id: "19IbRHsjbsv4vp09cRqbMHB8t_c23wjAG", query: "indifference",    rarity: .common),
  .init(name: "Insecurity",      id: "13SjKbM6w7YdeNinSGOOqqqTmDRtHiTVX", query: "insecurity",      rarity: .uncommon),
  .init(name: "Neurosis",        id: "1LZ9JbcOR6ApJNXY6rrfqziDK3dd-5rM9", query: "neurosis",        rarity: .common),
  .init(name: "Obsession",       id: "17NHCo4I-rC3TGMY0d_XwmpO6b0xRf8RX", query: "obsession",       rarity: .common),
  .init(name: "Panic",           id: "1rV5eeY7PXwmG1lqBai-KgHicfoHR2iD4", query: "panic",           rarity: .common),
  .init(name: "Rationalization", id: "1ScpTP8EfOWOA09WaYLMskxiDNUyoti75", query: "rationalization",  rarity: .rare),
  .init(name: "Regret",          id: "1sgexJmGnsDajXEPBwana3G-tii3iuSSQ", query: "regret",           rarity: .rare),
  .init(name: "Sneakiness",      id: "12M3oc-K2go7J_7QzRkD4cjfaExRBOSzv", query: "sneakiness",      rarity: .mythic),
  .init(name: "Worry",           id: "1pDOU6q2M_rsLK76yyuW2kbYsyXJqTwO6", query: "worry",           rarity: .uncommon),
  
  // MARK: Black
  .init(name: "Ambition",        id: "1l9sS8a1ZZA_fiHkpm9xUVwtvHLmhdTmk", query: "ambition",        rarity: .common),
  .init(name: "Angst",           id: "1XOIosOLM6ws77NF9BB20Tfs0X8DXs67o", query: "angst",           rarity: .uncommon),
  .init(name: "Apathy",          id: "1EqAaxAVL3eeQgvBNRPqSSSidj1ICy13B", query: "apathy",          rarity: .common),
  .init(name: "Betrayal",        id: "16ptz5EV7Rgcz4q0jmYmOu3jfmNgUpMFR", query: "betrayal",        rarity: .uncommon),
  .init(name: "Bitterness",      id: "1_8scA8GH7k_QTW-vz4V_UqJyz0XLvP_U", query: "bitterness",      rarity: .uncommon),
  .init(name: "Condescension",   id: "14v4LvwFGelxuSePscVMdMudeFdfUBMwq", query: "condescension",   rarity: .common),
  .init(name: "Contempt",        id: "1uGTpsb1CzKWxH-4kWcR0riJelwjkpesz", query: "contempt",        rarity: .uncommon),
  .init(name: "Corruption",      id: "1WB64CNJaZCVLMGYzffX8ldiVV4mZZs_H", query: "corruption",      rarity: .rare),
  .init(name: "Cruelty",         id: "1dN8YP4ZAgYdqH11aWQe3qP_SvluOyQ9p", query: "cruelty",         rarity: .uncommon),
  .init(name: "Cynicism",        id: "1tbiTqmRjyqDVKwvO8QJCun8ok6zdUgct", query: "cynicism",        rarity: .uncommon),
  .init(name: "Disgust",         id: "1CCwXjoSzsjGK5PIlVjSvpLDpnqn6xcSR", query: "disgust",         rarity: .common),
  .init(name: "Envy",            id: "1RhsYEukSKUGiH3fl9JjmNtdIQTSqlYcW", query: "envy",            rarity: .rare),
  .init(name: "Grief",           id: "1IdHdcby37besjXEkeN2OZon2X_8Rc9N2", query: "grief",           rarity: .rare),
  .init(name: "Hate",            id: "1a5KUmSPBanP6MFR0tbRY1Mo62k5ecOoi", query: "hate",            rarity: .common),
  .init(name: "Intimidation",    id: "1HjeTzXBVJqaVFYu-xl2-6IzhCCPcYg2B", query: "intimidation",    rarity: .rare),
  .init(name: "Malice",          id: "1WAAKBE7xKzsiRF7eq2zTrF0q6y_JMNvg", query: "malice",          rarity: .common),
  .init(name: "Melancholy",      id: "1h3b0pjIeUsRG2dI4X-H0GOX8DLY1wtrU", query: "melancholy",      rarity: .rare),
  .init(name: "Misery",          id: "11JbljfV8HSof_kSIAdnFGKe1HlSJ_IYk", query: "misery",          rarity: .uncommon),
  .init(name: "Paranoia",        id: "10H4me5slU0cG3COLF8zuLmPmgH9_ESQN", query: "paranoia",        rarity: .uncommon),
  .init(name: "Pity",            id: "1ANp1R3ucsYGqIPd0hAPGRaQTGrT131NX", query: "pity",            rarity: .common),
  .init(name: "Rejection",       id: "1HObtdqX-cvnhxiYwGWhxp-5uUoSG90P6", query: "rejection",       rarity: .rare),
  .init(name: "Sadness",         id: "1t33uY7SILX4IFRFzDznWMIQcprQwBT-7", query: "sadness",         rarity: .mythic),
  .init(name: "Self-Loathing",   id: "1tlXsNAcC83D61BUo69r5PXrCGEU-8XsM", query: "self loathing",   rarity: .common),
  .init(name: "Spite",           id: "1X3NXgs7B69aKU_zbogXlkCFMkNAHbc-u", query: "spite",           rarity: .common),
  .init(name: "Superiority",     id: "13HCnyhXAaWyMr_Wygblf00zdYINdnfzR", query: "superiority",     rarity: .common),
  .init(name: "Suspicion",       id: "1583AS1mYsSqHtO1Allv0BK4fQe9Tu3Hl", query: "suspicion",       rarity: .common),
  .init(name: "Vanity",          id: "1fM0-FN7L8Id2l_bSGYKlIl4ijsrEEerK", query: "vanity",          rarity: .mythic),
  
  // MARK: Red
  .init(name: "Anger",           id: "1hCVZlX0Bt_urPDaj9kx8Ahd3IKx8ffLF", query: "anger",           rarity: .uncommon),
  .init(name: "Animosity",       id: "18bZVappnsAgP8bswNLUMz9XyJKgfgMUn", query: "animosity",       rarity: .uncommon),
  .init(name: "Arrogance",       id: "1vlujfPXPEASf_6g74i8il7N0vs3NLd_p", query: "arrogance",       rarity: .uncommon),
  .init(name: "Boredom",         id: "1ussr5n1U0mhkVrPPcuNYEKO7tUrytgsF", query: "boredom",         rarity: .common),
  .init(name: "Bravado",         id: "1Qs5XZ8lyyh1iaQ_sOsKTO4wg4DRvNZnK", query: "bravado",         rarity: .common),
  .init(name: "Chaos",           id: "1k7ZrU_hCCD1q0LW3P6Er4fSZg5TojGix", query: "chaos",           rarity: .mythic),
  .init(name: "Compulsion",      id: "14WQMcLiMj06Q3HpIg8rDaWNBMeONBrPE", query: "compulsion",      rarity: .common),
  .init(name: "Embarrassment",   id: "1Eh3ufCv--WZ91n8OnGOuDD4oMaR5bkYa", query: "embarrassment",   rarity: .common),
  .init(name: "Excitement",      id: "1Hgi52O0wm51GvJ4IGTUGeRpLG9oTWba0", query: "excitement",      rarity: .common),
  .init(name: "Exhilaration",    id: "1KYpWzfdRHTm0RJvZZ7_4AN9KHoGqhinB", query: "exhilaration",    rarity: .mythic),
  .init(name: "Frustration",     id: "1rzMt9q_v7pp0nFCrDG1Ez93vOIYHXxMD", query: "frustration",     rarity: .common),
  .init(name: "Fury",            id: "1Rcb8ZQZmjc7u5x4j7Qk6mYibcB5PG109", query: "fury",            rarity: .uncommon),
  .init(name: "Glee",            id: "1JJFzPCMErjtVOdhJDCb7MJC8zsISflb1", query: "glee",            rarity: .common),
  .init(name: "Gluttony",        id: "1vhb5vMs3rjP3i3ez18nkdjZNjfeEQ7_-", query: "gluttony",        rarity: .uncommon),
  .init(name: "Hostility",       id: "1zpzjllZNza_F3U74q7fNMX09Z66pd-XL", query: "hostility",       rarity: .uncommon),
  .init(name: "Infatuation",     id: "1h_bXAV1HVtaRR5m-lOPOslajLF8ug_qV", query: "infatuation",     rarity: .rare),
  .init(name: "Instability",     id: "1AIplo7dUEkRc9bYmvbSoodzD5WFNugkQ", query: "instability",     rarity: .rare),
  .init(name: "Passion",         id: "18ACSKo3qs5DyGs1JJNkTUvDqo8itXqTR", query: "passion",         rarity: .rare),
  .init(name: "Rage",            id: "1eXSq99bLI39fjYeFj75RL_WlTB19kCp_", query: "rage",            rarity: .uncommon),
  .init(name: "Rebellion",       id: "1orIlOiCtyG0WEKWNjNhqiq6GT-ZUMwYK", query: "rebellion",       rarity: .uncommon),
  .init(name: "Recklessness",    id: "1kKv3MN86sbfn8pqyf9r9Qd6uEqZwFP2j", query: "recklessness",    rarity: .rare),
  .init(name: "Shock",           id: "1qQClTm4u2Fkmuwbq6uFjYe2UbFosNqe0", query: "shock",           rarity: .common),
  .init(name: "Stubbornness",    id: "14rra1CEGJv-P-wk_PcxNRGnACHcY7LyX", query: "stubbornness",    rarity: .rare),
  .init(name: "Thrill",          id: "1XgnndGy_CZ0u1SEwmSnGJRV9LfjC-TJm", query: "thrill",          rarity: .mythic),
  .init(name: "Triumph",         id: "1xaeWwUYmZBD4K3MX07r-VPucDUMqzy07", query: "triumph",         rarity: .common),
  .init(name: "Wrath",           id: "1WpEq4eWFW7POxtsboBdl-T55fiW3SnHg", query: "wrath",           rarity: .rare),
  .init(name: "Zeal",            id: "1jfrFUQenOqaxfnAyJVzJQ9-_WiHQeISw", query: "zeal",            rarity: .common),
  
  // MARK: Green
  .init(name: "Awe",             id: "1AdjzjqRnKcd5Hc8XE9ngep6XFiBdH_Fe", query: "awe",             rarity: .rare),
  .init(name: "Bliss",           id: "1XRh0N3knKWtYev8xLiXY82kspMzdWTtM", query: "bliss",           rarity: .mythic),
  .init(name: "Celebration",     id: "1Lfq-1C8nHIbIpLUJbty2zzZJJazwFA1s", query: "celebration",     rarity: .common),
  .init(name: "Cheer",           id: "1_zhZmQhh_dw21bSSwURUz9OerX7B9FP4", query: "cheer",           rarity: .common),
  .init(name: "Delight",         id: "1RcRhQ3e-ImpVMeTTvN0a70qITd96sXEu", query: "delight",         rarity: .common),
  .init(name: "Determination",   id: "1Uo0UWiRbPorZX4Jyvon_SNDX4MDVx6hE", query: "determination",   rarity: .common),
  .init(name: "Disregard",       id: "1ymHL6YkP2r-RxPIViHFf5twQHgcoZqtz", query: "disregard",       rarity: .common),
  .init(name: "Eagerness",       id: "1o5VJ1Rk7JTHL1cCQgEw6r6P8Z9C_yX60", query: "eagerness",       rarity: .uncommon),
  .init(name: "Enjoyment",       id: "1ibxnf1xNpNiKqpBnJCbZTX_GBezuuOmC", query: "enjoyment",       rarity: .common),
  .init(name: "Enthusiasm",      id: "1bDQgPe6XCadyS_LhhhM0E0n6M6pL4iVi", query: "enthusiasm",      rarity: .uncommon),
  .init(name: "Euphoria",        id: "1Xeeprf8m_Cox-vwzGNqCIaqmVs26TMoj", query: "euphoria",        rarity: .rare),
  .init(name: "Fascination",     id: "18661K8EpCXbSDnc0eaMd2y4RnAUflYwk", query: "fascination",     rarity: .uncommon),
  .init(name: "Fondness",        id: "1cwN7jE0KLveYM-2DXoDgdzQIFofSSe9b", query: "fondness",        rarity: .uncommon),
  .init(name: "Generosity",      id: "1kQckmTczMECNLGbL2Jyeq01lEehrNNcq", query: "generosity",      rarity: .common),
  .init(name: "Grace",           id: "1P-3BmTFlWEP4cdVSmTRBxkF8LenyOYHG", query: "grace",           rarity: .rare),
  .init(name: "Happiness",       id: "1amDykR65SiXLvVloeZ5-1gIg2LNfsiki", query: "happiness",       rarity: .uncommon),
  .init(name: "Harmony",         id: "19PlPlrmRNSgK_H-ZqLhsnPjAexIFAKua", query: "harmony",         rarity: .uncommon),
  .init(name: "Hope",            id: "16UsWQHIWA3oNXsnVW8Z2mz9y4dMO3C20", query: "hope",            rarity: .rare),
  .init(name: "Joy",             id: "1AlYg5sdjb3iD0dfdNY7DqNXus_5YNPrj", query: "joy",             rarity: .common),
  .init(name: "Laziness",        id: "1nB-rY0AF_ss07Kso4ogf3MxB7PAR0c0e", query: "laziness",        rarity: .common),
  .init(name: "Love",            id: "11r2CDgheycnEPN9YpKnK652qMbXJDhZb", query: "love",            rarity: .mythic),
  .init(name: "Nostalgia",       id: "1ijBZx0MeIeF8gaHGTIe1zOKYjJ-Ny34y", query: "nostalgia",       rarity: .common),
  .init(name: "Serenity",        id: "119O4kzrSK_CJhtddWN2EOWV6z0pGOgDm", query: "serenity",        rarity: .uncommon),
  .init(name: "Sloth",           id: "13xbwuUc-HK7ab5c3xyMB927MZ4GVn5ne", query: "sloth",           rarity: .rare),
  .init(name: "Tranquility",     id: "1iJ8pUfo7Vk3zMdt2cyUZIgcX6XwXkAsa", query: "tranquility",     rarity: .uncommon),
  .init(name: "Vulnerability",   id: "1lPMGktGliztfNBGhXrShUSRIV_Fmn0WV", query: "vulnerability",   rarity: .rare),
  .init(name: "Wonder",          id: "1WBahRjKqvehnxiBbwXj2XZgd3bhBZMLa", query: "wonder",          rarity: .mythic),
]

private let rulesCardFront = (
  id: "1Tt6hjk2jesuvHK0I0c_TFOaHY_XrBSps",
  name: "Mood Swings Rules (1).jpg",
  query: "mood swings rules"
)
private let rulesCardBack = (
  id: "1fFjYKtncqoE4aVl2bpRKo-lsG3BgpW0x",
  name: "Mood Swings Rules (2).jpg",
  query: "mood swings rules"
)
private let hurtFeelingsFront = (
  id: "11aev4h0i-nczAFTvwbdIb9C1R1mXDktV",
  name: "Hurt Feelings.jpg",
  query: "hurt feelings"
)
private let hurtFeelingsBack = (
  id: "12Xd4F5pqWkuJ0HhCVwq7YVnOXR0RUizn",
  name: "Mood Swings Rules.jpg",
  query: "mood swings"
)
private let defaultCardback = "1hKGZQPiSk_PCKEToNk4YwG5k1U62Z0bc"

/// Returns an XML order string matching a real copy of Mood Swings:
/// - Rules card (double-sided)
/// - 23 commons, 14 uncommons, 6 rares, 2 mythics chosen at random
/// - Hurt Feelings (with its special Mood Swings back)
func buildMoodSwingsOrder() -> String {
  let commons   = allCards.filter { $0.rarity == .common   }
  let uncommons = allCards.filter { $0.rarity == .uncommon }
  let rares     = allCards.filter { $0.rarity == .rare     }
  let mythics   = allCards.filter { $0.rarity == .mythic   }
  
  let chosen = (
    Array(commons.choose(23)) +
    Array(uncommons.choose(14)) +
    Array(rares.choose(6)) +
    Array(mythics.choose(2))
  ).shuffled()
  
  let hurtFeelingsSlot = chosen.count + 1
  
  let totalCards = 1 + chosen.count + 1
  
  func cardXML(id: String, slot: Int, name: String, query: String) -> String {
        """
                <card>
                    <id>\(id)</id>
                    <sourceType>Google Drive</sourceType>
                    <slots>\(slot)</slots>
                    <name>\(name)</name>
                    <query>\(query)</query>
                </card>
        """
  }
  
  var frontCards = [String]()
  frontCards.append(cardXML(
    id: rulesCardFront.id,
    slot: 0,
    name: rulesCardFront.name,
    query: rulesCardFront.query
  ))
  for (index, card) in chosen.enumerated() {
    frontCards.append(cardXML(
      id: card.id,
      slot: index + 1,
      name: "\(card.name).jpg",
      query: card.query
    ))
  }
  frontCards.append(cardXML(
    id: hurtFeelingsFront.id,
    slot: hurtFeelingsSlot,
    name: hurtFeelingsFront.name,
    query: hurtFeelingsFront.query
  ))
  
  let backCards = [
    cardXML(
      id: rulesCardBack.id,
      slot: 0,
      name: rulesCardBack.name,
      query: rulesCardBack.query
    ),
    cardXML(
      id: hurtFeelingsBack.id,
      slot: hurtFeelingsSlot,
      name: hurtFeelingsBack.name,
      query: hurtFeelingsBack.query
    ),
  ]
  
  let xml = """
    <order>
        <details>
            <quantity>\(totalCards)</quantity>
            <stock>(S30) Standard Smooth</stock>
            <foil>false</foil>
        </details>
        <fronts>
    \(frontCards.joined(separator: "\n"))
        </fronts>
        <backs>
    \(backCards.joined(separator: "\n"))
        </backs>
        <cardback>\(defaultCardback)</cardback>
    </order>
    """
  
  return xml
}
