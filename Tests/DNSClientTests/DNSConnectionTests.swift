import Atomics
import DNSClient
import DNSModels
import Logging
import NIOConcurrencyHelpers
import NIOCore
import NIOEmbedded
import Testing

@Suite
struct DNSConnectionTests {
    @available(swiftDNSApplePlatforms 13, *)
    @Test func `query tests`() async throws {
        try await self.runQueryTests(
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

    @available(swiftDNSApplePlatforms 13, *)
    func runQueryTests<each QueryableType: Queryable>(
        queryableTypes: repeat (each QueryableType).Type
    ) async throws {
        try await withThrowingTaskGroup { taskGroup -> Void in
            for queryableType in repeat each queryableTypes {
                taskGroup.addTask {
                    try await self.runQueryTest(queryableType: queryableType.self)
                }
            }
            try await taskGroup.waitForAll()
        }
    }

    @available(swiftDNSApplePlatforms 13, *)
    func runQueryTest<QueryableType: Queryable>(
        queryableType: QueryableType.Type
    ) async throws {
        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        async let asyncResponse = try await connection.send(
            message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
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

    @available(swiftDNSApplePlatforms 13, *)
    @Test func `query cancelled`() async throws {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await #expect(throws: DNSClientError.cancelled) {
                    _ = try await connection.send(
                        message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                        options: .default,
                        allocator: .init()
                    )
                }
            }

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
            let messageID = try #require(outbound.peekInteger(as: UInt16.self))
            /// The message ID should not be 0 because the channel handler reassigns it
            #expect(messageID != 0)

            group.cancelAll()
        }

        #expect(channel.isActive)
    }

    @available(swiftDNSApplePlatforms 13, *)
    @Test
    func `query cancelled then response arrives later then continue using the channel`()
        async throws
    {
        let (connection, channel) = try await self.makeTestConnection()

        do {
            typealias QueryableType = TXT

            let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
            let domainName = try #require(responseResource.domainName)

            nonisolated(unsafe) var sentMessageID: UInt16!

            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { @Sendable in
                    await #expect(throws: DNSClientError.cancelled) {
                        let preparedQuery = try await connection.prepareQuery(
                            message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                            options: .default,
                            allocator: .init()
                        )

                        sentMessageID = preparedQuery.producedMessage.messageID

                        _ = try await preparedQuery.send()
                    }
                }

                let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
                let receivedMessageID = try #require(outbound.peekInteger(as: UInt16.self))
                /// The message ID should not be 0 because the channel handler reassigns it
                #expect(receivedMessageID != 0)
                #expect(receivedMessageID == sentMessageID)

                group.cancelAll()
            }

            #expect(channel.isActive)

            /// Response arrives after the timeout
            let (buffer, _) = self.bufferAndMessage(
                from: responseResource,
                changingIDTo: sentMessageID
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
                message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                options: .default,
                allocator: .init()
            )

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
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

    @available(swiftDNSApplePlatforms 13, *)
    @Test func `query does not run when task is already cancelled`() async throws {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        await withThrowingTaskGroup(of: Void.self) { group in
            group.cancelAll()

            group.addTask {
                await #expect(throws: DNSClientError.cancelled) {
                    _ = try await connection.send(
                        message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                        options: .default,
                        allocator: .init()
                    )
                }
            }
        }

        #expect(channel.isActive)
    }

