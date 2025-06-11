import Benchmark
import DNSModels

let benchmarks: @Sendable () -> Void = {
    Benchmark(
        "200_000xParser_A_Response_CPUUser",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 1,
            maxDuration: .seconds(10),
            maxIterations: 10,
            thresholds: [
                .cpuUser: .init(
                    /// `3 - 1 == 2`% tolerance.
                    /// Will rely on the absolute threshold as the tighter threshold.
                    relative: [.p90: 3],
                    /// 11ms of tolerance.
                    absolute: [.p90: 11_000_000]
                )
            ]
        )
    ) { benchmark in
        var buffer = Resources.dnsResponseAExampleComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)
        let startIndex = buffer.readerIndex

        benchmark.startMeasurement()
        for _ in 0..<200_000 {
            buffer.moveReaderIndex(to: startIndex)

            let message = try Message(from: &buffer)
            blackHole(message)
        }
    }

    Benchmark(
        "Parser_A_Response_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxDuration: .seconds(10),
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
        "300_000xParser_AAAA_Response_CPUUser",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 1,
            maxDuration: .seconds(10),
            maxIterations: 10,
            thresholds: [
                .cpuUser: .init(
                    /// `3 - 1 == 2`% tolerance.
                    /// Will rely on the absolute threshold as the tighter threshold.
                    relative: [.p90: 3],
                    /// 11ms of tolerance.
                    absolute: [.p90: 11_000_000]
                )
            ]
        )
    ) { benchmark in
        var buffer = Resources.dnsResponseAAAACloudflareComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)
        let startIndex = buffer.readerIndex

        benchmark.startMeasurement()
        for _ in 0..<300_000 {
            buffer.moveReaderIndex(to: startIndex)

            let message = try Message(from: &buffer)
            blackHole(message)
        }
    }

    Benchmark(
        "Parser_AAAA_Response_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxDuration: .seconds(10),
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
        "300_000xParser_TXT_Response_CPUUser",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 1,
            maxDuration: .seconds(10),
            maxIterations: 10,
            thresholds: [
                .cpuUser: .init(
                    /// `3 - 1 == 2`% tolerance.
                    /// Will rely on the absolute threshold as the tighter threshold.
                    relative: [.p90: 3],
                    /// 11ms of tolerance.
                    absolute: [.p90: 11_000_000]
                )
            ]
        )
    ) { benchmark in
        var buffer = Resources.dnsResponseTXTExampleComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)
        let startIndex = buffer.readerIndex

        benchmark.startMeasurement()
        for _ in 0..<300_000 {
            buffer.moveReaderIndex(to: startIndex)

            let message = try Message(from: &buffer)
            blackHole(message)
        }
    }

    Benchmark(
        "Parser_TXT_Response_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxDuration: .seconds(10),
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
