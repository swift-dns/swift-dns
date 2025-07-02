import Benchmark
import DNSModels

let benchmarks: @Sendable () -> Void = {
    Benchmark(
        "200_000xA_Response_CPUUser",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 1,
            maxDuration: .seconds(10),
            maxIterations: 10,
            thresholds: [
                .cpuUser: .init(
                    /// `4 - 1 == 3`% tolerance.
                    /// Will rely on the absolute threshold as the tighter threshold.
                    relative: [.p90: 4],
                    /// 16ms of tolerance.
                    absolute: [.p90: 16_000_000]
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
        "A_Response_Malloc",
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
        "300_000xAAAA_Response_CPUUser",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 1,
            maxDuration: .seconds(10),
            maxIterations: 10,
            thresholds: [
                .cpuUser: .init(
                    /// `5 - 1 == 4`% tolerance.
                    /// Will rely on the absolute threshold as the tighter threshold.
                    relative: [.p90: 5],
                    /// 16ms of tolerance.
                    absolute: [.p90: 16_000_000]
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
        "AAAA_Response_Malloc",
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
        "300_000xTXT_Response_CPUUser",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 1,
            maxDuration: .seconds(10),
            maxIterations: 10,
            thresholds: [
                .cpuUser: .init(
                    /// `4 - 1 == 3`% tolerance.
                    /// Will rely on the absolute threshold as the tighter threshold.
                    relative: [.p90: 4],
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
        "TXT_Response_Malloc",
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
