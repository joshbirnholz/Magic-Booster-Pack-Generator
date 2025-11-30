//
//  ImageCrop.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 9/7/25.
//

import Vapor
import Swim
#if canImport(FoundationNetworking)
import FoundationNetworking
import Foundation
#endif

actor ImageController {
  
  private var cropCache: [URL: Data] = [:]
  private var accessOrder: [URL] = []
  private let maxCacheEntries = 100  // tune this number
  
  private func setCache(for url: URL, data: Data) {
    cropCache[url] = data
    accessOrder.removeAll { $0 == url }
    accessOrder.insert(url, at: 0)
    
    if accessOrder.count > maxCacheEntries {
      if let toRemove = accessOrder.popLast() {
        cropCache.removeValue(forKey: toRemove)
      }
    }
  }
  
  private func getCache(for url: URL) -> Data? {
    if let data = cropCache[url] {
      accessOrder.removeAll { $0 == url }
      accessOrder.insert(url, at: 0)
      return data
    }
    return nil
  }
  
  func artCrop(_ req: Request) async throws -> Response {
    let back = req.query.getBoolValue(at: "back") ?? false
    
    guard let code = req.parameters.get("set"), let number = req.parameters.get("number") else {
      throw Abort(.badRequest, reason: "Missing values for parameters code and/or number")
    }
    
    guard let mtgCard = await DraftmancerSetCache.shared.loadedDraftmancerCards?[.collectorNumberSet(collectorNumber: number, set: code, name: nil)] else {
      throw Abort(.badRequest, reason: "Set code and number do not identifiy a valid custom card")
    }
    
    let card = Swiftfall.Card(mtgCard)
    
    let urls = {
      var temp: [URL] = []
      if let url = card.imageUris?["large"] ?? card.imageUris?["normal"] {
        temp.append(url)
      }
      if let faces = card.cardFaces, faces.count == 2 {
        for face in faces {
          if let url = face.imageUris?["large"] ?? face.imageUris?["normal"]{
            temp.append(url)
          }
        }
      }
      
      return temp
    }()
    
    guard let url = back ? urls.last : urls.first else {
      throw Abort(.expectationFailed, reason: "Custom card has no images")
    }
    
    let headers: HTTPHeaders = [
      "Content-Type": "image/jpeg",
      "access-control-allow-headers": "Origin",
      "access-control-allow-origin": "*"
    ]
    
    if let data = getCache(for: url) ?? loadFromDisk(for: url) {
      setCache(for: url, data: data)
      return Response(status: .ok,
                      headers: headers,
                      body: .init(data: data))
    }
    
    let data = try await artCrop(url: url)
    
    return Response(
      status: .ok,
      headers: headers,
      body: .init(data: data)
    )
  }
  
  func proxyCrop(_ req: Request) async throws -> Response {
    guard let url = try? req.query.get(URL.self, at: "url") else {
      throw Abort(.expectationFailed, reason: "Couldn't get URL")
    }
    
    let headers: HTTPHeaders = [
      "Content-Type": "image/jpeg",
      "access-control-allow-headers": "Origin",
      "access-control-allow-origin": "*"
    ]
    
    if let data = getCache(for: url) ?? loadFromDisk(for: url) {
      setCache(for: url, data: data)
      return Response(status: .ok,
                      headers: headers,
                      body: .init(data: data))
    }
    
    let data = try await proxyCrop(url: url)
    
    return Response(
      status: .ok,
      headers: headers,
      body: .init(data: data)
    )
  }
  
  private func artCrop(url: URL) async throws -> Data {
    let referenceWidth: Double = 2010
    let referenceHeight: Double = 2814
    let refX: Double = 155
    let refY: Double = 319
    let refW: Double = 1699
    let refH: Double = 1242
    
    guard let image = try? await downloadImage(url: url) else {
      print("Could not decode image at \(url)")
      throw Abort(.unsupportedMediaType, reason: "Could not decode image")
    }
    
    // Calculate scale factors
    let scaleX = Double(image.width) / referenceWidth
    let scaleY = Double(image.height) / referenceHeight
    
    // Compute scaled crop rect
    let x = Int(refX * scaleX)
    let y = Int(refY * scaleY)
    let w = Int(refW * scaleX)
    let h = Int(refH * scaleY)
    
    // Perform crop
    let cropped = image[x..<(x+w), y..<(y+h)]
    
    // Encode back to JPEG
    
    guard let jpegData = try? cropped.fileData(format: WriteFormat.jpeg(quality: 90)) else {
      throw Abort(.internalServerError, reason: "Encoding failed")
    }
    
    cropCache[url] = jpegData
    
    Task {
      saveToDisk(jpegData, for: url)
    }
    Task {
      setCache(for: url, data: jpegData)
    }
    
    return jpegData
  }
  
  private func downloadImage(url: URL) async throws -> Image<RGBA, UInt8> {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try Image<RGBA, UInt8>(fileData: data)
  }
  
  private func proxyCrop(url: URL) async throws -> Data {
    let referenceWidth: Double = 2187
    let referenceHeight: Double = 2975
    let refX: Double = 89
    let refY: Double = 81
    let refW: Double = 2010
    let refH: Double = 2814
    
    guard let image = try? await downloadImage(url: url) else {
      print("Could not decode image at \(url)")
      throw Abort(.unsupportedMediaType, reason: "Could not decode image")
    }
    
    // Calculate scale factors
    let scaleX = Double(image.width) / referenceWidth
    let scaleY = Double(image.height) / referenceHeight
    
    // Compute scaled crop rect
    let x = Int(refX * scaleX)
    let y = Int(refY * scaleY)
    let w = Int(refW * scaleX)
    let h = Int(refH * scaleY)
    
    // Perform crop
    let cropped = image[x..<(x+w), y..<(y+h)]
    
    // Encode back to JPEG
    
    guard let jpegData = try? cropped.fileData(format: WriteFormat.jpeg(quality: 90)) else {
      throw Abort(.internalServerError, reason: "Encoding failed")
    }
    
    cropCache[url] = jpegData
    
    Task {
      saveToDisk(jpegData, for: url)
    }
    Task {
      setCache(for: url, data: jpegData)
    }
    
    return jpegData
  }
}

extension RGBA: ImageFileFormat {
  
}

extension ImageController {
  private var cacheDirectory: URL {
      FileManager.default.temporaryDirectory.appendingPathComponent("ImageCache")
  }
  
  private func filePath(for url: URL) -> URL {
    let filename = url.absoluteString
      .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
    return cacheDirectory.appendingPathComponent(filename).appendingPathExtension("jpg")
  }
  
  private func loadFromDisk(for url: URL) -> Data? {
    let path = filePath(for: url)
    return try? Data(contentsOf: path)
  }
  
  private func saveToDisk(_ data: Data, for url: URL) {
    let fm = FileManager.default
    try? fm.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    let path = filePath(for: url)
    try? data.write(to: path)
  }
}
