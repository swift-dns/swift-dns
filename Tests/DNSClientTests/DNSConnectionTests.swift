import DNSClient
import DNSModels
import Logging
import NIOCore
import NIOEmbedded
import Synchronization
import Testing

@Suite
struct DNSConnectionTests {
    @available(swiftDNSApplePlatforms 15, *)
    @Test func `simple query tests`() async throws {
        try await self.runSimpleQueryTests(
            queryableTypes: A.self,
            AAAA.self,
            TXT.self,
            CNAME.self,
            CAA.self,
            CERT.self,
            MX.self,
            NS.self,
            PTR.self,
            OPT.self,
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `simple query`() async throws {
        try await self.runSimpleQueryTests(
            queryableTypes: A.self,
            AAAA.self,
            TXT.self,
            CNAME.self,
            CAA.self,
            CERT.self,
            MX.self,
            NS.self,
            PTR.self,
            OPT.self,
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    func runSimpleQueryTests<each QueryableType: Queryable>(
        queryableTypes: repeat (each QueryableType).Type
    ) async throws {
        try await withThrowingTaskGroup { taskGroup -> Void in
            for queryableType in repeat each queryableTypes {
                taskGroup.addTask {
                    try await self.runSimpleQueryTest(queryableType: queryableType.self)
                }
            }
            try await taskGroup.waitForAll()
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    func runSimpleQueryTest<QueryableType: Queryable>(
        queryableType: QueryableType.Type
    ) async throws {
        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        async let asyncResponse = try await connection.send(
            message: MessageFactory<QueryableType>.forQuery(name: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
        let messageID = try #require(outbound.peekInteger(as: UInt16.self))
        /// The message ID should not be 0 because the channel handler reassigns it
        #expect(messageID != 0)

        let (buffer, message) = self.bufferAndMessage(
            from: responseResource,
            changingIDTo: messageID
        )

        try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

        let response = try await asyncResponse
        /// FIXME: use equatable instead of string comparison
        #expect("\(response)" == "\(message)")
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `simple query cancelled`() async throws {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: DNSClientError.cancelled) {
                    _ = try await connection.send(
                        message: MessageFactory<QueryableType>.forQuery(name: domainName),
                        options: .default,
                        allocator: .init()
                    )
                }
            }

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
            let messageID = try #require(outbound.peekInteger(as: UInt16.self))
            /// The message ID should not be 0 because the channel handler reassigns it
            #expect(messageID != 0)

            group.cancelAll()
        }

        #expect(channel.isActive)
    }

    // @available(swiftDNSApplePlatforms 15, *)
    // @Test
    // func `simple query cancelled then response arrives later then continue using the channel`()
    //     async throws
    // {
    //     let (connection, channel) = try await self.makeTestConnection()

    //     do {
    //         typealias QueryableType = TXT

    //         let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
    //         let domainName = try #require(responseResource.domainName)

    //         /// TODO: better code here to make sure we don't need to manually call
    //         /// `preflightCheck` here before producing the message.
    //         /// If we change some code in the actual connection code in
    //         /// `connection.send(message:options:allocator:)`, this code will have to change
    //         /// as well, and if we forget to make such a change then this test will be inaccurate.
    //         try await connection.preflightCheck()
    //         let producedMessage = try await connection.produceMessage(
    //             message: MessageFactory<QueryableType>.forQuery(name: domainName),
    //             options: .default,
    //             allocator: .init()
    //         )
    //         let messageID = producedMessage.messageID

    //         try await withThrowingTaskGroup(of: Void.self) { group in
    //             group.addTask {
    //                 await #expect(throws: DNSClientError.cancelled) {
    //                     _ = try await connection.send(
    //                         producedMessage: producedMessage
    //                     )
    //                 }
    //             }

    //             let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
    //             #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
    //             let messageID = try #require(outbound.peekInteger(as: UInt16.self))
    //             /// The message ID should not be 0 because the channel handler reassigns it
    //             #expect(messageID != 0)

    //             group.cancelAll()
    //         }

    //         #expect(channel.isActive)

    //         /// Response arrives after the timeout
    //         let (buffer, _) = self.bufferAndMessage(
    //             from: responseResource,
    //             changingIDTo: messageID
    //         )

    //         try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

    //         /// Nothing should happen here
    //     }

    //     /// Do another query over the same connection
    //     do {
    //         typealias QueryableType = CAA

    //         let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
    //         let domainName = try #require(responseResource.domainName)

    //         async let asyncResponse = try await connection.send(
    //             message: MessageFactory<QueryableType>.forQuery(name: domainName),
    //             options: .default,
    //             allocator: .init()
    //         )

    //         let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
    //         #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
    //         let messageID = try #require(outbound.peekInteger(as: UInt16.self))
    //         /// The message ID should not be 0 because the channel handler reassigns it
    //         #expect(messageID != 0)

    //         let (buffer, message) = self.bufferAndMessage(
    //             from: responseResource,
    //             changingIDTo: messageID
    //         )

    //         try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

    //         let response = try await asyncResponse
    //         /// FIXME: use equatable instead of string comparison
    //         #expect("\(response)" == "\(message)")
    //     }
    // }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `simple query timed out`() async throws {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        async let asyncResponse = try await connection.send(
            message: MessageFactory<QueryableType>.forQuery(name: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
        let messageID = try #require(outbound.peekInteger(as: UInt16.self))
        /// The message ID should not be 0 because the channel handler reassigns it
        #expect(messageID != 0)

        let eventLoop = (channel.eventLoop as! NIOAsyncTestingEventLoop)
        await eventLoop.advanceTime(by: .seconds(15))

        do {
            _ = try await asyncResponse
        } catch DNSClientError.queryTimeout {
            /// Good
        } catch {
            Issue.record("Expected DNSClientError.queryTimeout, got \(String(reflecting: error))")
        }

        #expect(channel.isActive)
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test
    func `simple query timed out then response arrives later then continue using the channel`()
        async throws
    {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        do {
            let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
            let domainName = try #require(responseResource.domainName)

            async let asyncResponse = try await connection.send(
                message: MessageFactory<QueryableType>.forQuery(name: domainName),
                options: .default,
                allocator: .init()
            )

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
            let messageID = try #require(outbound.peekInteger(as: UInt16.self))
            /// The message ID should not be 0 because the channel handler reassigns it
            #expect(messageID != 0)

            let eventLoop = (channel.eventLoop as! NIOAsyncTestingEventLoop)
            await eventLoop.advanceTime(by: .seconds(15))

            do {
                _ = try await asyncResponse
            } catch DNSClientError.queryTimeout {
                /// Good
            } catch {
                Issue.record(
                    "Expected DNSClientError.queryTimeout, got \(String(reflecting: error))"
                )
            }

            #expect(channel.isActive)

            let (buffer, _) = self.bufferAndMessage(
                from: responseResource,
                changingIDTo: messageID
            )

            try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

            /// Nothing should happen here
        }

        /// Do another query over the same connection
        do {
            typealias QueryableType = CAA

            let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
            let domainName = try #require(responseResource.domainName)

            async let asyncResponse = try await connection.send(
                message: MessageFactory<QueryableType>.forQuery(name: domainName),
                options: .default,
                allocator: .init()
            )

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
            let messageID = try #require(outbound.peekInteger(as: UInt16.self))
            /// The message ID should not be 0 because the channel handler reassigns it
            #expect(messageID != 0)

            let (buffer, message) = self.bufferAndMessage(
                from: responseResource,
                changingIDTo: messageID
            )

            try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

            let response = try await asyncResponse
            /// FIXME: use equatable instead of string comparison
            #expect("\(response)" == "\(message)")
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `sequential A queries over one connection`() async throws {
        typealias QueryableType = A

        let (connection, channel) = try await self.makeTestConnection()

        for _ in 0..<1_000 {
            let (_, responseResource) = Resources.forQuery(
                queryableType: QueryableType.self
            )
            let domainName = try #require(responseResource.domainName)

            /// TODO: better code here to make sure we don't need to manually call
            /// `preflightCheck` here before producing the message.
            /// If we change some code in the actual connection code in
            /// `connection.send(message:options:allocator:)`, this code will have to change
            /// as well, and if we forget to make such a change then this test will be inaccurate.
            try await connection.preflightCheck()
            let producedMessage = try await connection.produceMessage(
                message: MessageFactory<QueryableType>.forQuery(name: domainName),
                options: .default,
                allocator: .init()
            )
            let messageID = producedMessage.messageID
            async let asyncResponse = try await connection.send(
                producedMessage: producedMessage
            )

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            let receivedMessageID = try #require(
                outbound.peekInteger(as: UInt16.self)
            )
            #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
            #expect(receivedMessageID == messageID)

            let (buffer, message) = self.bufferAndMessage(
                from: responseResource,
                changingIDTo: messageID
            )
            try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

            let response = try await asyncResponse
            /// TODO: use an actual Equality checker here instead of description comparison
            #expect("\(response)" == "\(message)")
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `concurrent MX queries over one connection`() async throws {
        typealias QueryableType = MX

        try await withThrowingTaskGroup { taskGroup -> Void in
            let (connection, channel) = try await self.makeTestConnection()

            let messageSuccessfullySentOverChannel: Mutex<[UInt16: ByteBuffer]> = Mutex([:])
            let messageSuccessfullySentOverChannelCount: Atomic<Int> = Atomic(0)
            let count = MessageIDGenerator.capacity

            for _ in 0..<count {
                taskGroup.addTask { @Sendable in
                    let (_, responseResource) = Resources.forQuery(
                        queryableType: QueryableType.self
                    )
                    let domainName = try #require(responseResource.domainName)

                    /// TODO: better code here to make sure we don't need to manually call
                    /// `preflightCheck` here before producing the message.
                    /// If we change some code in the actual connection code in
                    /// `connection.send(message:options:allocator:)`, this code will have to change
                    /// as well, and if we forget to make such a change then this test will be inaccurate.
                    try await connection.preflightCheck()
                    let producedMessage = try await connection.produceMessage(
                        message: MessageFactory<QueryableType>.forQuery(name: domainName),
                        options: .default,
                        allocator: .init()
                    )
                    let messageID = producedMessage.messageID
                    async let asyncResponse = try await connection.send(
                        producedMessage: producedMessage
                    )

                    /// We're sending queries concurrently so this is not necessarily the
                    /// message that we just sent. We just wait for one message to be written and
                    /// save it for now.
                    let oneOutbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    let oneReceivedMessageID = try #require(
                        oneOutbound.peekInteger(as: UInt16.self)
                    )
                    messageSuccessfullySentOverChannelCount.add(1, ordering: .relaxed)
                    messageSuccessfullySentOverChannel.withLock {
                        $0[oneReceivedMessageID] = oneOutbound
                    }
                    /// The message ID should not be 0 because the channel handler reassigns it
                    #expect(oneReceivedMessageID != 0)

                    try await self.simpleWait(until: {
                        messageSuccessfullySentOverChannel.withLock({ $0[messageID] != nil })
                    })

                    let _outbound = messageSuccessfullySentOverChannel.withLock({ $0[messageID] })
                    let outbound = try #require(_outbound)
                    #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
                    #expect(outbound.peekInteger(as: UInt16.self) == messageID)

                    let (buffer, message) = self.bufferAndMessage(
                        from: responseResource,
                        changingIDTo: messageID
                    )
                    try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

                    let response = try await asyncResponse
                    /// TODO: use an actual Equality checker here instead of description comparison
                    #expect("\(response)" == "\(message)")
                }
            }

            try await taskGroup.waitForAll()

            /// There is a chance that message IDs were reused and a value replaced another value
            /// in the dictionary.
            #expect(messageSuccessfullySentOverChannel.withLock({ $0.count }) <= count)
            #expect(messageSuccessfullySentOverChannelCount.load(ordering: .relaxed) == count)
        }
    }

    /// Don't want to make the tests complicated.
    /// Wait for `until` to return true, in a simple manner.
    func simpleWait(until: () -> Bool) async throws {
        for _ in 0..<20 {
            switch until() {
            case true:
                return
            case false:
                try await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    func bufferAndMessage(
        from resource: Resources,
        changingIDTo messageID: UInt16?
    ) -> (buffer: DNSBuffer, message: Message) {
        var buffer = resource.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)
        if let messageID {
            buffer.setInteger(messageID, at: 42)
        }
        let readerIndex = buffer.readerIndex
        let message = try! Message(from: &buffer)
        /// Reset the reader index to reuse the buffer
        buffer.moveReaderIndex(to: readerIndex)
        return (buffer, message)
    }

    @available(swiftDNSApplePlatforms 15, *)
    func makeTestConnection(
        configuration: DNSConnectionConfiguration = .init(),
        address: DNSServerAddress = .domain(
            name: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
            port: 53
        ),
        isOverUDP: Bool = true
    ) async throws -> (
        connection: DNSConnection,
        channel: NIOAsyncTestingChannel
    ) {
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        /// FIXME: This is safe but better solution than using nonisolated(unsafe)?
        nonisolated(unsafe) let channelHandler = DNSChannelHandler(
            eventLoop: channel.eventLoop,
            configuration: configuration,
            isOverUDP: isOverUDP,
            logger: logger
        )
        let connection = DNSConnection(
            channel: channel,
            connectionID: .random(in: .min ... .max),
            channelHandler: channelHandler,
            configuration: configuration,
            logger: logger
        )
        channel.eventLoop.execute {
            try! channel.pipeline.syncOperations.addHandler(channelHandler)
        }
        try await channel.connect(to: address.asSocketAddress())
        return (connection, channel)
    }
}
