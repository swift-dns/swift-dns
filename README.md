<p>
    <a href="https://github.com/MahdiBM/swift-dns/actions/workflows/unit-tests.yml">
        <img
            src="https://img.shields.io/github/actions/workflow/status/MahdiBM/swift-dns/unit-tests.yml?event=push&style=plastic&logo=github&label=unit-tests&logoColor=%23ccc"
            alt="Unit Tests CI"
        >
    </a>
    <a href="https://github.com/MahdiBM/swift-dns/actions/workflows/integration-tests.yml">
        <img
            src="https://img.shields.io/github/actions/workflow/status/MahdiBM/swift-dns/integration-tests.yml?event=push&style=plastic&logo=github&label=integration-tests&logoColor=%23ccc"
            alt="Integration Tests CI"
        >
    </a>
    <a href="https://github.com/MahdiBM/swift-dns/actions/workflows/benchmarks.yml">
        <img
            src="https://img.shields.io/github/actions/workflow/status/MahdiBM/swift-dns/benchmarks.yml?event=push&style=plastic&logo=github&label=benchmarks&logoColor=%23ccc"
            alt="Benchamrks CI"
        >
    </a>
    <a href="https://swift.org">
        <img
            src="https://design.vapor.codes/images/swift62up.svg"
            alt="Swift 6.2+"
        >
    </a>
</p>

# swift-dns

A high-performance Swift DNS library built on top of SwiftNIO; aiming to provide DNS client, resolver and server implementations.

## Usage

Initialize a `DNSResolver`, then use the `query` methods:

```swift
import DNSClient
import DNSModels

/// Create a `DNSResolver`
let resolver = try DNSResolver(
    transport: .default(
        serverAddress: .domain(
            /// Connect to Cloudflare's DNS primary server @ 1.1.1.1
            domainName: DomainName(ipv4: IPv4Address(1, 1, 1, 1)),
            port: 53
        )
    )
)

try await withThrowingTaskGroup(of: Void.self) { taskGroup in
    /// Use `addImmediateTask` instead of `addTask` on macOS 26 or Linux.
    taskGroup.addTask {
        try await resolver.run()/// !important
    }

    /// You can use the resolver while the `resolver.run()` method is not cancelled.

    /// Send the query
    /// `response` will be of type `Message`
    let response = try await resolver.resolveA(
        message: .forQuery(domainName: "mahdibm.com")
    )

    /// Read the answers
    for answer in response.answers {
        /// `a` will be of type `A`
        let a = answer.rdata
        /// `ipv4` will be of type `IPv4Address`
        let ipv4 = a.value
        print(
            "Got ipv4 \(ipv4) for domain \(response.queries.first?.domainName.description ?? "n/a")"
        )
    }

    /// To shutdown the resolver, cancel its run method, by cancelling the taskGroup.
    taskGroup.cancelAll()
}
```

You can use different transports if you so desire.
The `default` transport is `preferUDPOrUseTCP` similar to other DNS resolvers and resolvers.
Currently a TCP-only transport is also supported:

```swift
/// Create a `DNSResolver` with the TCP transport
let resolver = try DNSResolver(
    transport: .tcp(
        serverAddress: .domain(
            domainName: DomainName(ipv4: IPv4Address(1, 1, 1, 1)),
            port: 53
        )
    )
)
```

## Operators

I'm experimenting with using operators that do checks in debug builds, but are unchecked in optimized builds.

These operators always have 2 of the last character of the normal operator, and they should in theory always result in the same value as their stdlib version.

Some examples of these operators are:

- `&+` -> `&++`
- `&+=` -> `&+==`
- `&>>` -> `&>>>`

## Checklist

- [x] DNS Parsing
  - [x] IDNA support for non-ASCII domain names.
- [x] DNS client
  - [x] DNS over UDP
  - [x] DNS over TCP
  - [ ] DoT (DNS Over TLS)
  - [ ] DoH (DNS Over HTTPS)
  - [ ] DoQ (DNS Over Quic)
  - [ ] MDNS
- [x] DNS resolver (DNS client but with following CNAMEs, doing caching etc...)
  - Implementation is in progress
- [ ] DNS server
- [ ] DNSSEC

## Credits

- https://github.com/apple/swift-nio
  - The networking library used to implement this library.
- https://github.com/hickory-dns/hickory-dns
  - Some data type / parsing implementations were heavily inspired by hickory-dns.
- https://github.com/valkey-io/valkey-swift
  - Helped a lot in putting together an initial version of the connection handling.
