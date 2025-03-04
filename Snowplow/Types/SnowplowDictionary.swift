import Foundation

public typealias SnowplowDictionary = [PropertyKey: Sendable]

public extension SnowplowDictionary {
  init?(dictionary: [String: Sendable]) {
    self.init()
    dictionary.forEach { (key, value) in
      guard let propertyKey = PropertyKey(rawValue: key) else {
        return
      }
      self[propertyKey] = value
    }
  }

  var dictionaryRepresentation: [String: Sendable] {
    var dictionary: [String: Sendable] = [:]
    for (key, value) in self {
      dictionary[key.rawValue] = value
    }
    return dictionary
  }
}

extension SnowplowDictionary {
  var queryItems: [URLQueryItem] {
    var items: [URLQueryItem] = []
    self.forEach { (key, value) in
      if let value = value as? String {
        items.append(.init(name: key.rawValue, value: value))
      } else {
        items.append(.init(name: key.rawValue, value: "\(value)"))
      }
    }
    return items
  }
}
