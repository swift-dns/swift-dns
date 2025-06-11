# 🚧 Under Heavy Construction 🚧

Definetely not yet ready for production use.   

I'll tag/release an alpha/beta as soon as things are more reliable and there are adequete tests.   

If you're curious, use the GitHub "Watch" feature (near the star button) and choose "Custom" -> "Releases" to be notified of releases when they happen.   

#### Requires Swift 6.2. Also requires macOS 26 if used on macos.

# swift-dns

A Swift DNS library built on top of SwiftNIO; aiming to provide DNS client, resolver and server implementations.

## Usage

I'll add convenience methods sometime soon.
For now use the `DNSClient` to send a fully-customizable DNS `Message`:

```swift
import DNSClient
import DNSModels

/// Create a `DNSClient`
let client = DNSClient(
    connectionTarget: .domain(name: "8.8.4.4", port: 53),
    logger: Logger(label: "DNSTests")
)

/// Create a `Query` object
let query = Query(
    name: try Name(string: "example.com"),
    queryType: .A,
    queryClass: .IN
)

/// Construct the full `Message` object
let message = Message(
    header: Header(
        id: .random(in: .min ... .max),
        messageType: .Query,
        opCode: .Query,
        authoritative: false,
        truncation: false,
        recursionDesired: true,
        recursionAvailable: false,
        authenticData: true,
        checkingDisabled: false,
        responseCode: .NoError,
        queryCount: 1,
        answerCount: 0,
        nameServerCount: 0,
        additionalCount: 0
    ),
    queries: [query],
    answers: [],
    nameServers: [],
    additionals: [],
    signature: [],
    edns: nil
)

/// Send the query
/// The return type is the same as the query type (`Message`)
/// But the returned `Message` can have completely different contents
let response: Message = try await client.query(message: message)

/// Read the answers
for answer in response.answers {
    switch answer.rdata {
    case .A(let a):
        let ipv4 = a.value
        print("Got:", ipv4)
    default:
        print("Impossible")
    }
}
```

## Checklist

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
