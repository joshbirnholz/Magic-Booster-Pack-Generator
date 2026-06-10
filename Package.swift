// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "TabletopSimulatorMagicBoosterPackServer",
  platforms: [
    .macOS(.v13),
  ],
  dependencies: [
    // 💧 A server-side Swift web framework.
    .package(url: "https://github.com/vapor/vapor.git", from: "4.92.0"),

    // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
    .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-rc"),
    .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc"),

    // CSV parsing
    .package(url: "https://github.com/yaslab/CSV.swift.git", .upToNextMinor(from: "2.4.3")),

    // XML decoding
    .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.17.1"),
    .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    .package(url: "https://github.com/t-ae/swim.git", branch: "master"),

    // Transitive dependency of Vapor, pinned explicitly because 1.1.1 fails to
    // compile under newer Swift toolchains (a Sendable/region-isolation error
    // in MultiProducerSingleConsumerChannel). 1.1.2 fixes it and remains
    // compatible with the server's Swift 6.0 build.
    .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.1.2"),
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        .product(name: "Fluent", package: "fluent"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "Vapor", package: "vapor"),
        .product(name: "CSV", package: "CSV.swift"),
        .product(name: "XMLCoder", package: "XMLCoder"),
        .product(name: "SwiftSoup", package: "SwiftSoup"),
        .product(name: "Swim", package: "Swim")
      ]
    ),
    .executableTarget(
      name: "Run",
      dependencies: [
        .target(name: "App")
      ]
    ),
    .testTarget(
      name: "AppTests",
      dependencies: [
        .target(name: "App")
      ]
    )
  ]
)
