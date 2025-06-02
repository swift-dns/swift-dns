import DNSClient
import DNSModels
import Testing

@Suite
struct DNSTests {
    @Test func queryA() async throws {
        let query = Query(
            name: try Name(string: "example.com"),
            queryType: .A,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 12847,
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

        let response = try await Client.query(message: message)

        #expect(response.header.id == 12847)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount > 0)
        /// response.header.nameServerCount is whatever
        #expect(response.header.additionalCount > 0)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == false)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries[0].name.isFQDN == false)
        let name = try Name(string: "example.com")
        #expect(response.queries[0].name.data == name.data)
        #expect(response.queries[0].queryType == .A)
        #expect(response.queries[0].queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 6)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN == false },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .A }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let ipv4s = response.answers.compactMap {
            switch $0.rdata {
            case .A(let a):
                return a.value
            default:
                Issue.record("rdata was not of type A: \($0.rdata)")
                return nil
            }
        }
        #expect(
            ipv4s.allSatisfy {
                /// Weird way to check if the IPv4 is not just some zero bytes
                var sum: UInt32 = 0
                for idx in $0.bytes.indices {
                    sum += UInt32($0.bytes[idx])
                }
                return sum != 0
            }
        )

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        #expect(edns.options.options.count > 0)
    }
}
