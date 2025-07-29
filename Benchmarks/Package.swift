// swift-tools-version: 6.2

import CompilerPluginSupport
// MARK: - BEGIN exact copy of the main package's Package.swift
import PackageDescription

let package = Package(
    name: "swift-dns",
    traits: [
        .trait(name: "ServiceLifecycleSupport"),
        .default(enabledTraits: ["ServiceLifecycleSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.82.1"),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", from: "1.25.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.8.0"),
        .package(url: "https://github.com/mahdibm/swift-idna.git", from: "1.0.0-beta.1"),

        /// For the connection pool implementation copied from `PostgresNIO`.
        /// `PostgresNIO` is still supporting Swift 5.10 at the time of writing, so can't use stdlib atomics.
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "DNSCore",
            swiftSettings: settings
        ),
        .target(
            name: "DNSModels",
            dependencies: [
                "DNSCore",
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "SwiftIDNA", package: "swift-idna"),
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
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OrderedCollections", package: "swift-collections"),
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
        .enableExperimentalFeature(
            "AvailabilityMacro=swiftDNSApplePlatforms 26.0:macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0"
        ),
    ]
}

// MARK: - END exact copy of the main package's Package.swift

// MARK: - Add benchmark stuff now

package.dependencies.append(
    .package(
        url: "https://github.com/MahdiBM/package-benchmark.git",
        branch: "mmbm-range-relative-thresholds-options"
    ),
)

package.targets += [
    .executableTarget(
        name: "DNSParsing",
        dependencies: [
            "DNSModels",
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "DNSParsing",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
    .executableTarget(
        name: "Name",
        dependencies: [
            "DNSModels",
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "Name",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    ),
]
