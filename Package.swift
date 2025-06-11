// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-dns",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.82.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.3"),
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
            ],
            swiftSettings: settings
        ),
        .target(
            name: "DNSClient",
            dependencies: [
                "DNSCore",
                "DNSModels",
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: settings
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
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny"),
    ]
}

// MARK: - Benchmark stuff
/// Should make all these conditional only for development with an env var or something

package.dependencies.append(
    .package(url: "https://github.com/ordo-one/package-benchmark.git", from: "1.29.3"),
)

package.targets += [
    .executableTarget(
        name: "DNSParserBenchmarks",
        dependencies: [
            "DNSModels",
            .product(name: "Benchmark", package: "package-benchmark"),
        ],
        path: "Benchmarks/DNSParser",
        plugins: [
            .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
        ]
    )
]