    @available(swiftDNSApplePlatforms 13, *)
    @Test func `query timed out`() async throws {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        async let asyncResponse = try await connection.send(
            message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
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

    @available(swiftDNSApplePlatforms 13, *)
    @Test
    func `query timed out then response arrives later then continue using the channel`()
        async throws
    {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        do {
            let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
            let domainName = try #require(responseResource.domainName)

            async let asyncResponse = try await connection.send(
                message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                options: .default,
                allocator: .init()
            )

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
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
                message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                options: .default,
                allocator: .init()
            )

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
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

    @available(swiftDNSApplePlatforms 13, *)
    @Test func `query does not run when connection is closed`() async throws {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        connection.close()

        await #expect(throws: DNSClientError.connectionClosed) {
            _ = try await connection.send(
                message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                options: .default,
                allocator: .init()
            )
        }

        #expect(!channel.isActive)
    }

    @available(swiftDNSApplePlatforms 13, *)
    @Test func `sequential A queries over one connection`() async throws {
        typealias QueryableType = A

        let (connection, channel) = try await self.makeTestConnection()

        try await self.runSequentialTestQueries(
            connection: connection,
            channel: channel,
            count: 1_000,
            queryableType: QueryableType.self
        )
    }

    @available(swiftDNSApplePlatforms 13, *)
    func runSequentialTestQueries<QueryableType: Queryable>(
        connection: DNSConnection,
        channel: NIOAsyncTestingChannel,
        count: Int,
        queryableType: QueryableType.Type
    ) async throws {
        for _ in 0..<count {
            let (_, responseResource) = Resources.forQuery(
                queryableType: QueryableType.self
            )
            let domainName = try #require(responseResource.domainName)

            let preparedQuery = try await connection.prepareQuery(
                message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                options: .default,
                allocator: .init()
            )
            let producedMessage = preparedQuery.producedMessage
            let messageID = producedMessage.messageID
            async let asyncResponse = try await preparedQuery.send()

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            let receivedMessageID = try #require(
                outbound.peekInteger(as: UInt16.self)
            )
            #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
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

    @available(swiftDNSApplePlatforms 13, *)
    @Test func `concurrent MX queries over one connection`() async throws {
        typealias QueryableType = MX

        try await withThrowingTaskGroup { taskGroup -> Void in
            let (connection, channel) = try await self.makeTestConnection()

            try await self.runConcurrentTestQueries(
                connection: connection,
                channel: channel,
                taskGroup: &taskGroup,
                count: MessageIDGenerator.capacity,
                queryableType: QueryableType.self
            )
        }
    }

    @available(swiftDNSApplePlatforms 13, *)
    func runConcurrentTestQueries<QueryableType: Queryable>(
        connection: DNSConnection,
        channel: NIOAsyncTestingChannel,
        taskGroup: inout ThrowingTaskGroup<Void, any Error>,
        count: Int,
        queryableType: QueryableType.Type
    ) async throws {
        let messageSuccessfullySentOverChannel: NIOLockedValueBox<[UInt16: ByteBuffer]> =
            NIOLockedValueBox([:])
        let messageSuccessfullySentOverChannelCount: ManagedAtomic<Int> = ManagedAtomic(0)

        for _ in 0..<count {
            taskGroup.addTask { @Sendable in
                let (_, responseResource) = Resources.forQuery(
                    queryableType: QueryableType.self
                )
                let domainName = try #require(responseResource.domainName)

                let preparedQuery = try await connection.prepareQuery(
                    message: MessageFactory<QueryableType>.forQuery(domainName: domainName),
                    options: .default,
                    allocator: .init()
                )
                let messageID = preparedQuery.producedMessage.messageID
                async let asyncResponse = try await preparedQuery.send()

                /// We're sending queries concurrently so this is not necessarily the
                /// message that we just sent. We just wait for one message to be written and
                /// save it for now.
                let oneOutbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                let oneReceivedMessageID = try #require(
                    oneOutbound.peekInteger(as: UInt16.self)
                )
                messageSuccessfullySentOverChannelCount.wrappingIncrement(by: 1, ordering: .relaxed)
                messageSuccessfullySentOverChannel.withLockedValue {
                    $0[oneReceivedMessageID] = oneOutbound
                }
                /// The message ID should not be 0 because the channel handler reassigns it
                #expect(oneReceivedMessageID != 0)

                try await self.simpleWait(until: {
                    messageSuccessfullySentOverChannel.withLockedValue({ $0[messageID] != nil })
                })

                let _outbound = messageSuccessfullySentOverChannel.withLockedValue({
                    $0[messageID]
                })
                let outbound = try #require(_outbound)
                #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
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
        #expect(messageSuccessfullySentOverChannel.withLockedValue({ $0.count }) <= count)
        #expect(messageSuccessfullySentOverChannelCount.load(ordering: .relaxed) == count)
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

    @available(swiftDNSApplePlatforms 13, *)
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

    @available(swiftDNSApplePlatforms 13, *)
    func makeTestConnection(
        configuration: DNSConnectionConfiguration = .init(),
        address: DNSServerAddress = .domain(
            domainName: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
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
