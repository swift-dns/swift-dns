import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    var buffer = DNSBuffer()
    var startIndex = 0

    Benchmark(
        "A_Response_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
            setup: {
                buffer = Resources.dnsResponseAExampleComPacket.buffer()
                buffer.moveReaderIndex(forwardBy: 42)
                buffer.moveDNSPortionStartIndex(forwardBy: 42)
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            buffer.moveReaderIndex(to: startIndex)
            let message = try Message(from: &buffer)
            blackHole(message)
        }
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
        "AAAA_Response_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
            setup: {
                buffer = Resources.dnsResponseAAAACloudflareComPacket.buffer()
                buffer.moveReaderIndex(forwardBy: 42)
                buffer.moveDNSPortionStartIndex(forwardBy: 42)
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            buffer.moveReaderIndex(to: startIndex)
            let message = try Message(from: &buffer)
            blackHole(message)
        }
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
        "TXT_Response_CPU_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000,
            setup: {
                buffer = Resources.dnsResponseTXTExampleComPacket.buffer()
                buffer.moveReaderIndex(forwardBy: 42)
                buffer.moveDNSPortionStartIndex(forwardBy: 42)
                startIndex = buffer.readerIndex
            }
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            buffer.moveReaderIndex(to: startIndex)
            let message = try Message(from: &buffer)
            blackHole(message)
        }
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
