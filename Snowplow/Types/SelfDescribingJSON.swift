import Foundation

public struct SelfDescribingJSON: Sendable {
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
    guard let wrapper = try? JSONCoding.decoder.decode(SelfDescribingJSONCodableWrapper.self, from: data),
          let decodedSchema = SchemaDefinition(rawValue: wrapper.schema) else {
      return nil
    }

    self.schema = decodedSchema
    self.data = wrapper.data.mapValues { $0.sendableValue }
  }
}

extension SelfDescribingJSON {
  var base64EncodedRepresentation: String? {
    try? JSONCoding.base64EncodedString(fromJSONObject: self.dictionaryRepresentation)
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

private extension SelfDescribingJSON {
  struct SelfDescribingJSONCodableWrapper: Codable {
    let schema: String
    let data: [String: JSONValue]
  }
}
