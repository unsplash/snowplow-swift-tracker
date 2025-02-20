// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "Snowplow",
  platforms: [
    .iOS(.v15),
    .macOS(.v11),
    .tvOS(.v15)
  ],
  products: [
    .library(name: "Snowplow", targets: ["Snowplow"])
  ],
  targets: [
    .target(name: "Snowplow", path: "Snowplow")
  ]
)
