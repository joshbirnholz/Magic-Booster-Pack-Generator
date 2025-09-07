//
//  ImageCrop.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 9/7/25.
//

import Vapor
import Swim

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
    guard let urlString = req.query[String.self, at: "url"], let url = URL(string: urlString) else {
      throw Abort(.badRequest, reason: "Missing or invalid url")
    }
    
    if let data = getCache(for: url) ?? loadFromDisk(for: url) {
      setCache(for: url, data: data)
      return Response(status: .ok,
                      headers: ["Content-Type": "image/jpeg"],
                      body: .init(data: data))
    }
    
    let referenceWidth: Double = 2010
    let referenceHeight: Double = 2814
    let refX: Double = 155
    let refY: Double = 319
    let refW: Double = 1699
    let refH: Double = 1242
    
    // Download image
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = try? Image<RGBA, UInt8>(fileData: data) else {
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
    
    guard let jpegData = try? cropped.fileData(format: .jpeg(quality: 90)) else {
      throw Abort(.internalServerError, reason: "Encoding failed")
    }
    
    var buffer = ByteBufferAllocator().buffer(capacity: jpegData.count)
    buffer.writeBytes(jpegData)
    
    cropCache[url] = jpegData
    
    Task {
      saveToDisk(jpegData, for: url)
    }
    Task {
      setCache(for: url, data: jpegData)
    }
    
    return Response(
      status: .ok,
      headers: ["Content-Type": "image/jpeg"],
      body: .init(buffer: buffer)
    )
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
