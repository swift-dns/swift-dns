import Benchmark
import DNSModels
import NIOCore

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Android)
@preconcurrency import Android
#endif

let ipv4AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_String_Encoding_Zero

    let ipv4Zero = IPv4Address(0, 0, 0, 0)
    Benchmark(
        "IPv4_String_Encoding_Zero_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4Zero.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Localhost

    let ipv4Localhost = IPv4Address(127, 0, 0, 1)
    Benchmark(
        "IPv4_String_Encoding_Localhost_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4Localhost.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Local_Broadcast

    let ipv4LocalBroadcast = IPv4Address(255, 255, 255, 255)
    Benchmark(
        "IPv4_String_Encoding_Local_Broadcast_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let description = ipv4LocalBroadcast.description
            blackHole(description)
        }
    }

    // MARK: - IPv4_String_Encoding_Mixed

    let ipv4Mixed = IPv4Address(123, 45, 6, 0)
    Benchmark(
        "IPv4_String_Encoding_Mixed_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
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

    // MARK: IPv4_String_Encoding_Mixed_inet_ntop

    #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android)
    var ipv4MixedInetNtop = IPv4Address(123, 45, 6, 0)

    Benchmark(
        "IPv4_String_Encoding_Mixed_inet_ntop_15M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<15_000_000 {
            let ptr = UnsafeMutableRawPointer.allocate(byteCount: 15, alignment: 1).bindMemory(
                to: Int8.self,
                capacity: 15
            )
            inet_ntop(
                AF_INET,
                &ipv4MixedInetNtop.address,
                ptr,
                15
            )
            let description = String(cString: ptr)
            ptr.deinitialize(count: 15).deallocate()
            blackHole(description)
        }
    }

    Benchmark(
        "IPv4_String_Encoding_Mixed_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ptr = UnsafeMutableRawPointer.allocate(byteCount: 15, alignment: 1).bindMemory(
            to: Int8.self,
            capacity: 15
        )
        inet_ntop(
            AF_INET,
            &ipv4MixedInetNtop.address,
            ptr,
            15
        )
        let description = String(cString: ptr)
        ptr.deinitialize(count: 15).deallocate()
        blackHole(description)
    }
    #endif
}
