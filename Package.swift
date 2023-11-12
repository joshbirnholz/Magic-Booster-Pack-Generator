// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "TabletopSimulatorMagicBoosterPackServer",
	platforms: [
		.macOS(.v10_15),
	],
//    products: [
//        .library(name: "TabletopSimulatorMagicBoosterPackServer", targets: ["App"]),
//    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
		.package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
		.package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc"),
		.package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-rc"),
		.package(url: "https://github.com/vapor/jwt.git", from: "4.0.0-rc"),
    .package(url: "https://github.com/yaslab/CSV.swift.git", .upToNextMinor(from: "2.4.3"))
    ],
    targets: [
        .target(name: "App", dependencies: [
			.product(name: "Fluent", package: "fluent"),
			.product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
			.product(name: "Vapor", package: "vapor"),
			.product(name: "CSV", package: "CSV.swift"),
		]),
        .target(name: "Run", dependencies: [
			.target(name: "App"),
		]),
        .testTarget(name: "AppTests", dependencies: [
			.target(name: "App"),
		])
    ]
)

