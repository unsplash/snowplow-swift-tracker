//
//  Payload.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-05.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation
import os

public struct Payload: Identifiable {
  public let id: String
  private(set) var content = [String: Any]()
  private let isBase64Encoded: Bool

  public init(isBase64Encoded: Bool = true) {
    self.id = UUID().uuidString
    self.isBase64Encoded = isBase64Encoded
  }

  public init(_ content: [PropertyKey: Any], isBase64Encoded: Bool = true) {
    self.init(isBase64Encoded: isBase64Encoded)
    for (key, value) in content {
      self.content[key.rawValue] = value
    }
  }

  public init(_ content: SelfDescribingJSON, base64Encoded: Bool = true) {
    self.init(isBase64Encoded: base64Encoded)
    self.content = [
      PropertyKey.schema.rawValue: content.schema.rawValue,
      PropertyKey.data.rawValue: content.data
    ]
  }

  public mutating func set(_ value: String?, forKey key: PropertyKey) {
    content[key.rawValue] = value
  }

  public mutating func set(_ object: [String: Any], forKey key: PropertyKey) {
    content[key.rawValue] = object
  }

  public mutating func set(_ payload: Payload, forKey key: PropertyKey) {
    content[key.rawValue] = payload.content
  }

  public mutating func set(_ json: SelfDescribingJSON, forKey key: PropertyKey) {
    let dictionaryRepresentation: [String: Any] = [
      PropertyKey.schema.rawValue: json.schema.rawValue,
      PropertyKey.data.rawValue: json.data
    ]
    set(dictionaryRepresentation, forKey: key)
  }

  public mutating func add(values: [PropertyKey: String]) {
    for (key, value) in values {
      content[key.rawValue] = value
    }
  }

  public mutating func merge(payload: Payload) {
    content.merge(payload.content, uniquingKeysWith: { (current, _) in current })
  }

  public subscript(key: PropertyKey) -> Any? {
    set { content[key.rawValue] = newValue }
    get { return content[key.rawValue] }
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
    guard let decodedContent = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
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
