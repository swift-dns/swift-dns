import Benchmark
import DNSModels
import NIOCore

#if os(Linux) || os(FreeBSD) || os(Android)

#if canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Android)
@preconcurrency import Android
#endif

#elseif os(Windows)
import ucrt
#elseif canImport(Darwin)
import Darwin
#elseif canImport(WASILibc)
@preconcurrency import WASILibc
#else
#error("The IPv4AddressFromString benchmarks module was unable to identify your C library.")
#endif

let ipv4AddressFromStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv4_String_Decoding_Zero

    Benchmark(
        "IPv4_String_Decoding_Zero_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let ip = IPv4Address("0.0.0.0").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv4_String_Decoding_Localhost

    Benchmark(
        "IPv4_String_Decoding_Localhost_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let ip = IPv4Address("127.0.0.1").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv4_String_Decoding_Local_Broadcast

    Benchmark(
        "IPv4_String_Decoding_Local_Broadcast_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let ip = IPv4Address("255.255.255.255").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_String_Decoding_Local_Broadcast_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv4Address("255.255.255.255").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: IPv4_String_Decoding_Broadcast_inet_pton

    Benchmark(
        "IPv4_String_Decoding_Local_Broadcast_inet_pton_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            var ipv4SocketAddress = sockaddr_in()
            _ = "255.255.255.255".withCString { p in
                inet_pton(AF_INET, p, &ipv4SocketAddress.sin_addr)
            }
            blackHole(ipv4SocketAddress)
        }
    }

    Benchmark(
        "IPv4_String_Decoding_Local_Broadcast_inet_pton_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var ipv4SocketAddress = sockaddr_in()
        _ = "255.255.255.255".withCString { p in
            inet_pton(AF_INET, p, &ipv4SocketAddress.sin_addr)
        }
        blackHole(ipv4SocketAddress)
    }
}
