//
//  SelfDescribingJSON.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-07.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

public struct SelfDescribingJSON: Sendable {
  let schema: SchemaDefinition
  let data: PayloadContentValue

  public init(schema: SchemaDefinition, data: PayloadContentValue) {
    self.schema = schema
    self.data = data
  }
}

extension SelfDescribingJSON: Codable {
  private enum CodingKeys: CodingKey {
    case schema
    case data
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schema = try container.decode(SchemaDefinition.self, forKey: .schema)
    if let jsonData = try? container.decode(SelfDescribingJSON.self, forKey: .data) {
      data = jsonData
    } else if let stringData = try? container.decode(String.self, forKey: .data) {
      data = stringData
    } else if let payloadData = try? container.decode(Payload.self, forKey: .data) {
      data = payloadData
    } else {
      throw DecodingError.dataCorruptedError(forKey: CodingKeys.data, in: container, debugDescription: "Cannot decode data.")
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(schema, forKey: .schema)
    try container.encode(data, forKey: .data)
  }
}

extension SelfDescribingJSON {
  public var base64EncodedRepresentation: String? {
    guard let data = try? JSONEncoder().encode(data) else {
      return nil
    }
    return data.base64EncodedString()
  }
}
