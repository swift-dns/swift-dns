import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.units = [.throughput: .kilo]
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    var buffer = DNSBuffer()
    var startIndex = 0

    Benchmark(
        "google_dot_com_Binary_Parsing_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 10_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 4])
            ],
            setup: {
                buffer = DNSBuffer(bytes: [
                    0x06, 0x67, 0x6f, 0x6f,
                    0x67, 0x6c, 0x65, 0x03,
                    0x63, 0x6f, 0x6d, 0x00,
                ])
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let name = try Name(from: &buffer)
        blackHole(name)
    }

    Benchmark(
        "google_dot_com_Binary_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
            setup: {
                buffer = DNSBuffer(bytes: [
                    0x06, 0x67, 0x6f, 0x6f,
                    0x67, 0x6c, 0x65, 0x03,
                    0x63, 0x6f, 0x6d, 0x00,
                ])
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let name = try Name(from: &buffer)
        blackHole(name)
    }

    Benchmark(
        "app-analytics-services_dot_com_Binary_Parsing_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 10_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 6])
            ],
            setup: {
                buffer = DNSBuffer(bytes: [
                    0x16, 0x61, 0x70, 0x70,
                    0x2d, 0x61, 0x6e, 0x61,
                    0x6c, 0x79, 0x74, 0x69,
                    0x63, 0x73, 0x2d, 0x73,
                    0x65, 0x72, 0x76, 0x69,
                    0x63, 0x65, 0x73, 0x03,
                    0x63, 0x6f, 0x6d, 0x00,
                ])
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let name = try Name(from: &buffer)
        blackHole(name)
    }

    Benchmark(
        "app-analytics-services_dot_com_Binary_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
            setup: {
                buffer = DNSBuffer(bytes: [
                    0x16, 0x61, 0x70, 0x70,
                    0x2d, 0x61, 0x6e, 0x61,
                    0x6c, 0x79, 0x74, 0x69,
                    0x63, 0x73, 0x2d, 0x73,
                    0x65, 0x72, 0x76, 0x69,
                    0x63, 0x65, 0x73, 0x03,
                    0x63, 0x6f, 0x6d, 0x00,
                ])
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let name = try Name(from: &buffer)
        blackHole(name)
    }

    let google = "google.com"
    Benchmark(
        "google_dot_com_String_Parsing_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 10_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 6])
            ]
        )
    ) { benchmark in
        let name = try! Name(string: google)
        blackHole(name)
    }

    Benchmark(
        "google_dot_com_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        let name = try! Name(string: google)
        blackHole(name)
    }

    let appAnalyticsServices = "app-analytics-services.com"
    Benchmark(
        "app-analytics-services_dot_com_String_Parsing_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 10_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 4])
            ]
        )
    ) { benchmark in
        let name = try! Name(string: appAnalyticsServices)
        blackHole(name)
    }

    Benchmark(
        "app-analytics-services_dot_com_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        let name = try! Name(string: appAnalyticsServices)
        blackHole(name)
    }

    let name1 = try! Name(string: "google.com.")
    let name2 = try! Name(string: "google.com.")
    Benchmark(
        "Case_Insensitive_Equality_Check_Fast_Path_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 100_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 6])
            ]
        )
    ) { benchmark in
        blackHole(name1 == name2)
    }

    Benchmark(
        "Case_Insensitive_Equality_Check_Fast_Path_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        blackHole(name1 == name2)
    }

    let lowercasedASCIIDomain = try! Name(string: "google.com.")
    let uppercasedASCIIDomain = try! Name(string: "GOOGLE.COM.")
    Benchmark(
        "Case_Insensitive_Equality_Check_Any_ASCII_Path_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 100_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 3])
            ]
        )
    ) { benchmark in
        blackHole(lowercasedASCIIDomain == uppercasedASCIIDomain)
    }

    Benchmark(
        "Case_Insensitive_Equality_Check_Any_ASCII_Path_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        blackHole(lowercasedASCIIDomain == uppercasedASCIIDomain)
    }

    let lowercasedUTF8Domain = try! Name(string: "googße.com.")
    let uppercasedUTF8Domain = try! Name(string: "GOOGSSe.COM.")
    Benchmark(
        "Case_Insensitive_Equality_Check_Any_UTF8_Path_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 100_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 3])
            ]
        )
    ) { benchmark in
        blackHole(lowercasedUTF8Domain == uppercasedUTF8Domain)
    }

    Benchmark(
        "Case_Insensitive_Equality_Check_Any_UTF8_Path_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        blackHole(lowercasedUTF8Domain == uppercasedUTF8Domain)
    }
}
