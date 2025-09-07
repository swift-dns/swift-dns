import Benchmark
import DNSModels
import NIOCore

let ipv4AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_Zero_String_Description

    let ipv4Zero = IPv4Address(0, 0, 0, 0)
    Benchmark(
        "IPv4_Zero_String_Description",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 10,
            maxIterations: 50_000_000
        )
    ) { benchmark in
        let description = ipv4Zero.description
        blackHole(description)
    }

    // MARK: - IPv4_Localhost_String_Description

    let ipv4Localhost = IPv4Address(127, 0, 0, 1)
    Benchmark(
        "IPv4_Localhost_String_Description",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 10,
            maxIterations: 50_000_000
        )
    ) { benchmark in
        let description = ipv4Localhost.description
        blackHole(description)
    }

    // MARK: - IPv4_Local_Broadcast_String_Description

    let ipv4LocalBroadcast = IPv4Address(255, 255, 255, 255)
    Benchmark(
        "IPv4_Local_Broadcast_String_Description",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 10,
            maxIterations: 50_000_000
        )
    ) { benchmark in
        let description = ipv4LocalBroadcast.description
        blackHole(description)
    }

    // MARK: - IPv4_Mixed_String_Description

    let ipv4Mixed = IPv4Address(123, 45, 6, 0)
    Benchmark(
        "IPv4_Mixed_String_Description",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 10,
            maxIterations: 50_000_000
        )
    ) { benchmark in
        let description = ipv4Mixed.description
        blackHole(description)
    }

    Benchmark(
        "IPv4_Mixed_String_Description_Malloc",
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
