// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-dns",
    platforms: [
        // FIXME: remove this platform requirement, use @available instead
        .macOS("26.0")
    ],
    traits: [
        .trait(name: "ServiceLifecycleSupport"),
        .default(enabledTraits: ["ServiceLifecycleSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.82.1"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.32.0"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.25.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.8.0"),

        /// For the connection pool implementation copied from `PostgresNIO`.
        /// `PostgresNIO` is still supporting Swift 5.10 at the time of writing, so can't use stdlib atomics.
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "DNSCore",
            swiftSettings: settings
        ),
        .target(name: "CSwiftDNSIDNA"),
        .target(
            name: "DNSModels",
            dependencies: [
                "DNSCore",
                "CSwiftDNSIDNA",
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "NIOCore", package: "swift-nio"),
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
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "DequeModule", package: "swift-collections"),
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
        .target(
            name: "CSwiftDNSIDNATesting",
            cSettings: cSettingsIgnoringInvalidSourceCharacters
        ),
        .testTarget(
            name: "DNSTests",
            dependencies: [
                "DNSCore",
                "DNSModels",
                "CSwiftDNSIDNATesting",
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
                .product(name: "DequeModule", package: "swift-collections"),
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
        .enableExperimentalFeature(
            "AvailabilityMacro=swiftDNS 1.0:macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0"
        ),
    ]
}

var cSettingsIgnoringInvalidSourceCharacters: [CSetting] {
    [
        .unsafeFlags(
            [
                "-Wno-unknown-escape-sequence",
                "-Wno-invalid-source-encoding",
            ]
        )
    ]
}
