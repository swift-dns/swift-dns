// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-dns",
    products: [
        .library(
            name: "DNSModels",
            targets: ["DNSModels"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4")
    ],
    targets: [
        .target(
            name: "DNSModels",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "DNSModelsTests",
            dependencies: ["DNSModels"],
            swiftSettings: settings
        ),
    ]
)

var settings: [SwiftSetting] {
    [
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
