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

Initialize a `DNSClient`, then use the `query` methods:

```swift
import DNSClient
import DNSModels

/// Create a `DNSClient`
let client = try DNSClient(
    transport: .default(
        serverAddress: .domain(
            /// Connect to Cloudflare's DNS primary server @ 1.1.1.1
            name: DomainName(ipv4: IPv4Address(1, 1, 1, 1)),
            port: 53
        )
    )
)

/// Run the client in the background.
/// When you exit this function, the in-progress requests will be cancelled,
/// and the client will be shut down.
async let _ = try await client.run()

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
    print("Got", ipv4, "for domain", response.queries.first?.name ?? "n/a")
}
```

You can use different transports if you so desire.
The `default` transport is `preferUDPOrUseTCP` similar to other DNS clients and resolvers.
Currently a TCP-only transport is also supported:

```swift
/// Create a `DNSClient` with the TCP transport
let client = try DNSClient(
    transport: .tcp(
        serverAddress: .domain(
            name: DomainName(ipv4: IPv4Address(1, 1, 1, 1)),
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
