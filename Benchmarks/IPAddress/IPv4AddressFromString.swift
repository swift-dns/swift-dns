import Benchmark
import DNSModels
import NIOCore

let ipv4AddressFromStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_Zero_String_Parsing

    Benchmark(
        "IPv4_Zero_String_Parsing_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let ip = IPv4Address("0.0.0.0").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv4_Localhost_String_Parsing

    Benchmark(
        "IPv4_Localhost_String_Parsing_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let ip = IPv4Address("127.0.0.1").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv4_Local_Broadcast_String_Parsing

    Benchmark(
        "IPv4_Local_Broadcast_String_Parsing_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let ip = IPv4Address("255.255.255.255").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_Local_Broadcast_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv4Address("255.255.255.255").unsafelyUnwrapped
        blackHole(ip)
    }
}
