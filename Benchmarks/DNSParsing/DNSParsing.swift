import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.units = [.throughput: .kilo]
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    var buffer = DNSBuffer()
    var startIndex = 0

    Benchmark(
        "A_Response_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 10_000_000,
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
        "A_Response_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var buffer = Resources.dnsResponseAExampleComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        benchmark.startMeasurement()
        let message = try Message(from: &buffer)
        blackHole(message)
    }

    Benchmark(
        "A_Response_Memory_Leaked",
        configuration: .init(
            metrics: [.memoryLeaked],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var buffer = Resources.dnsResponseAExampleComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        benchmark.startMeasurement()
        let message = try Message(from: &buffer)
        blackHole(message)
    }

    Benchmark(
        "AAAA_Response_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 10_000_000,
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
        "AAAA_Response_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var buffer = Resources.dnsResponseAAAACloudflareComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        benchmark.startMeasurement()
        let message = try Message(from: &buffer)
        blackHole(message)
    }

    Benchmark(
        "TXT_Response_Throughput",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 1000,
            maxIterations: 10_000_000,
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

    Benchmark(
        "TXT_Response_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var buffer = Resources.dnsResponseTXTExampleComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        benchmark.startMeasurement()
        let message = try Message(from: &buffer)
        blackHole(message)
    }
}
