import DNSClient
import Logging
import NIOCore
import NIOEmbedded
import Testing

struct DNSResolverTests {
    @available(swiftDNSApplePlatforms 10.15, *)
    @Test(arguments: TestingDNSConnectionFactory.makeConnFactoryAndDNSResolvers())
    func `resolve A record where the original record is a CNAME`(
        connFactory: TestingDNSConnectionFactory,
        resolver: DNSResolver
    ) async throws {
        try await withRunningDNSResolver(resolver) { resolver in
            let domainName = try! DomainName("www.example.com.")
            let isOverUDP = await resolver.client.isOverUDP

            let messageFactory: MessageFactory<A> = .forQuery(domainName: domainName)

            let expectation = await connFactory.registerExpectationForNewChannel(udp: isOverUDP)
            async let asyncResponse = try await resolver.resolveA(message: messageFactory.copy())

            await expectation.waitFulfillment()

            /// With TCP, technically we might have multiple channels.
            /// For now we just get the first one and it's working since PostgresNIO's conn-pool
            /// implementation which we use, just uses the first conn for the first query.
            let channel = try #require(await connFactory.getFirstChannel(udp: isOverUDP))
            let channelCount = await connFactory.udpChannels.count
            #expect(channelCount <= 1)

            let outboundMessage = try await channel.waitForOutboundMessage()
            #expect(outboundMessage.queries.first?.domainName == domainName)

            var expectedQueryMessage = messageFactory.copy().takeMessage()
            expectedQueryMessage.header.id = outboundMessage.header.id
            #expect("\(outboundMessage)" == "\(expectedQueryMessage)")

            let expectedResponse = Message(
                header: Header(
                    id: outboundMessage.header.id,
                    messageType: .Response,
                    opCode: .Query,
                    authoritative: false,
                    truncation: false,
                    recursionDesired: true,
                    recursionAvailable: true,
                    authenticData: false,
                    checkingDisabled: false,
                    responseCode: .NoError,
                    queryCount: 1,
                    answerCount: 4,
                    nameServerCount: 0,
                    additionalCount: 1
                ),
                queries: [
                    Query(
                        domainName: try! DomainName("www.example.com."),
                        queryType: .A,
                        queryClass: .IN
                    )
                ],
                answers: [
                    Record(
                        nameLabels: try! DomainName("www.example.com."),
                        dnsClass: .IN,
                        ttl: 201,
                        rdata: .CNAME(
                            CNAME(domainName: try! DomainName("www.example.com-v4.edgesuite.net."))
                        )
                    ),
                    Record(
                        nameLabels: try! DomainName("www.example.com-v4.edgesuite.net."),
                        dnsClass: .IN,
                        ttl: 21391,
                        rdata: .CNAME(CNAME(domainName: try! DomainName("a1422.dscr.akamai.net.")))
                    ),
                    Record(
                        nameLabels: try! DomainName("a1422.dscr.akamai.net."),
                        dnsClass: .IN,
                        ttl: 20,
                        rdata: .A(A(value: IPv4Address(185, 200, 232, 40)))
                    ),
                    Record(
                        nameLabels: try! DomainName("a1422.dscr.akamai.net."),
                        dnsClass: .IN,
                        ttl: 20,
                        rdata: .A(A(value: IPv4Address(185, 200, 232, 48)))
                    ),
                ],
                nameServers: [],
                additionals: [],
                signature: [],
                edns: EDNS(
                    rcodeHigh: 0,
                    version: 0,
                    flags: EDNS.Flags(dnssecOk: false, z: 0),
                    maxPayload: 512,
                    options: OPT(options: [])
                )
            )

            try await channel.writeInboundMessage(expectedResponse)

            let response = try await asyncResponse
            /// FIXME: use equatable instead of string comparison
            #expect("\(response.message)" == "\(expectedResponse)")
        }
    }

    @available(swiftDNSApplePlatforms 10.15, *)
    @Test(arguments: TestingDNSConnectionFactory.makeConnFactoryAndDNSResolvers())
    func `resolve AAAA record where the original record is a CNAME`(
        connFactory: TestingDNSConnectionFactory,
        resolver: DNSResolver
    ) async throws {
        try await withRunningDNSResolver(resolver) { resolver in
            let domainName = try! DomainName("www.example.com.")
            let isOverUDP = await resolver.client.isOverUDP

            let messageFactory: MessageFactory<AAAA> = .forQuery(domainName: domainName)

            let expectation = await connFactory.registerExpectationForNewChannel(udp: isOverUDP)
            async let asyncResponse = try await resolver.resolveAAAA(message: messageFactory.copy())

            await expectation.waitFulfillment()

            /// With TCP, technically we might have multiple channels.
            /// For now we just get the first one and it's working since PostgresNIO's conn-pool
            /// implementation which we use, just uses the first conn for the first query.
            let channel = try #require(await connFactory.getFirstChannel(udp: isOverUDP))
            let channelCount = await connFactory.udpChannels.count
            #expect(channelCount <= 1)

            let outboundMessage = try await channel.waitForOutboundMessage()
            #expect(outboundMessage.queries.first?.domainName == domainName)

            var expectedQueryMessage = messageFactory.copy().takeMessage()
            expectedQueryMessage.header.id = outboundMessage.header.id
            #expect("\(outboundMessage)" == "\(expectedQueryMessage)")

            let expectedResponse = Message(
                header: Header(
                    id: outboundMessage.header.id,
                    messageType: .Response,
                    opCode: .Query,
                    authoritative: false,
                    truncation: false,
                    recursionDesired: true,
                    recursionAvailable: true,
                    authenticData: true,
                    checkingDisabled: false,
                    responseCode: .NoError,
                    queryCount: 1,
                    answerCount: 3,
                    nameServerCount: 0,
                    additionalCount: 1
                ),
                queries: TinyFastSequence([
                    Query(
                        domainName: try! DomainName("www.example.com."),
                        queryType: .AAAA,
                        queryClass: .IN
                    )
                ]),
                answers: TinyFastSequence([
                    Record(
                        nameLabels: try! DomainName("www.example.com."),
                        dnsClass: .IN,
                        ttl: 201,
                        rdata: RData.CNAME(
                            CNAME(
                                domainName: try! DomainName("www.example.com.cdn.cloudflare.net.")
                            )
                        )
                    ),
                    Record(
                        nameLabels: try! DomainName("www.example.com.cdn.cloudflare.net."),
                        dnsClass: .IN,
                        ttl: 97,
                        rdata: RData.AAAA(AAAA(value: IPv6Address("[2606:4700:10::ac42:9071]")!))
                    ),
                    Record(
                        nameLabels: try! DomainName("www.example.com.cdn.cloudflare.net."),
                        dnsClass: .IN,
                        ttl: 97,
                        rdata: RData.AAAA(AAAA(value: IPv6Address("[2606:4700:10::6814:22dc]")!))
                    ),
                ]),
                nameServers: [],
                additionals: [],
                signature: [],
                edns: EDNS(
                    rcodeHigh: 0,
                    version: 0,
                    flags: EDNS.Flags(dnssecOk: false, z: 0),
                    maxPayload: 512,
                    options: OPT(options: [])
                )
            )

            try await channel.writeInboundMessage(expectedResponse)

            let response = try await asyncResponse
            /// FIXME: use equatable instead of string comparison
            #expect("\(response.message)" == "\(expectedResponse)")
        }
    }
}
