import Benchmark
import DNSModels

let cidrBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_CIDR_Create_Then_Check_Is_Loopback_100M

    /// 127.0.0.1
    let ipv4Loopback: IPv4Address = 0x7F_00_00_01
    Benchmark(
        "IPv4_CIDR_Create_Then_Check_Is_Loopback_100M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<100_000_000 {
            let isLoopback = ipv4Loopback.isLoopback
            blackHole(isLoopback)
        }
    }

    // MARK: - IPv4_CIDR_Create_Then_Check_Is_Multicast_100M

    /// 224.0.255.255
    let ipv4Multicast: IPv4Address = 0xE0_00_FF_FF
    Benchmark(
        "IPv4_CIDR_Create_Then_Check_Is_Multicast_100M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<100_000_000 {
            let isMulticast = ipv4Multicast.isMulticast
            blackHole(isMulticast)
        }
    }

    Benchmark(
        "IPv4_CIDR_Create_Then_Check_Is_Multicast_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let isMulticast = ipv4Multicast.isMulticast
        blackHole(isMulticast)
    }

    // MARK: - IPv6_CIDR_Create_Then_Check_Is_Loopback_100M

    /// ::1
    let ipv6Loopback: IPv6Address = 0x0000_0000_0000_0000_0000_0000_0000_0001
    Benchmark(
        "IPv6_CIDR_Create_Then_Check_Is_Loopback_100M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<100_000_000 {
            let isLoopback = ipv6Loopback.isLoopback
            blackHole(isLoopback)
        }
    }

    // MARK: - IPv6_CIDR_Create_Then_Check_Is_Multicast_100M

    /// FF00::FFFF:FFFF:FFFF:FFFF
    let ipv6Multicast: IPv6Address = 0xFF00_0000_0000_0000_FFFF_FFFF_FFFF_FFFF
    Benchmark(
        "IPv6_CIDR_Create_Then_Check_Is_Multicast_100M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<100_000_000 {
            let isMulticast = ipv6Multicast.isMulticast
            blackHole(isMulticast)
        }
    }

    Benchmark(
        "IPv6_CIDR_Create_Then_Check_Is_Multicast_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let isMulticast = ipv6Multicast.isMulticast
        blackHole(isMulticast)
    }
}
