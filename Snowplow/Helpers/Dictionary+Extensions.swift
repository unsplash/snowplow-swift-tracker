import Foundation

extension [String: Sendable] {
  var base64EncodedRepresentation: String? {
    guard let data = try? JSONSerialization.data(withJSONObject: self) else {
      return nil
    }
    return data.base64EncodedString()
  }
}
