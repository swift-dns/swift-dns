import DNSClient
import Testing

@Suite
struct DNSCacheTests {
    @Test(
        arguments: [
            (checkingDisabled: true, ttl: 97, cnameTTL: 201),
            (checkingDisabled: false, ttl: 97, cnameTTL: 201),
            (checkingDisabled: true, ttl: 97, cnameTTL: 50),
            (checkingDisabled: false, ttl: 97, cnameTTL: 50),
        ]
    )
    func `cache message and retrieve it`(
        checkingDisabled: Bool,
        ttl: UInt32,
        cnameTTL: UInt32
    ) async throws {
        let cache = DNSCache(clock: .continuous)
        let message = self.makeMessage(
            checkingDisabled: checkingDisabled,
            ttl: ttl,
            cnameTTL: cnameTTL
        )

        let domainName = try #require(message.queries.first).domainName
        await cache.save(
            domainName: domainName,
            message: message
        )

        await self.expectRetrieve(
            from: cache,
            domainName: domainName,
            checkingDisabled: checkingDisabled,
            expect: .cachedMessage(id: message.header.id)
        )
    }

    @Test(
        arguments: [
            (checkingDisabled: true, timeTravelSeconds: 3),
            (checkingDisabled: true, timeTravelSeconds: 97),
            (checkingDisabled: false, timeTravelSeconds: 3),
            (checkingDisabled: false, timeTravelSeconds: 97),
        ],
    )
    func `cached message has updated TTLs upon retrieval`(
        checkingDisabled: Bool,
        timeTravelSeconds: UInt32
    ) async throws {
        let testClock = ManualClock()
        let cache = DNSCache(clock: testClock)
        let message = self.makeMessage(checkingDisabled: checkingDisabled, ttl: 100)

        let domainName = try #require(message.queries.first).domainName
        await cache.save(
            domainName: domainName,
            message: message
        )

        testClock.advance(by: .seconds(timeTravelSeconds))

        let _retrievedMessage = await self.expectRetrieve(
            from: cache,
            domainName: domainName,
            checkingDisabled: checkingDisabled,
            expect: .cachedMessage(id: message.header.id)
        )
        let retrievedMessage = try #require(_retrievedMessage)

        for (newAnswer, originalAnswer) in zip(retrievedMessage.answers, message.answers) {
            let expectedTTL = originalAnswer.ttl - timeTravelSeconds
            let expectedTTLRange = (expectedTTL - 1)...(expectedTTL + 1)
            #expect(expectedTTLRange.contains(newAnswer.ttl))
        }
    }

    @Test(arguments: [true, false])
    func `cached message expires`(checkingDisabled: Bool) async throws {
        let testClock = ManualClock()
        let cache = DNSCache(clock: testClock)
        let message = self.makeMessage(checkingDisabled: checkingDisabled)

        let domainName = try #require(message.queries.first).domainName
        await cache.save(
            domainName: domainName,
            message: message
        )

        let ttl = try #require(message.answers.min(by: { $0.ttl < $1.ttl })).ttl
        testClock.advance(by: .seconds(ttl + 1))

        for newCheckingDisabled in [true, false] {
            let expectationMode: ExpectationMode =
                (newCheckingDisabled == true || checkingDisabled == false)
                ? .staleCachedMessage(id: message.header.id)
                : .noCachedMessageExists
            await self.expectRetrieve(
                from: cache,
                domainName: domainName,
                checkingDisabled: newCheckingDisabled,
                expect: expectationMode
            )
        }
    }

    @Test(arguments: [true, false])
    func `cached message does not save because cached message with higher TTL exists`(
        checkingDisabled: Bool
    ) async throws {
        let cache = DNSCache(clock: .continuous)
        let message1 = self.makeMessage(
            checkingDisabled: checkingDisabled,
            ttl: 100
        )
        let message2 = self.makeMessage(
            checkingDisabled: checkingDisabled,
            ttl: 99
        )

        let domainName = try #require(message1.queries.first).domainName
        #expect(domainName == message2.queries.first?.domainName)

        for message in [message1, message2] {
            await cache.save(
                domainName: domainName,
                message: message
            )
        }

        await self.expectRetrieve(
            from: cache,
            domainName: domainName,
            checkingDisabled: checkingDisabled,
            expect: .cachedMessage(id: message1.header.id)
        )
    }

