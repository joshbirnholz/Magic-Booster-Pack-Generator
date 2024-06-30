//
//  File.swift
//  
//
//  Created by Josh Birnholz on 11/11/23.
//

import Foundation
import Vapor
import CSV

struct CollectionRemoverOutput: Content {
  let output: String
  let notFoundOutput: String
  let status: String
}

func collectionRemove(_ req: Request) throws -> CollectionRemoverOutput {
  
  struct Input: Content {
    let original: Data
    let remove: Data
  }
  
  let input = try req.content.decode(Input.self)
  
  guard
    let original = String(data: input.original, encoding: .utf8),
    let remove = String(data: input.remove, encoding: .utf8)
  else {
    throw Abort(.badRequest, reason: "Unreadable CSV file")
  }

  let remover = CollectionRemover()
  
  let items = try remover.readCollectionItems(from: original)
  
  let itemsToRemove = try remover.readCollectionItems(from: remove)
  
  let (collection, notFound) = remover.remove(itemsToRemove, from: items)
  
  let output = try remover.writeCSV(collection)
  let notFoundOutput = try remover.writeCSV(notFound)
  
  let inputCount = (items.count, items.reduce(0, { $0 + $1.amount }))
  let removeCount = (itemsToRemove.count, itemsToRemove.reduce(0, { $0 + $1.amount }))
  let collectionCount = (collection.count, collection.reduce(0, { $0 + $1.amount }))
  let notFoundCount = (notFound.count, notFound.reduce(0, { $0 + $1.amount }))
  
  let status = """
Input: \(inputCount.0) rows (\(inputCount.1) cards)
Remove: \(removeCount.0) rows (\(removeCount.1) cards)
Output: \(collectionCount.0) rows (\(collectionCount.1) cards)

Removed: \(inputCount.0 - collectionCount.0) rows (\(inputCount.1 - collectionCount.1) cards)
Not Found: \(notFoundCount.0) rows (\(notFoundCount.1) cards)
"""
  print(status)
  
  return CollectionRemoverOutput(output: output, notFoundOutput: notFoundOutput, status: status)
}

fileprivate struct CollectionRemover {
  struct CollectionItem: Codable {
    var amount: Int
    var cardName: String
    var isFoil: Bool
    var isPinned: Bool
    var isSigned: Bool
    var setID: String
    var setCode: String
    var collectorNumber: String
    var language: String
    var condition: String
    var comment: String
    var added: String
  }

  func readCollectionItems(from csvString: String) throws -> [CollectionItem] {
    let reader = try CSVReader(string: csvString, hasHeaderRow: true)
    
    var items: [CollectionItem] = []
    
    while reader.next() != nil {
      let isPinnedString = reader["is_pinned"] ?? ""
      let isSigned = reader["is_signed"] ?? ""
      let setID = reader["set_id"] ?? ""
      let comment = reader["comment"] ?? ""
      
      guard let amountString = reader["amount"], let amount = Int(amountString),
          let cardName = reader["card_name"],
          let isFoilString = reader["is_foil"],
          let setCode = reader["set_code"] ?? reader["set_name"],
          let collectorNumber = reader["collector_number"],
          let language = reader["language"],
          let condition = reader["condition"],
          let added = reader["added"]
      else {
        continue
      }
      
      let item = CollectionItem(
        amount: amount,
        cardName: cardName,
        isFoil: isFoilString == "1",
        isPinned: isPinnedString == "1",
        isSigned: isSigned == "1",
        setID: setID,
        setCode: setCode,
        collectorNumber: collectorNumber,
        language: language,
        condition: condition,
        comment: comment,
        added: added
      )
      items.append(item)
    }
    
    return items
  }

  private func indexOfItem(matching itemToRemove: CollectionItem, inCollection collection: [CollectionItem]) -> Int? {
    return collection.firstIndex { item in
      item.cardName.lowercased() == itemToRemove.cardName.lowercased() &&
      item.isFoil == itemToRemove.isFoil &&
      item.isSigned == itemToRemove.isSigned &&
      (item.setCode.lowercased() == itemToRemove.setCode.lowercased() || (item.setID.lowercased() == itemToRemove.setID.lowercased() && !item.setID.isEmpty)) &&
      item.collectorNumber.lowercased() == itemToRemove.collectorNumber.lowercased() &&
      ((item.language.lowercased() == itemToRemove.language.lowercased()) || Set([item.language.lowercased(), itemToRemove.language.lowercased()]) == ["en", ""]) &&
      item.condition.lowercased() == itemToRemove.condition.lowercased()
    }
  }

  func remove(_ itemsToRemove: [CollectionItem], from collection: [CollectionItem]) -> (result: [CollectionItem], notFound: [CollectionItem]) {
    var collection = collection
    
    var notFound: [CollectionItem] = []
    
    outer: for item in itemsToRemove {
      var amountLeftToRemove = item.amount
      var amountRemoved = 0
      
      while amountLeftToRemove > 0 {
        guard let index = indexOfItem(matching: item, inCollection: collection) else {
          notFound.append(item)
          continue outer
        }
        
        let amountToRemoveFromThisRow = min(amountLeftToRemove, collection[index].amount)
        
        collection[index].amount -= amountToRemoveFromThisRow
        
        amountRemoved += amountToRemoveFromThisRow
        
        amountLeftToRemove -= amountRemoved
        
        if collection[index].amount <= 0 {
          collection.remove(at: index)
        }
      }
    }
    
    return (result: collection, notFound: notFound)
  }

  func writeCSV(_ items: [CollectionItem]) throws -> String {
    let stream = OutputStream(toMemory: ())
    let csv = try CSVWriter(stream: stream)
    
    try csv.write(row: ["amount", "card_name", "is_foil", "is_pinned", "is_signed", "set_id", "set_code", "collector_number", "language", "condition", "comment", "added"])
    
    for item in items {
      csv.beginNewRow()
      
      try csv.write(field: String(item.amount))
      try csv.write(field: item.cardName, quoted: true)
      try csv.write(field: item.isFoil ? "1" : "")
      try csv.write(field: item.isPinned ? "1" : "")
      try csv.write(field: item.isSigned ? "1" : "")
      try csv.write(field: item.setID)
      try csv.write(field: item.setCode)
      try csv.write(field: item.collectorNumber)
      try csv.write(field: item.language)
      try csv.write(field: item.condition)
      try csv.write(field: item.comment)
      try csv.write(field: item.added)
    }
    
    csv.stream.close()

    // Get a String
    let csvData = csv.stream.property(forKey: .dataWrittenToMemoryStreamKey) as! Data
    let csvString = String(data: csvData, encoding: .utf8)!
    
    return csvString
  }

}
