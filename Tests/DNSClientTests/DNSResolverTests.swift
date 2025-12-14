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
        resolver: _RecursiveDNSResolver
    ) async throws {
        try await withRunningDNSResolver(resolver) { resolver in
            let domainName = try! DomainName("www.example.com.")
            let isOverUDP = resolver.client.isOverUDP

            let messageFactory: MessageFactory<A> = .forQuery(domainName: domainName)

            let expectation = await connFactory.registerExpectationForNewChannel(udp: isOverUDP)
            async let asyncResponse = try await resolver.resolveA(message: messageFactory.copy())

            try await expectation.waitFulfillment()

            let outboundMessage = try await connFactory.waitForOutboundMessage(udp: isOverUDP)
            #expect(outboundMessage.queries.first?.domainName == domainName)
            let messageID = outboundMessage.header.id
            /// The message ID should not be 0 because the channel handler reassigns it
            #expect(messageID != 0)

            var expectedQueryMessage = messageFactory.copy().takeMessage()
            expectedQueryMessage.header.id = messageID
            #expect("\(outboundMessage)" == "\(expectedQueryMessage)")

            let expectedResponse = Message(
                header: Header(
                    id: messageID,
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

            try await connFactory.writeInboundMessage(
                udp: isOverUDP,
                message: expectedResponse
            )

            let response = try await asyncResponse
            /// FIXME: use equatable instead of string comparison
            #expect("\(response.message)" == "\(expectedResponse)")
        }
    }

    @available(swiftDNSApplePlatforms 10.15, *)
    @Test(arguments: TestingDNSConnectionFactory.makeConnFactoryAndDNSResolvers())
    func `resolve AAAA record where the original record is a CNAME`(
        connFactory: TestingDNSConnectionFactory,
        resolver: _RecursiveDNSResolver
    ) async throws {
        try await withRunningDNSResolver(resolver) { resolver in
            let domainName = try! DomainName("www.example.com.")
            let isOverUDP = resolver.client.isOverUDP

            let messageFactory: MessageFactory<AAAA> = .forQuery(domainName: domainName)

            let expectation = await connFactory.registerExpectationForNewChannel(udp: isOverUDP)
            async let asyncResponse = try await resolver.resolveAAAA(message: messageFactory.copy())

            try await expectation.waitFulfillment()

            let outboundMessage = try await connFactory.waitForOutboundMessage(udp: isOverUDP)
            #expect(outboundMessage.queries.first?.domainName == domainName)
            let messageID = outboundMessage.header.id
            /// The message ID should not be 0 because the channel handler reassigns it
            #expect(messageID != 0)

            var expectedQueryMessage = messageFactory.copy().takeMessage()
            expectedQueryMessage.header.id = messageID
            #expect("\(outboundMessage)" == "\(expectedQueryMessage)")

            let expectedResponse = Message(
                header: Header(
                    id: messageID,
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

            try await connFactory.writeInboundMessage(
                udp: isOverUDP,
                message: expectedResponse
            )

            let response = try await asyncResponse
            /// FIXME: use equatable instead of string comparison
            #expect("\(response.message)" == "\(expectedResponse)")
        }
    }

    /// I haven't actually caught this case in practice, but it sounds plausible.
    @available(swiftDNSApplePlatforms 10.15, *)
    @Test(arguments: TestingDNSConnectionFactory.makeConnFactoryAndDNSResolvers())
    func `resolve AAAA record where there are multiple CNAME record layers`(
        connFactory: TestingDNSConnectionFactory,
        resolver: _RecursiveDNSResolver
    ) async throws {
        try await withRunningDNSResolver(resolver) { resolver in
            let domainName = try! DomainName("www.example.com.")
            let firstCNAME = try! DomainName("www.example.com.cdn.cloudflare.net.")
            let secondCNAME = try! DomainName("random.name.www.example.com.cdn.cloudflare.net.")
            let isOverUDP = resolver.client.isOverUDP

            let messageFactory: MessageFactory<AAAA> = .forQuery(domainName: domainName)

            let expectation = await connFactory.registerExpectationForNewChannel(udp: isOverUDP)
            async let asyncResponse = try await resolver.resolveAAAA(message: messageFactory.copy())

            try await expectation.waitFulfillment()

            do {
                let outboundMessage = try await connFactory.waitForOutboundMessage(udp: isOverUDP)
                #expect(outboundMessage.queries.first?.domainName == domainName)
                let messageID = outboundMessage.header.id
                /// The message ID should not be 0 because the channel handler reassigns it
                #expect(messageID != 0)

                var expectedQueryMessage = messageFactory.copy().takeMessage()
                expectedQueryMessage.header.id = messageID
                #expect("\(outboundMessage)" == "\(expectedQueryMessage)")

                let expectedResponse = Message(
                    header: Header(
                        id: messageID,
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
                        answerCount: 1,
                        nameServerCount: 0,
                        additionalCount: 1
                    ),
                    queries: TinyFastSequence([
                        Query(
                            domainName: domainName,
                            queryType: .AAAA,
                            queryClass: .IN
                        )
                    ]),
                    answers: TinyFastSequence([
                        Record(
                            nameLabels: domainName,
                            dnsClass: .IN,
                            ttl: 201,
                            rdata: RData.CNAME(
                                CNAME(domainName: firstCNAME)
                            )
                        )
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

                try await connFactory.writeInboundMessage(
                    udp: isOverUDP,
                    message: expectedResponse
                )
            }

            do {
                let messageFactory: MessageFactory<AAAA> = .forQuery(domainName: firstCNAME)
                let outboundMessage = try await connFactory.waitForOutboundMessage(udp: isOverUDP)
                #expect(outboundMessage.queries.first?.domainName == firstCNAME)
                let messageID = outboundMessage.header.id
                /// The message ID should not be 0 because the channel handler reassigns it
                #expect(messageID != 0)

                var expectedQueryMessage = messageFactory.copy().takeMessage()
                expectedQueryMessage.header.id = messageID
                #expect("\(outboundMessage)" == "\(expectedQueryMessage)")

                let expectedResponse = Message(
                    header: Header(
                        id: messageID,
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
                        answerCount: 1,
                        nameServerCount: 0,
                        additionalCount: 1
                    ),
                    queries: TinyFastSequence([
                        Query(
                            domainName: firstCNAME,
                            queryType: .AAAA,
                            queryClass: .IN
                        )
                    ]),
                    answers: TinyFastSequence([
                        Record(
                            nameLabels: firstCNAME,
                            dnsClass: .IN,
                            ttl: 201,
                            rdata: RData.CNAME(
                                CNAME(domainName: secondCNAME)
                            )
                        )
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

                try await connFactory.writeInboundMessage(
                    udp: isOverUDP,
                    message: expectedResponse
                )
            }

            do {
                let messageFactory: MessageFactory<AAAA> = .forQuery(domainName: secondCNAME)
                let outboundMessage = try await connFactory.waitForOutboundMessage(udp: isOverUDP)
                #expect(outboundMessage.queries.first?.domainName == secondCNAME)
                let messageID = outboundMessage.header.id
                /// The message ID should not be 0 because the channel handler reassigns it
                #expect(messageID != 0)

                var expectedQueryMessage = messageFactory.copy().takeMessage()
                expectedQueryMessage.header.id = messageID
                #expect("\(outboundMessage)" == "\(expectedQueryMessage)")

                let expectedResponse = Message(
                    header: Header(
                        id: messageID,
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
                        answerCount: 2,
                        nameServerCount: 0,
                        additionalCount: 1
                    ),
                    queries: TinyFastSequence([
                        Query(
                            domainName: secondCNAME,
                            queryType: .AAAA,
                            queryClass: .IN
                        )
                    ]),
                    answers: TinyFastSequence([
                        Record(
                            nameLabels: secondCNAME,
                            dnsClass: .IN,
                            ttl: 97,
                            rdata: RData.AAAA(
                                AAAA(value: IPv6Address("[2606:4700:10::ac42:9071]")!)
                            )
                        ),
                        Record(
                            nameLabels: secondCNAME,
                            dnsClass: .IN,
                            ttl: 97,
                            rdata: RData.AAAA(
                                AAAA(value: IPv6Address("[2606:4700:10::6814:22dc]")!)
                            )
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

                try await connFactory.writeInboundMessage(
                    udp: isOverUDP,
                    message: expectedResponse
                )

                var expectedFinalResponse = expectedResponse

                var cnameRecords: TinyFastSequence<Record> = [
                    Record(
                        nameLabels: domainName,
                        dnsClass: .IN,
                        ttl: 201,
                        rdata: RData.CNAME(
                            CNAME(domainName: firstCNAME)
                        )
                    ),
                    Record(
                        nameLabels: firstCNAME,
                        dnsClass: .IN,
                        ttl: 201,
                        rdata: RData.CNAME(
                            CNAME(domainName: secondCNAME)
                        )
                    ),
                ]
                cnameRecords.append(contentsOf: expectedResponse.answers)
                expectedFinalResponse.answers = cnameRecords
                expectedFinalResponse.header.answerCount += 2

                let response = try await asyncResponse
                /// FIXME: use equatable instead of string comparison
                #expect("\(response.message)" == "\(expectedFinalResponse)")
            }
        }
    }
}
