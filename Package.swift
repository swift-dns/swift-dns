// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-dns",
    traits: [
        .trait(name: "ServiceLifecycleSupport"),
        .default(enabledTraits: ["ServiceLifecycleSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.88.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.25.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.8.0"),
        .package(url: "https://github.com/swift-dns/swift-idna.git", from: "1.0.0-beta.17"),
        .package(url: "https://github.com/swift-dns/swift-endpoint.git", from: "1.0.0-beta.6"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "DNSCore",
            dependencies: [
                .product(name: "IPAddress", package: "swift-endpoint")
            ],
            swiftSettings: settings
        ),
        .target(
            name: "DNSModels",
            dependencies: [
                "DNSCore",
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "SwiftIDNA", package: "swift-idna"),
                .product(name: "Endpoint", package: "swift-endpoint"),
            ],
            swiftSettings: settings
        ),
        .target(
            name: "DNSClient",
            dependencies: [
                "DNSCore",
                "DNSModels",
                "_DNSConnectionPool",
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "_NIOFileSystem", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Endpoint", package: "swift-endpoint"),
                .product(
                    name: "ServiceLifecycle",
                    package: "swift-service-lifecycle",
                    condition: .when(traits: ["ServiceLifecycleSupport"])
                ),
            ],
            swiftSettings: settings
        ),
        .target(
            name: "_DNSConnectionPool",
            dependencies: [
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "DequeModule", package: "swift-collections"),
            ],
            path: "Sources/DNSConnectionPool",
            swiftSettings: []/// Intentional. This module is copied from PostgresNIO.
        ),
        .testTarget(
            name: "DNSTests",
            dependencies: [
                "DNSCore",
                "DNSModels",
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "DNSClientTests",
            dependencies: [
                "DNSModels",
                "DNSClient",
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOEmbedded", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "DNSModels",
                "DNSClient",
            ],
            swiftSettings: settings
        ),
    ]
)

var settings: [SwiftSetting] {
    [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("StrictMemorySafety"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature(
            "AvailabilityMacro=swiftDNSApplePlatforms 26:macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=swiftDNSApplePlatforms 14:macOS 14, iOS 17, tvOS 17, watchOS 10"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=swiftDNSApplePlatforms 15:macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=swiftDNSApplePlatforms 13:macOS 13, iOS 16, tvOS 16, watchOS 9"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=swiftDNSApplePlatforms 11:macOS 11, iOS 14, tvOS 14, watchOS 7"
        ),
        .enableExperimentalFeature(
            "AvailabilityMacro=swiftDNSApplePlatforms 10.15:macOS 10.15, iOS 13, tvOS 13, watchOS 6"
        ),
    ]
}
