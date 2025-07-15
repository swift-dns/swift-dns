// swift-tools-version: 6.2

import CompilerPluginSupport
// MARK: - BEGIN exact copy of the main package's Package.swift
import PackageDescription

let package = Package(
    name: "swift-dns",
    platforms: [
        // FIXME: remove this platform requirement, use @available instead
        .macOS("26.0")
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
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: settings
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
