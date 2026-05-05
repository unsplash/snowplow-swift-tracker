import Foundation

extension [String: Sendable] {
  var base64EncodedRepresentation: String? {
    try? JSONCoding.base64EncodedString(fromJSONObject: self)
  }
}
