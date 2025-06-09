import Benchmark
import DNSModels

let benchmarks: @Sendable () -> Void = {
    Benchmark(
        "1000xParser_A_Response_CPUUser",
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

        for _ in 0..<1000 {
            buffer.moveReaderIndex(to: startIndex)

            benchmark.startMeasurement()

            let message = try Message(from: &buffer)
            blackHole(message)

            benchmark.stopMeasurement()
        }
    }
}
