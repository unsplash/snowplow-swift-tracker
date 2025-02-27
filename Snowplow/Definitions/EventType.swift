import Foundation

enum EventType: String, Codable {
  case pageView         = "pv"
  case structured       = "se"
  case unstructured     = "ue"
  case ecommerce        = "tr"
  case ecommerceItem    = "ti"
}
