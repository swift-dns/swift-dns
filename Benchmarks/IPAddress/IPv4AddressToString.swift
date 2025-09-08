import Benchmark
import DNSModels
import NIOCore

let ipv4AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_String_Encoding_Zero

    let ipv4Zero = IPv4Address(0, 0, 0, 0)
    Benchmark(
        "IPv4_String_Encoding_Zero_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let description = ipv4Zero.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Localhost

    let ipv4Localhost = IPv4Address(127, 0, 0, 1)
    Benchmark(
        "IPv4_String_Encoding_Localhost_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let description = ipv4Localhost.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Local_Broadcast

    let ipv4LocalBroadcast = IPv4Address(255, 255, 255, 255)
    Benchmark(
        "IPv4_String_Encoding_Local_Broadcast_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let description = ipv4LocalBroadcast.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Mixed

    let ipv4Mixed = IPv4Address(123, 45, 6, 0)
    Benchmark(
        "IPv4_String_Encoding_Mixed_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let description = ipv4Mixed.description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_String_Encoding_Mixed_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let description = ipv4Mixed.description
        blackHole(description)
    }
}
