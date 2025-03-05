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

    guard let contentDictionary = dictionary["content"] as? [String: Sendable],
          let content = SnowplowDictionary(dictionary: contentDictionary) else {
      return nil
    }

    guard let isBase64Encoded = dictionary["isBase64Encoded"] as? Bool else {
      return nil
    }

    self.id = id
    self.content = content
    self.isBase64Encoded = isBase64Encoded
  }

  public init?(data: Data) {
    guard let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Sendable] else {
      return nil
    }

    self.init(dictionary: dictionary)
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

extension Payload {
  var dictionaryRepresentation: [String: Any] {
    [
      "id": id,
      "content": content.dictionaryRepresentation,
      "isBase64Encoded": isBase64Encoded
    ]
  }
}
