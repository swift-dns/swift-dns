public import DNSModels
import Logging
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
    nonisolated public let unownedExecutor: UnownedSerialExecutor

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
    init(
        channel: any Channel,
        connectionID: ID,
        channelHandler: DNSChannelHandler,
        configuration: DNSConnectionConfiguration,
        logger: Logger
    ) {
        self.unownedExecutor = channel.eventLoop.executor.asUnownedSerialExecutor()
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
    func send(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions,
        allocator: ByteBufferAllocator
    ) async throws -> Message {
        let producedMessage = try self.channelHandler.queryProducer.produceMessage(
            message: factory,
            options: options,
            allocator: allocator
        )
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
        self.channel.eventLoop.execute {
            self.assumeIsolated {
                $0.channelHandler.cancel(requestID: requestID)
            }
        }
    }
}