    @Test(arguments: [true, false])
    func `cached message does save because cached message is close to expiration now`(
        checkingDisabled: Bool
    ) async throws {
        let testClock = ManualClock()
        let cache = DNSCache(clock: testClock)
        let message1 = self.makeMessage(
            checkingDisabled: checkingDisabled,
            ttl: 100
        )
        let message2 = self.makeMessage(
            checkingDisabled: checkingDisabled,
            ttl: 99
        )

        let domainName = try #require(message1.queries.first).domainName
        #expect(domainName == message2.queries.first?.domainName)

        await cache.save(
            domainName: domainName,
            message: message1
        )

        testClock.advance(by: .seconds(2))
        await cache.save(
            domainName: domainName,
            message: message2
        )

        await self.expectRetrieve(
            from: cache,
            domainName: domainName,
            checkingDisabled: checkingDisabled,
            expect: .cachedMessage(id: message2.header.id)
        )
    }

    @Test func `retrieving message prefers to return message with checking enabled`() async throws {
        let cache = DNSCache(clock: .continuous)
        let messageWithCheckingDisabled = self.makeMessage(checkingDisabled: true)
        let messageWithCheckingEnabled = self.makeMessage(checkingDisabled: false)

        let domainName = try #require(messageWithCheckingDisabled.queries.first).domainName
        #expect(domainName == messageWithCheckingEnabled.queries.first?.domainName)

        for message in [messageWithCheckingDisabled, messageWithCheckingEnabled] {
            await cache.save(
                domainName: domainName,
                message: message
            )
        }

        do {
            await self.expectRetrieve(
                from: cache,
                domainName: domainName,
                checkingDisabled: true,
                /// We requested `checkingDisabled: true` but we should still get the message with checking enabled.
                expect: .cachedMessage(id: messageWithCheckingEnabled.header.id)
            )
        }

        do {
            await self.expectRetrieve(
                from: cache,
                domainName: domainName,
                checkingDisabled: false,
                expect: .cachedMessage(id: messageWithCheckingEnabled.header.id)
            )
        }
    }

    enum ExpectationMode {
        case cachedMessage(id: UInt16)
        case staleCachedMessage(id: UInt16)
        case noCachedMessageExists
    }

    @discardableResult
    func expectRetrieve<ClockType: Clock>(
        from cache: DNSCache<ClockType>,
        domainName: DomainName,
        checkingDisabled: Bool,
        expect expectationMode: ExpectationMode,
        sourceLocation: Testing.SourceLocation = #_sourceLocation
    ) async -> Message? {
        func retrieve(stale: Bool) async -> Message? {
            await cache.retrieve(
                domainName: domainName,
                checkingDisabled: checkingDisabled,
                useStaleCache: stale
            )
        }

        switch expectationMode {
        case .cachedMessage(let id):
            let possiblyStaleMessage = await retrieve(stale: true)
            #expect(possiblyStaleMessage?.header.id == id, sourceLocation: sourceLocation)

            let message = await retrieve(stale: false)
            #expect(message?.header.id == id, sourceLocation: sourceLocation)

            return message
        case .staleCachedMessage(let id):
            let possiblyStaleMessage = await retrieve(stale: true)
            #expect(possiblyStaleMessage?.header.id == id, sourceLocation: sourceLocation)

            let message = await retrieve(stale: false)
            #expect(message == nil, sourceLocation: sourceLocation)

            return possiblyStaleMessage
        case .noCachedMessageExists:
            let message = await retrieve(stale: false)
            #expect(message == nil, sourceLocation: sourceLocation)

            let possiblyStaleMessage = await retrieve(stale: true)
            #expect(possiblyStaleMessage == nil, sourceLocation: sourceLocation)

            return nil
        }
    }

    func makeMessage(
        checkingDisabled: Bool = true,
        ttl: UInt32 = 97,
        cnameTTL: UInt32 = 201
    ) -> Message {
        Message(
            header: Header(
                id: .random(in: .min ... .max),
                messageType: .Response,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: true,
                authenticData: true,
                checkingDisabled: checkingDisabled,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 2,
                nameServerCount: 0,
                additionalCount: 0
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
                    ttl: cnameTTL,
                    rdata: RData.CNAME(
                        CNAME(
                            domainName: try! DomainName("www.example.com.cdn.cloudflare.net.")
                        )
                    )
                ),
                Record(
                    nameLabels: try! DomainName("www.example.com.cdn.cloudflare.net."),
                    dnsClass: .IN,
                    ttl: ttl,
                    rdata: RData.AAAA(AAAA(value: IPv6Address("[2606:4700:10::ac42:9071]")!))
                ),
            ]),
            nameServers: [],
            additionals: [],
            signature: [],
            edns: nil
        )
    }
}
