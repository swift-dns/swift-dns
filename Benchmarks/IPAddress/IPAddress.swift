import Benchmark
import DNSModels
import NIOCore

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)

    ipv4AddressFromStringBenchmarks()
    ipv4AddressToStringBenchmarks()

    ipv6AddressFromStringBenchmarks()
    ipv6AddressToStringBenchmarks()
}
