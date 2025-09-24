public import DNSModels
package import Logging
public import NIOCore
import NIOPosix
import Synchronization

#if canImport(Network)
import Network
import NIOTransportServices
#endif

/// Single connection to a DNS server
@available(swiftDNSApplePlatforms 15, *)
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
    let isClosed: Atomic<Bool>
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
        self.executor = channel.eventLoop.executor
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
        try self.channelHandler.preflightCheck()
        let producedMessage = try self.produceMessage(
            message: factory,
            options: options,
            allocator: allocator
        )
        return try await self.send(producedMessage: producedMessage)
    }

    @inlinable
    package func preflightCheck() throws {
        try self.channelHandler.preflightCheck()
    }

    /// Send a query to DNS connection
    /// - Parameter message: The query DNS message
    /// - Returns: The response DNS message
    @inlinable
    package func produceMessage(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions,
        allocator: ByteBufferAllocator
    ) throws -> ProducedMessage {
        try self.channelHandler.queryProducer.produceMessage(
            message: factory,
            options: options,
            allocator: allocator
        )
    }

    /// Send a query to DNS connection
    /// - Parameter message: The query DNS message
    /// - Returns: The response DNS message
    @inlinable
    package func send(producedMessage: ProducedMessage) async throws -> Message {
        let requestID = producedMessage.messageID
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
            self.cancel(requestID: requestID)
        }
    }

    @usableFromInline
    nonisolated func cancel(requestID: UInt16) {
        // self.channel.eventLoop.execute {
        //     self.assumeIsolated {
        //         $0.channelHandler.cancel(requestID: requestID)
        //     }
        // }
    }
}
