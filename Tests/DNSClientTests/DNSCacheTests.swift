import DNSClient
import Testing

@Suite
struct DNSCacheTests {
    @Test(arguments: [true, false])
    func `cache message and retrieve it`(checkingDisabled: Bool) async throws {
        let cache = DNSCache(clock: .continuous)
        let message = self.makeMessage(checkingDisabled: checkingDisabled)

        let domainName = try #require(message.queries.first).domainName
        let ttl = try #require(message.answers.last).ttl
        await cache.cache(
            domainName: domainName,
            message: message,
            ttl: ttl
        )

        let retrievedMessage = await cache.retrieve(
            domainName: domainName,
            checkingDisabled: true
        )
        #expect(retrievedMessage?.header.id == message.header.id)
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
        let ttl = try #require(message.answers.last).ttl
        await cache.cache(
            domainName: domainName,
            message: message,
            ttl: ttl
        )

        testClock.advance(by: .seconds(timeTravelSeconds))

        let _retrievedMessage = await cache.retrieve(
            domainName: domainName,
            checkingDisabled: true
        )
        let retrievedMessage = try #require(_retrievedMessage)
        #expect(retrievedMessage.header.id == message.header.id)

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
        let ttl = try #require(message.answers.last).ttl
        await cache.cache(
            domainName: domainName,
            message: message,
            ttl: ttl
        )

        testClock.advance(by: .seconds(ttl + 1))

        for checkingDisabled in [true, false] {
            let retrievedMessage = await cache.retrieve(
                domainName: domainName,
                checkingDisabled: checkingDisabled
            )
            #expect(retrievedMessage == nil)
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
            let ttl = try #require(message.answers.last).ttl
            await cache.cache(
                domainName: domainName,
                message: message,
                ttl: ttl
            )
        }

        let retrievedMessage = await cache.retrieve(
            domainName: domainName,
            checkingDisabled: checkingDisabled
        )
        #expect(retrievedMessage?.header.id == message1.header.id)
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

        let ttl1 = try #require(message1.answers.last).ttl
        await cache.cache(
            domainName: domainName,
            message: message1,
            ttl: ttl1
        )

        testClock.advance(by: .seconds(2))
        let ttl2 = try #require(message2.answers.last).ttl
        await cache.cache(
            domainName: domainName,
            message: message2,
            ttl: ttl2
        )

        let retrievedMessage = await cache.retrieve(
            domainName: domainName,
            checkingDisabled: checkingDisabled
        )
        /// `message1` had a ttl of 100. After 2 seconds we added `message2` with a ttl of 99.
        /// At that point `message1`'s ttl was 98, so `message2` should have been saved instead.
        #expect(retrievedMessage?.header.id == message2.header.id)
    }

    @Test func `retrieving message prefers to return message with checking enabled`() async throws {
        let cache = DNSCache(clock: .continuous)
        let messageWithCheckingDisabled = self.makeMessage(checkingDisabled: true)
        let messageWithCheckingEnabled = self.makeMessage(checkingDisabled: false)

        let domainName = try #require(messageWithCheckingDisabled.queries.first).domainName
        #expect(domainName == messageWithCheckingEnabled.queries.first?.domainName)

        for message in [messageWithCheckingDisabled, messageWithCheckingEnabled] {
            let ttl = try #require(message.answers.last).ttl
            await cache.cache(
                domainName: domainName,
                message: message,
                ttl: ttl
            )
        }

        do {
            let retrievedMessage = await cache.retrieve(
                domainName: domainName,
                checkingDisabled: true
            )
            /// We requested `checkingDisabled: true` but we should still get the message with checking enabled.
            #expect(retrievedMessage?.header.id == messageWithCheckingEnabled.header.id)
        }

        do {
            let retrievedMessage = await cache.retrieve(
                domainName: domainName,
                checkingDisabled: false
            )
            #expect(retrievedMessage?.header.id == messageWithCheckingEnabled.header.id)
        }
    }

    func makeMessage(checkingDisabled: Bool = true, ttl: UInt32 = 97) -> Message {
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
