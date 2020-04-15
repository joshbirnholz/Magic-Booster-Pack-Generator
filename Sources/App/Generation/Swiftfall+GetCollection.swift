//
//  Swiftfall+GetCollection.swift
//  Magic Board
//
//  Created by Josh Birnholz on 2/20/20.
//  Copyright © 2020 Josh Birnholz. All rights reserved.
//

import Foundation

fileprivate extension Swiftfall {
	
	static func parseResource<ResultType: Decodable>(call: String, body: Data? = nil, method: String? = "GET", completion: @escaping (Swift.Result<ResultType, Error>) -> ()) {
        
        let url = URL(string: "\(scryfall)\(call)")
		var request = URLRequest(url: url!)
		request.httpBody = body
		request.httpMethod = method
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            
            guard let content = data else {
                print("Error: There was no data returned from JSON file.")
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let httpStatus = (response as! HTTPURLResponse).statusCode
            do {
                if (200..<300).contains(httpStatus) {
                    // Decode JSON file starting from Response struct.
                    let decoded:ResultType = try decoder.decode(ResultType.self, from: content)
                    completion(.success(decoded))
                } else {
					if let decoded:ScryfallError = try? decoder.decode(ScryfallError.self, from: content) {
						completion(.failure(decoded))
					} else if let error = error {
						completion(.failure(error))
					}
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

extension Swiftfall {
	
	// struct which contrains a list of cards
    public struct CardCollectionList: Codable, CustomStringConvertible {
        // an array of Cards
        public let data: [Card]
		
		public let warnings: [String]?
		
		public let notFound: [MTGCardIdentifier]?
        
        // prints each set
        public var description: String {
            var text = ""
            var i = 0
            for card in data {
                text += "Card Number: \(i)\n"
                text += card.description
                text += "\n"
                i = i + 1
            }
            return text
        }
    }
	
	static func getCollection(identifiers: [MTGCardIdentifier]) throws -> CardCollectionList {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		
		let data = try encoder.encode(["identifiers": identifiers])
		let string = String(data: data, encoding: .utf8)!
		
		print(string)
		
		let call = "cards/collection"
        
		var cardlist: Swift.Result<CardCollectionList, Error>?
		let semaphore = DispatchSemaphore(value: 0)
		
		parseResource(call: call, body: string.data(using: .utf8), method: "POST") {
			(newcardlist: Swift.Result<CardCollectionList, Error>) in
            cardlist = newcardlist
			semaphore.signal()
        }
		
		semaphore.wait()
		
        return try cardlist!.get()
	}
	
}
