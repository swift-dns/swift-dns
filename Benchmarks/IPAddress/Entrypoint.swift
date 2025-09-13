import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    /// package-benchmark sorts benchmarks by name.
    /// We do a warmup benchmark here to make sure the results are not skewed.
    Benchmark(
        "111_Machine_Warmup_Benchmark",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 1,
            maxIterations: 1_000_000
        )
    ) { benchmark in
        for _ in 0..<1_000 {
            let ip = IPv6Address("FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF").unsafelyUnwrapped
            let description = ip.description
            blackHole(ip)
            blackHole(description)
        }
    }

    cidrBenchmarks()

    ipv4AddressFromStringBenchmarks()
    ipv4AddressToStringBenchmarks()

    ipv6AddressFromStringBenchmarks()
    ipv6AddressToStringBenchmarks()
}
