import Benchmark
import DNSModels
import NIOCore

let ipv6AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv6_String_Encoding_Zero

    let ipv6Zero: IPv6Address = 0
    Benchmark(
        "IPv6_String_Encoding_Zero_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let description = ipv6Zero.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_String_Encoding_Localhost

    let ipv6Localhost: IPv6Address = 0x0000_0000_0000_0000_0000_0000_0000_0001
    Benchmark(
        "IPv6_String_Encoding_Localhost_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let description = ipv6Localhost.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_String_Encoding_Max

    let ipv6Max: IPv6Address = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
    Benchmark(
        "IPv6_String_Encoding_Max_5M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<5_000_000 {
            let description = ipv6Max.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_String_Encoding_Mixed

    let ipv6Mixed: IPv6Address = 0x85a0_850a_8500_0000_0000_00af_805a_085a
    Benchmark(
        "IPv6_String_Encoding_Mixed_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            let description = ipv6Mixed.description
            blackHole(description)
        }
    }

    Benchmark(
        "IPv6_String_Encoding_Mixed_Malloc",
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
