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

let ipv6AddressFromStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv6_String_Decoding_Uncompressed

    Benchmark(
        "IPv6_String_Decoding_Uncompressed_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            let ip = IPv6Address("[2001:0db8:85a3:f109:197a:8a2e:0370:7334]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_String_Decoding_Zero_Compressed

    Benchmark(
        "IPv6_String_Decoding_Zero_Compressed_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let ip = IPv6Address("[::]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_String_Decoding_Zero_Uncompressed

    Benchmark(
        "IPv6_String_Decoding_Zero_Uncompressed_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            let ip = IPv6Address("[0000:0000:0000:0000:0000:0000:0000:0000]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_String_Decoding_Localhost_Compressed

    Benchmark(
        "IPv6_String_Decoding_Localhost_Compressed_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let ip = IPv6Address("[::1]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_String_Decoding_2_Groups_Compressed_In_The_Middle_No_Brackets

    Benchmark(
        "IPv6_String_Decoding_2_Groups_Compressed_In_The_Middle_No_Brackets_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            let ip = IPv6Address("2001:0db8:85a3::8a2e:0370:7334").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_String_Decoding_2_Groups_Compressed_In_The_Middle_No_Brackets_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("2001:0db8:85a3::8a2e:0370:7334").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_String_Decoding_2_Groups_Compressed_At_The_End

    Benchmark(
        "IPv6_String_Decoding_2_Groups_Compressed_At_The_End_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            let ip = IPv6Address("[2001:0db8:85a3:8a2e:0370:7334::]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: - IPv6_String_Decoding_2_Groups_Compressed_At_The_Begining

    Benchmark(
        "IPv6_String_Decoding_2_Groups_Compressed_At_The_Begining_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            let ip = IPv6Address("[::2001:0db8:85a3:8a2e:0370:7334]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    // MARK: IPv6_String_Decoding_2_Groups_Compressed_In_The_Middle_No_Brackets_inet_pton

    #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android)
    Benchmark(
        "IPv6_String_Decoding_2_Groups_Compressed_In_The_Middle_No_Brackets_inet_pton_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            var ipv6SocketAddress = sockaddr_in6()
            _ = "2001:0db8:85a3::8a2e:0370:7334".withCString { p in
                inet_pton(AF_INET6, p, &ipv6SocketAddress.sin6_addr)
            }
            blackHole(ipv6SocketAddress)
        }
    }

    Benchmark(
        "IPv6_String_Decoding_2_Groups_Compressed_In_The_Middle_No_Brackets_inet_pton_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var ipv6SocketAddress = sockaddr_in6()
        _ = "2001:0db8:85a3::8a2e:0370:7334".withCString { p in
            inet_pton(AF_INET6, p, &ipv6SocketAddress.sin6_addr)
        }
        blackHole(ipv6SocketAddress)
    }
    #endif
}
