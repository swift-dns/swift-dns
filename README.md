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

A Swift DNS library built on top of SwiftNIO; aiming to provide DNS client, resolver and server implementations.

## Platform Requirements

* Requires Swift 6.2.
* On Apple platforms, requires macOS/iOS 26 etc... as well, _to use_.
* You can still depend on this library in packages supporting macOS 15 and lower.
  * But you'll need to guard your usage of this library with `@available` or `#available`.
  * Example: `@available(macOS 26, iOS 26, tvOS 26, watchOS 26, visionOS 26, *)`.

## Usage

Initialize a `DNSClient`, then use the `query` methods:

```swift
import DNSClient
import DNSModels

/// Create a `DNSClient`
let client = try DNSClient.defaultTransport(
    serverAddress: .domain(name: "1.1.1.1", port: 53)
)

try await withThrowingTaskGroup(of: Void.self) { taskGroup in
    taskGroup.addImmediateTask {
        await client.run()  /// !important
    }

    /// You can use the client while the `client.run()` method is not cancelled.

    /// Send the query
    /// `response` will be of type `Message`
    let response = try await client.queryA(
        message: .forQuery(name: "mahdibm.com")
    )

    /// Read the answers
    for answer in response.answers {
        /// `a` will be of type `A`
        let a = try answer.rdata
        /// `ipv4` will be of type `IPv4Address`
        let ipv4 = a.value
        print("Got ipv4 \(ipv4) for domain \(response.queries.first?.name.description ?? "n/a")")
    }

    /// To shutdown the client, cancel its run method, by cancelling the taskGroup.
    taskGroup.cancelAll()
}
```

You can use different transport if you so desire.
The default transport is `PreferUDPOrUseTCP` similar to other DNS client and resolvers.
Currently a TCP-only transport is also supported:

```swift
/// Create a `DNSClient` with TCP transport
let client = try DNSClient.tcpTransport(
    serverAddress: .domain(name: "1.1.1.1", port: 53)
)
```

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
- [ ] DNS resolver (DNS client but with caching etc...)
- [ ] DNS server
- [ ] DNSSEC

## Credits

- https://github.com/apple/swift-nio
  - The networking library used to implement this library.
- https://github.com/hickory-dns/hickory-dns
  - Some data type / parsing implementations were heavily inspired by hickory-dns.
- https://github.com/valkey-io/valkey-swift
  - Helped a lot in putting together an initial version of the connection handling.
