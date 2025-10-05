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
}
