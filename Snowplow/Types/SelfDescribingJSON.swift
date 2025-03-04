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

  public init?(data: Data) {
    guard let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return nil
    }

    guard let schemaValue = dictionary["schema"] as? String,
          let decodedSchema = SchemaDefinition(rawValue: schemaValue) else {
      return nil
    }

    guard let decodedData = dictionary["data"] as? [String: Sendable] else {
      return nil
    }

    self.schema = decodedSchema
    self.data = decodedData
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
