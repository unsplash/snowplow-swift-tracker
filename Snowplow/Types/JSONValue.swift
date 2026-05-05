import Foundation

enum JSONValue: Codable, Sendable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object([String: JSONValue])
  case array([JSONValue])
  case null

  init?(sendable: Sendable) {
    switch sendable {
    case let value as String:
      self = .string(value)
    case let value as Int:
      self = .number(Double(value))
    case let value as Int8:
      self = .number(Double(value))
    case let value as Int16:
      self = .number(Double(value))
    case let value as Int32:
      self = .number(Double(value))
    case let value as Int64:
      self = .number(Double(value))
    case let value as UInt:
      self = .number(Double(value))
    case let value as UInt8:
      self = .number(Double(value))
    case let value as UInt16:
      self = .number(Double(value))
    case let value as UInt32:
      self = .number(Double(value))
    case let value as UInt64:
      self = .number(Double(value))
    case let value as Float:
      self = .number(Double(value))
    case let value as Double:
      self = .number(value)
    case let value as Bool:
      self = .bool(value)
    case _ as NSNull:
      self = .null
    case let value as [String: Sendable]:
      let mapped = value.compactMapValues { JSONValue(sendable: $0) }
      guard mapped.count == value.count else {
        return nil
      }
      self = .object(mapped)
    case let value as [Sendable]:
      let mapped = value.compactMap { JSONValue(sendable: $0) }
      guard mapped.count == value.count else {
        return nil
      }
      self = .array(mapped)
    default:
      return nil
    }
  }

  var sendableValue: Sendable {
    switch self {
    case .string(let value):
      return value
    case .number(let value):
      return value
    case .bool(let value):
      return value
    case .object(let value):
      return value.mapValues { $0.sendableValue }
    case .array(let value):
      return value.map { $0.sendableValue }
    case .null:
      return NSNull()
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      self = .null
      return
    }

    if let object = try? container.decode([String: JSONValue].self) {
      self = .object(object)
      return
    }

    if let array = try? container.decode([JSONValue].self) {
      self = .array(array)
      return
    }

    if let bool = try? container.decode(Bool.self) {
      self = .bool(bool)
      return
    }

    if let number = try? container.decode(Double.self) {
      self = .number(number)
      return
    }

    if let string = try? container.decode(String.self) {
      self = .string(string)
      return
    }

    throw DecodingError.dataCorruptedError(in: container,
                                           debugDescription: "Unsupported JSON value.")
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .string(let value):
      try container.encode(value)
    case .number(let value):
      try container.encode(value)
    case .bool(let value):
      try container.encode(value)
    case .object(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    case .null:
      try container.encodeNil()
    }
  }
}
