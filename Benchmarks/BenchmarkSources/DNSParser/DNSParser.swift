import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    var buffer = DNSBuffer()
    var startIndex = 0

    Benchmark(
        "A_Response",
        configuration: .init(
            metrics: [.throughput, .mallocCountTotal],
            warmupIterations: 1000,
            maxDuration: .seconds(5),
            maxIterations: 10_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 5])
            ],
            setup: {
                buffer = Resources.dnsResponseAExampleComPacket.buffer()
                buffer.moveReaderIndex(forwardBy: 42)
                buffer.moveDNSPortionStartIndex(forwardBy: 42)
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let message = try Message(from: &buffer)
        blackHole(message)
    }

    Benchmark(
        "AAAA_Response",
        configuration: .init(
            metrics: [.throughput, .mallocCountTotal],
            warmupIterations: 1000,
            maxDuration: .seconds(5),
            maxIterations: 10_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 4])
            ],
            setup: {
                buffer = Resources.dnsResponseAAAACloudflareComPacket.buffer()
                buffer.moveReaderIndex(forwardBy: 42)
                buffer.moveDNSPortionStartIndex(forwardBy: 42)
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let message = try Message(from: &buffer)
        blackHole(message)
    }

    Benchmark(
        "TXT_Response",
        configuration: .init(
            metrics: [.throughput, .mallocCountTotal],
            warmupIterations: 1000,
            maxDuration: .seconds(5),
            maxIterations: 10_000_000,
            thresholds: [
                .throughput: .init(relative: [.p90: 4])
            ],
            setup: {
                buffer = Resources.dnsResponseTXTExampleComPacket.buffer()
                buffer.moveReaderIndex(forwardBy: 42)
                buffer.moveDNSPortionStartIndex(forwardBy: 42)
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        buffer.moveReaderIndex(to: startIndex)
        benchmark.startMeasurement()
        let message = try Message(from: &buffer)
        blackHole(message)
    }
}
