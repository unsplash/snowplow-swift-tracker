//
//  Payload.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import os

public typealias PayloadContentValue = Codable & Sendable
public typealias PayloadContent = [PropertyKey: PayloadContentValue]

public struct Payload: Identifiable, Sendable {
  public let id: String
  public let content: PayloadContent
  private let isBase64Encoded: Bool

  public init(_ content: PayloadContent, base64Encoded: Bool = true) {
    self.id = UUID().uuidString
    self.isBase64Encoded = base64Encoded
    self.content = content
  }

  public init(_ content: SelfDescribingJSON, base64Encoded: Bool = true) {
    self.id = UUID().uuidString
    self.isBase64Encoded = base64Encoded
    self.content = [
      PropertyKey.schema: content.schema.rawValue,
      PropertyKey.data: content.data
    ]
  }

  public func merged(with payload: Payload) -> Payload {
    var newContent = content
    newContent.merge(payload.content, uniquingKeysWith: { (current, _) in current })
    return Payload(newContent, base64Encoded: isBase64Encoded)
  }
}

extension Payload: Equatable {
  public static func == (lhs: Payload, rhs: Payload) -> Bool {
    lhs.id == rhs.id
  }
}

extension Payload: Codable {
  private enum CodingKeys: CodingKey {
    case content
    case id
    case isBase64Encoded
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let data = try container.decode(Data.self, forKey: .content)
    guard let decodedContent = try JSONSerialization.jsonObject(with: data, options: []) as? PayloadContent else {
      throw DecodingError.dataCorruptedError(forKey: CodingKeys.content, in: container, debugDescription: "")
    }
    content = decodedContent
    id = try container.decode(String.self, forKey: .id)
    isBase64Encoded = try container.decode(Bool.self, forKey: .isBase64Encoded)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let contentData = try JSONSerialization.data(withJSONObject: content, options: [])
    try container.encode(contentData, forKey: .content)
    try container.encode(id, forKey: .id)
    try container.encode(isBase64Encoded, forKey: .isBase64Encoded)
  }
}
