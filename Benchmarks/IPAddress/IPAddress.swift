import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    // MARK: - IPv4_Zero_String_Parsing

    Benchmark(
        "IPv4_Zero_String_Parsing_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            let ip = IPv4Address("0.0.0.0").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_Zero_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv4Address("0.0.0.0").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv4_Localhost_String_Parsing

    Benchmark(
        "IPv4_Localhost_String_Parsing_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            let ip = IPv4Address("127.0.0.1").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_Localhost_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv4Address("127.0.0.1").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv4_Local_Broadcast_String_Parsing

    Benchmark(
        "IPv4_Local_Broadcast_String_Parsing_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            let ip = IPv4Address("255.255.255.255").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv4_Local_Broadcast_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv4Address("255.255.255.255").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_Uncompressed_String_Parsing

    Benchmark(
        "IPv6_Uncompressed_String_Parsing_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let ip = IPv6Address("[2001:0db8:85a3:f109:197a:8a2e:0370:7334]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_Uncompressed_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("[2001:0db8:85a3:f109:197a:8a2e:0370:7334]").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_Uncompressed_Full_Non_ASCII_String_Parsing

    Benchmark(
        "IPv6_Uncompressed_Full_Non_ASCII_String_Parsing_10K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<10_000 {
            let ip = IPv6Address("﹇₂₀₀₁︓₀ⒹⒷ₈︓₈₅Ⓐ₃︓Ⓕ₁₀₉︓₁₉₇Ⓐ︓₈Ⓐ₂Ⓔ︓₀₃₇₀︓₇₃₃₄﹈").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_Uncompressed_Full_Non_ASCII_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("﹇₂₀₀₁︓₀ⒹⒷ₈︓₈₅Ⓐ₃︓Ⓕ₁₀₉︓₁₉₇Ⓐ︓₈Ⓐ₂Ⓔ︓₀₃₇₀︓₇₃₃₄﹈").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_Zero_Compressed_String_Parsing

    Benchmark(
        "IPv6_Zero_Compressed_String_Parsing_2M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<2_000_000 {
            let ip = IPv6Address("[::]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_Zero_Compressed_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("[::]").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_Zero_Uncompressed_String_Parsing

    Benchmark(
        "IPv6_Zero_Uncompressed_String_Parsing_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let ip = IPv6Address("[0000:0000:0000:0000:0000:0000:0000:0000]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_Zero_Uncompressed_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("[0000:0000:0000:0000:0000:0000:0000:0000]").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_Localhost_Compressed_String_Parsing

    Benchmark(
        "IPv6_Localhost_Compressed_String_Parsing_1M",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<1_000_000 {
            let ip = IPv6Address("[::1]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_Localhost_Compressed_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("[::1]").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_2_Groups_Compressed_In_The_Middle_String_Parsing

    Benchmark(
        "IPv6_2_Groups_Compressed_In_The_Middle_String_Parsing_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let ip = IPv6Address("[2001:0db8:85a3::8a2e:0370:7334]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_2_Groups_Compressed_In_The_Middle_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("[2001:0db8:85a3::8a2e:0370:7334]").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_2_Groups_Compressed_At_The_End_String_Parsing

    Benchmark(
        "IPv6_2_Groups_Compressed_At_The_End_String_Parsing_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let ip = IPv6Address("[2001:0db8:85a3:8a2e:0370:7334::]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_2_Groups_Compressed_At_The_End_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("[2001:0db8:85a3:8a2e:0370:7334::]").unsafelyUnwrapped
        blackHole(ip)
    }

    // MARK: - IPv6_2_Groups_Compressed_At_The_Begining_String_Parsing

    Benchmark(
        "IPv6_2_Groups_Compressed_At_The_Begining_String_Parsing_200K",
        configuration: .init(
            metrics: [.cpuUser],
            warmupIterations: 10,
            maxIterations: 1000
        )
    ) { benchmark in
        for _ in 0..<200_000 {
            let ip = IPv6Address("[::2001:0db8:85a3:8a2e:0370:7334]").unsafelyUnwrapped
            blackHole(ip)
        }
    }

    Benchmark(
        "IPv6_2_Groups_Compressed_At_The_Begining_String_Parsing_Malloc",
        configuration: .init(
            metrics: [.mallocCountTotal],
            warmupIterations: 1,
            maxIterations: 10
        )
    ) { benchmark in
        let ip = IPv6Address("[::2001:0db8:85a3:8a2e:0370:7334]").unsafelyUnwrapped
        blackHole(ip)
    }
}
