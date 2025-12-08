import Atomics
import DNSClient
import DNSModels
import Logging
import NIOConcurrencyHelpers
import NIOPosix
import Testing

import struct NIOCore.ByteBuffer

extension SerializationNamespace {
    struct DNSResolverTests {}
}

extension SerializationNamespace.DNSResolverTests {
    /// Currently the upstream resolver responds with answers that start with a CNAME and the rest are the A records.
    @available(swiftDNSApplePlatforms 10.15, *)
    @Test(.packetCaptureMarker, arguments: Utils.makeTestingDNSClients())
    func `resolve A record where the original record is a CNAME`(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let resolver = DNSResolver(client: client)
            let factory = try MessageFactory<A>.forQuery(domainName: "www.example.com.")
            let message = factory.__testing_copyMessage()
            let response = try await resolver.resolveA(
                message: factory
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            /// At least one CNAME and one A records are expected
            #expect(response.header.answerCount >= 2)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("www.example.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .A)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count > 0)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                /// These are the A records corresponding to the CNAME
                /// So they must not have the same domain name as what we queried
                response.answers.allSatisfy { $0.nameLabels != domainName },
                "\(response.answers)"
            )
            #expect(
                response.message.answers.contains { $0.nameLabels != domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .A }, "\(response.answers).")
            #expect(
                response.message.answers.contains { $0.recordType == .CNAME },
                "\(response.answers)."
            )
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let ipv4s = response.answers.map(\.rdata.value)
            #expect(ipv4s.allSatisfy { $0.address != 0 })

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            #expect(edns.flags.dnssecOk == false)
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }
}
