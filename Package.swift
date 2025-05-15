// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "TabletopSimulatorMagicBoosterPackServer",
  platforms: [
    .macOS(.v10_15),
  ],
  dependencies: [
    // 💧 A server-side Swift web framework.
    .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
    // 🗄 An ORM for SQL and NoSQL databases.
    .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
    // 🐘 Fluent driver for Postgres.
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
    // 🍃 An expressive, performant, and extensible templating language built for Swift.
    .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
    // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    // CSV parsing
    .package(url: "https://github.com/yaslab/CSV.swift.git", .upToNextMinor(from: "2.4.3")),
    // XML decoding
    .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.17.1")
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        .product(name: "Fluent", package: "fluent"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "Leaf", package: "leaf"),
        .product(name: "Vapor", package: "vapor"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "CSV", package: "CSV.swift"),
        .product(name: "XMLCoder", package: "XMLCoder")
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
        .target(name: "App"),
        .product(name: "VaporTesting", package: "vapor"),
      ]
    )
  ]
)
