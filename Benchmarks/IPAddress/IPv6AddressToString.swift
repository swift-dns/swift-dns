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

let ipv6AddressToStringBenchmarks: @Sendable () -> Void = {
    // MARK: - IPv6_String_Encoding_Zero

    let ipv6Zero: IPv6Address = 0
    Benchmark(
        "IPv6_String_Encoding_Zero_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<20_000_000 {
            let description = ipv6Zero.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_String_Encoding_Localhost

    let ipv6Localhost: IPv6Address = 0x0000_0000_0000_0000_0000_0000_0000_0001
    Benchmark(
        "IPv6_String_Encoding_Localhost_10M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000_000 {
            let description = ipv6Localhost.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_String_Encoding_Max

    let ipv6Max: IPv6Address = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
    Benchmark(
        "IPv6_String_Encoding_Max_4M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<4_000_000 {
            let description = ipv6Max.description
            blackHole(description)
        }
    }

    // MARK: - IPv6_String_Encoding_Mixed

    let ipv6Mixed: IPv6Address = 0x85a0_850a_8500_0000_0000_00af_805a_085a
    Benchmark(
        "IPv6_String_Encoding_Mixed_4M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<4_000_000 {
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

    // MARK: IPv6_String_Encoding_Mixed_inet_ntop

    #if canImport(Darwin) || canImport(Glibc) || canImport(Musl) || canImport(Android)
    var ipv6MixedInetNtop = ipv6Mixed.address

    /// inet_ntop expects the reverse byte-order but we don't account for that here so
    /// that we're not blaming byte-order mismatches on inet_ntop.

    Benchmark(
        "IPv6_String_Encoding_Mixed_inet_ntop_4M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 5,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<4_000_000 {
            let ptr = UnsafeMutableRawPointer.allocate(byteCount: 64, alignment: 1).bindMemory(
                to: Int8.self,
                capacity: 64
            )
            inet_ntop(
                AF_INET6,
                &ipv6MixedInetNtop,
                ptr,
                64
            )
            let description = String(cString: ptr)
            ptr.deinitialize(count: 64).deallocate()
            blackHole(description)
        }
    }

    Benchmark(
        "IPv6_String_Encoding_Mixed_inet_ntop_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        var addressBytes: [Int8] = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]
        let description = addressBytes.withUnsafeMutableBufferPointer {
            (addressBytesPtr: inout UnsafeMutableBufferPointer<Int8>) -> String in
            inet_ntop(
                AF_INET6,
                &ipv6MixedInetNtop,
                addressBytesPtr.baseAddress!,
                50
            )
            return addressBytesPtr.baseAddress!.withMemoryRebound(
                to: UInt8.self,
                capacity: 50
            ) {
                String(cString: $0)
            }
        }
        blackHole(description)
    }
    #endif
}
