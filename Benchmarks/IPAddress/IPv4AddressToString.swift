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
#error("The IPv4AddressToString benchmarks module was unable to identify your C library.")
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

    var ipv4MixedInetNtop = ipv4Mixed.address

    /// inet_ntop expects the reverse byte-order but we don't account for that here so
    /// that we're not blaming byte-order mismatches on inet_ntop.

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
                &ipv4MixedInetNtop,
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
        var addressBytes: [Int8] = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]
        let description = addressBytes.withUnsafeMutableBufferPointer {
            (addressBytesPtr: inout UnsafeMutableBufferPointer<Int8>) -> String in
            inet_ntop(
                AF_INET,
                &ipv4MixedInetNtop,
                addressBytesPtr.baseAddress!,
                15
            )
            return addressBytesPtr.baseAddress!.withMemoryRebound(
                to: UInt8.self,
                capacity: 15
            ) {
                String(cString: $0)
            }
        }
        blackHole(description)
    }
}
