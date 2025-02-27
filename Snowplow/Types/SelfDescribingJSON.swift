import Foundation

public struct SelfDescribingJSON {
  let schema: SchemaDefinition
  let data: [String: Sendable]

  public init(schema: SchemaDefinition, data: [String: Sendable]) {
    self.schema = schema
    self.data = data
  }

  public init(schema: SchemaDefinition, payload: Payload) {
    self.schema = schema
    self.data = payload.content.dictionaryRepresentation
  }

  public init(schema: SchemaDefinition, dictionary: SnowplowDictionary) {
    self.schema = schema
    self.data = dictionary.dictionaryRepresentation
  }
}

extension SelfDescribingJSON {
  var base64EncodedRepresentation: String? {
    guard let data = try? JSONSerialization.data(withJSONObject: self.dictionaryRepresentation) else {
      return nil
    }
    return data.base64EncodedString()
  }

  var dictionaryRepresentation: [String: Sendable] {
    Self.dictionaryRepresentation(schema: schema, data: data)
  }

  static func dictionaryRepresentation(schema: SchemaDefinition, data: Sendable) -> [String: Sendable] {
    [
      "schema": schema.rawValue,
      "data": data
    ]
  }
}
