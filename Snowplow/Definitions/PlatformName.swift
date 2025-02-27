import Foundation

enum PlatformName: String, Codable {
  case web
  case mobile          = "mob"
  case computer        = "pc"
  case server          = "srv"
  case application     = "app"
  case television      = "tv"
  case console         = "cnsl"
  case internetOfThing = "iot"
}
