import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    var buffer = DNSBuffer()
    var startIndex = 0

    Benchmark(
        "google_dot_com_Binary_Parsing_CPU_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
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
        for _ in 0..<2_000_000 {
            buffer.moveReaderIndex(to: startIndex)
            let domainName = try DomainName(from: &buffer)
            blackHole(domainName)
        }
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
        let domainName = try DomainName(from: &buffer)
        blackHole(domainName)
    }

    Benchmark(
        "app-analytics-services_dot_com_Binary_Parsing_CPU_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
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
        for _ in 0..<2_000_000 {
            buffer.moveReaderIndex(to: startIndex)
            let domainName = try DomainName(from: &buffer)
            blackHole(domainName)
        }
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
        let domainName = try DomainName(from: &buffer)
        blackHole(domainName)
    }

    let google = "google.com"
    Benchmark(
        "google_dot_com_String_Parsing_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let domainName = try! DomainName(string: google)
            blackHole(domainName)
        }
    }

    Benchmark(
        "google_dot_com_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        let domainName = try! DomainName(string: google)
        blackHole(domainName)
    }

    let appAnalyticsServices = "app-analytics-services.com"
    Benchmark(
        "app-analytics-services_dot_com_String_Parsing_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let domainName = try! DomainName(string: appAnalyticsServices)
            blackHole(domainName)
        }
    }

    Benchmark(
        "app-analytics-services_dot_com_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        let domainName = try! DomainName(string: appAnalyticsServices)
        blackHole(domainName)
    }

    let name1 = try! DomainName(string: "google.com.")
    let name2 = try! DomainName(string: "google.com.")
    Benchmark(
        "Equality_Check_CPU_20M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 100_000_000,
        )
    ) { benchmark in
        for _ in 0..<20_000_000 {
            blackHole(name1 == name2)
        }
    }

    Benchmark(
        "Equality_Check_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10,
        )
    ) { benchmark in
        blackHole(name1 == name2)
    }
}
