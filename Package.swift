// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Snowplow",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_12),
        .tvOS(.v11)
    ],
    products: [
    .library(name: "Snowplow",
             targets: ["Snowplow"])
    ],
    targets: [
    .target(
        name: "Snowplow",
        path: "Snowplow")
    ]
)
