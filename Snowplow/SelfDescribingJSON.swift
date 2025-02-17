//
//  SelfDescribingJSON.swift
//  Snowplow
//
//  Created by Olivier Collet on 2018-04-07.
//  Copyright © 2018 Unsplash. All rights reserved.
//

import Foundation

public struct SelfDescribingJSON {
  
  let schema: String
  let data: Any
  
  public init(schema: SchemaDefinition, data: Payload) {
    self.schema = schema.rawValue
    self.data = data.content
  }
  
  public init(schema: SchemaDefinition, data: [Payload]) {
    self.schema = schema.rawValue
    self.data = data.map({ $0.content })
  }
  
  public init(schema: SchemaDefinition, data: SelfDescribingJSON) {
    self.schema = schema.rawValue
    self.data = data.dictionaryRepresentation
  }
  
  public init(schema: SchemaDefinition, data: [SelfDescribingJSON]) {
    self.schema = schema.rawValue
    self.data = data.map({ $0.dictionaryRepresentation })
  }
  
  public init(schema: SchemaDefinition, data: [PropertyKey: Any]) {
    self.schema = schema.rawValue
    var dictionary = [String: Any]()
    for (key, value) in data {
      dictionary[key.rawValue] = value
    }
    self.data = dictionary
  }
  
  public var dictionaryRepresentation: [String: Any] {
    return [
      PropertyKey.schema.rawValue: schema,
      PropertyKey.data.rawValue: data
    ]
  }
  
}

extension SelfDescribingJSON {
  
  public var base64EncodedRepresentation: String? {
    guard let data = try? JSONSerialization.data(withJSONObject: dictionaryRepresentation, options: []) else {
      return nil
    }
    return data.base64EncodedString()
  }
  
}
