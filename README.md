# 🚧 Under Heavy Construction 🚧

Definetely not yet ready for production use.

I'll tag/release an alpha/beta as soon as things are more reliable and there are adequete tests.

If you're curious, use the GitHub "Watch" feature (near the star button) and choose "Custom" -> "Releases" to be notified of releases when they happen.

#### Requires Swift 6.2. Also requires macOS 26 if used on macos.

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

## Usage

Initialize a `DNSClient`, then use the `query` methods:

```swift
import DNSClient
import DNSModels

/// Create a `DNSClient`
let client = DNSClient(
    serverAddress: .domain(name: "8.8.4.4", port: 53),
    logger: Logger(label: "DNSTests")
)

/// Send the query
let response = try await client.queryA(
    message: .forQuery(name: "example.com"),
    options: .edns
) /// type of value is `Message`

/// Read the answers
for answer in response.answers {
    let a = try answer.rdata /// type of value is `A`
    let ipv4 = a.value /// type of value is `IPv4Address`
    print("Got ipv4 \(ipv4) for domain \(response.queries.first?.name.description ?? "n/a")")
}
```

## Checklist

- [x] DNS Parsing
  - [x] IDNA support for non-ASCII domain names.
- [x] DNS client
  - [x] DNS over UDP
  - [ ] DNS over TCP
  - [ ] DoT (DNS Over TLS)
  - [ ] DoH (DNS Over HTTPS)
  - [ ] DoQ (DNS Over Quic)
- [ ] DNS resolver (DNS client but with caching etc...)
- [ ] DNS server
- [ ] DNSSEC

## Credits

- https://github.com/apple/swift-nio
  - The networking library used to implement this library.
- https://github.com/hickory-dns/hickory-dns
  - Some data type / parsing implementations were heavily inspired by hickory-dns.
- https://github.com/valkey-io/valkey-swift
  - Helped a lot in putting an initial version of the connection handling together.
