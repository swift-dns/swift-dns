import Benchmark
import DNSModels
import NIOCore

let ipv6AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv6_Zero_String_Description

    let ipv6Zero: IPv6Address = 0
    Benchmark(
        "IPv6_Zero_String_Description",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 10,
            maxIterations: 50_000_000
        )
    ) { benchmark in
        let description = ipv6Zero.description
        blackHole(description)
    }

    // MARK: - IPv6_Localhost_String_Description

    let ipv6Localhost: IPv6Address = 0x0000_0000_0000_0000_0000_0000_0000_0001
    Benchmark(
        "IPv6_Localhost_String_Description",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 10,
            maxIterations: 50_000_000
        )
    ) { benchmark in
        let description = ipv6Localhost.description
        blackHole(description)
    }

    // MARK: - IPv6_Max_String_Description

    let ipv6Max: IPv6Address = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
    Benchmark(
        "IPv6_Max_String_Description",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 10,
            maxIterations: 50_000_000
        )
    ) { benchmark in
        let description = ipv6Max.description
        blackHole(description)
    }

    // MARK: - IPv6_Mixed_String_Description

    let ipv6Mixed: IPv6Address = 0x85a0_850a_8500_0000_0000_00af_805a_085a
    Benchmark(
        "IPv6_Mixed_String_Description",
        configuration: .init(
            metrics: [.throughput],
            warmupIterations: 10,
            maxIterations: 20_000_000
        )
    ) { benchmark in
        let description = ipv6Mixed.description
        blackHole(description)
    }

    Benchmark(
        "IPv6_Mixed_String_Description_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let description = ipv6Mixed.description
        blackHole(description)
    }
}
