import Atomics
public import DNSModels
package import Logging
public import NIOCore
import NIOPosix

/// Single connection to a DNS server
@available(swiftDNSApplePlatforms 13, *)
public final actor DNSConnection: Sendable {
    @usableFromInline
    let executor: any SerialExecutor
    @inlinable
    nonisolated public var unownedExecutor: UnownedSerialExecutor {
        self.executor.asUnownedSerialExecutor()
    }

    /// Connection ID, used by connection pool
    public let id: ID
    /// Logger used by Server
    let logger: Logger
    @usableFromInline
    let channel: any Channel
    @usableFromInline
    let channelHandler: DNSChannelHandler
    let configuration: DNSConnectionConfiguration
    let isClosed: ManagedAtomic<Bool>
    var isOverUDP: Bool {
        channelHandler.isOverUDP
    }

    /// Initialize connection
    package init(
        channel: any Channel,
        connectionID: ID,
        channelHandler: DNSChannelHandler,
        configuration: DNSConnectionConfiguration,
        logger: Logger
    ) {
        if #available(swiftDNSApplePlatforms 14, *) {
            self.executor = channel.eventLoop.executor
        } else {
            /// FIXME: Satisfy compiler while I find out what to do here
            self.executor = { fatalError() }()
        }
        self.channel = channel
        self.channelHandler = channelHandler
        self.configuration = configuration
        self.id = connectionID
        self.logger = logger
        self.isClosed = .init(false)
    }

    /// Close connection
    public nonisolated func close() {
        guard
            self.isClosed.compareExchange(
                expected: false,
                desired: true,
                successOrdering: .relaxed,
                failureOrdering: .relaxed
            ).exchanged
        else {
            return
        }
        self.channel.close(mode: .all, promise: nil)
    }

    /// Send a query to DNS connection
    /// - Parameter message: The query DNS message
    /// - Returns: The response DNS message
    @inlinable
    package func send(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions,
        allocator: ByteBufferAllocator
    ) async throws -> Message {
        let preparedQuery = try self.prepareQuery(
            message: factory,
            options: options,
            allocator: allocator
        )
        return try await preparedQuery.send()
    }

    /// Send a query to DNS connection
    /// - Parameter
    ///   - message: The query DNS message
    ///   - options: The options for producing the query message
    ///   - allocator: The allocator for producing the query message
    /// - Returns: The response DNS message
    @inlinable
    package func prepareQuery(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions,
        allocator: ByteBufferAllocator
    ) throws -> PreparedQuery {
        try self.channelHandler.preflightCheck()
        let producedMessage = try self.channelHandler.queryProducer.produceMessage(
            message: factory,
            options: options,
            allocator: allocator
        )
        return PreparedQuery(
            connection: self,
            producedMessage: producedMessage
        )
    }

    /// Send a query to DNS connection
    /// - Parameter message: The query DNS message
    /// - Returns: The response DNS message
    @inlinable
    func send(producedMessage: ProducedMessage) async throws -> Message {
        let requestID = producedMessage.messageID
        /// TODO: use the other cancel function below when compiler bug is resolved
        /// Then we can remove this whole unsafe line
        nonisolated(unsafe) let channelHandler = self.channelHandler
        return try await withTaskCancellationHandler {
            if Task.isCancelled {
                throw DNSClientError.cancelled
            }
            return try await withCheckedThrowingContinuation { continuation in
                self.channelHandler.write(
                    producedMessage: producedMessage,
                    promise: .swift(continuation)
                )
            }
        } onCancel: {
            self.cancel(requestID: requestID, channelHandler: channelHandler)
        }
    }

    @usableFromInline
    nonisolated func cancel(requestID: UInt16, channelHandler: DNSChannelHandler) {
        /// TODO: use the other cancel function below when compiler bug is resolved
        nonisolated(unsafe) let channelHandler = channelHandler
        self.channel.eventLoop.execute {
            channelHandler.cancel(requestID: requestID)
        }
    }

    // There is a compiler bug so this is commented out for now
    // The bug happens when you run tests on macOS using Swiftly 6.2.0 toolchain
    // @usableFromInline
    // nonisolated func cancel(requestID: UInt16) {
    //     self.channel.eventLoop.execute {
    //         self.assumeIsolated {
    //             $0.channelHandler.cancel(requestID: requestID)
    //         }
    //     }
    // }
}

@available(swiftDNSApplePlatforms 13, *)
@usableFromInline
package struct PreparedQuery: Sendable, ~Copyable {
    @usableFromInline
    package let connection: DNSConnection
    @usableFromInline
    package let producedMessage: ProducedMessage

    @inlinable
    init(connection: DNSConnection, producedMessage: ProducedMessage) {
        self.producedMessage = producedMessage
        self.connection = connection
    }

    @inlinable
    package func send() async throws -> Message {
        try await self.connection.send(
            producedMessage: self.producedMessage
        )
    }
}
