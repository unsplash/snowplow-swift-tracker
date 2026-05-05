import Foundation

public struct Payload: Identifiable, Sendable {
  public let id: String
  public let content: SnowplowDictionary
  private let isBase64Encoded: Bool

  public init(_ content: SnowplowDictionary, base64Encoded: Bool = true) {
    self.id = UUID().uuidString
    self.isBase64Encoded = base64Encoded
    self.content = content
  }

  public init(_ content: SelfDescribingJSON, base64Encoded: Bool = true) {
    self.id = UUID().uuidString
    self.isBase64Encoded = base64Encoded
    self.content = [
      .schema: content.schema.rawValue,
      .data: content.data
    ]
  }

  public init?(dictionary: [String: Sendable]) {
    guard let id = dictionary["id"] as? String else {
      return nil
    }

    guard let contentDictionary = dictionary["content"] as? [String: Sendable] else {
      return nil
    }
    let content = SnowplowDictionary(dictionary: contentDictionary)

    guard let isBase64Encoded = dictionary["isBase64Encoded"] as? Bool else {
      return nil
    }

    self.id = id
    self.content = content
    self.isBase64Encoded = isBase64Encoded
  }

  public init?(data: Data) {
    guard let wrapper = try? JSONCoding.decoder.decode(PayloadCodableWrapper.self, from: data) else {
      return nil
    }

    self.init(wrapper: wrapper)
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
  public init(from decoder: Decoder) throws {
    let wrapper = try PayloadCodableWrapper(from: decoder)
    guard let payload = Payload(wrapper: wrapper) else {
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                              debugDescription: "Cannot decode payload content."))
    }
    self = payload
  }

  public func encode(to encoder: Encoder) throws {
    let contentDictionary = content.dictionaryRepresentation
    let encodedContent = try contentDictionary.reduce(into: [String: JSONValue]()) { result, item in
      guard let jsonValue = JSONValue(sendable: item.value) else {
        throw EncodingError.invalidValue(item.value,
                                         .init(codingPath: encoder.codingPath,
                                               debugDescription: "Unsupported payload content value."))
      }
      result[item.key] = jsonValue
    }

    let wrapper = PayloadCodableWrapper(id: id,
                                        content: encodedContent,
                                        isBase64Encoded: isBase64Encoded)
    try wrapper.encode(to: encoder)
  }
}

extension Payload {
  var dictionaryRepresentation: [String: Any] {
    [
      "id": id,
      "content": content.dictionaryRepresentation,
      "isBase64Encoded": isBase64Encoded
    ]
  }
}

private extension Payload {
  struct PayloadCodableWrapper: Codable {
    let id: String
    let content: [String: JSONValue]
    let isBase64Encoded: Bool
  }

  init?(wrapper: PayloadCodableWrapper) {
    let contentDictionary = wrapper.content.mapValues { $0.sendableValue }
    let content = SnowplowDictionary(dictionary: contentDictionary)

    self.id = wrapper.id
    self.content = content
    self.isBase64Encoded = wrapper.isBase64Encoded
  }
}
