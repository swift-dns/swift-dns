## swift-dns

### Usage

Use `Message` to send a fully-customizable DNS request:

```swift
import DNSClient
import DNSModels

/// Create a `Client`
let client = Client(
    connectionTarget: .domain(name: "8.8.4.4", port: 53),
    eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
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
        additionalCount: 1
    ),
    queries: [query],
    answers: [],
    nameServers: [],
    additionals: [],
    signature: [],
    edns: EDNS(
        rcodeHigh: 0,
        version: 0,
        flags: .init(dnssecOk: false, z: 0),
        maxPayload: 4096,
        options: OPT(options: [])
    )
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

### Credits

- https://github.com/hickory-dns/hickory-dns
  - Some data type implementations were inspired by hickory-dns.
