import Foundation

enum JSONCoding {
  static let encoder = JSONEncoder()
  static let decoder = JSONDecoder()

  static func data(fromJSONObject object: Any) throws -> Data {
    try JSONSerialization.data(withJSONObject: object)
  }

  static func base64EncodedString(fromJSONObject object: Any) throws -> String {
    try data(fromJSONObject: object).base64EncodedString()
  }
}
