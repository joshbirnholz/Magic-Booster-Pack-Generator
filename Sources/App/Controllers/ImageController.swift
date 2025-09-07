//
//  ImageCrop.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Created by Josh Birnholz on 9/7/25.
//

import Vapor
import Swim

final class ImageController: Sendable {
  
  func artCrop(_ req: Request) async throws -> Response {
    guard let urlString = req.query[String.self, at: "url"], let url = URL(string: urlString) else {
      throw Abort(.badRequest, reason: "Missing or invalid url")
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
    
    return Response(
      status: .ok,
      headers: ["Content-Type": "image/jpeg"],
      body: .init(buffer: buffer)
    )
  }
  
}

extension RGBA: ImageFileFormat {
  
}
