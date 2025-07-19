public import DNSModels
import Logging
public import NIOCore
import NIOPosix
import NIOSSL
import Synchronization

#if canImport(Network)
import Network
import NIOTransportServices
#endif

/// Single connection to a DNS server
@available(swiftDNS 1.0, *)
public final actor DNSConnection: Sendable {
    nonisolated public let unownedExecutor: UnownedSerialExecutor

    /// Request ID generator
    @usableFromInline
    static let requestIDGenerator: IDGenerator = .init()
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
    func send(message: Message) async throws -> Message {
        let requestID = Self.requestIDGenerator.next()
        return try await withTaskCancellationHandler {
            if Task.isCancelled {
                throw DNSClientError.cancelled
            }
            return try await withCheckedThrowingContinuation { continuation in
                self.channelHandler.write(
                    message: message,
                    continuation: continuation,
                    requestID: requestID
                )
            }
        } onCancel: {
            self.cancel(requestID: requestID)
        }
    }

    @usableFromInline
    nonisolated func cancel(requestID: Int) {
        self.channel.eventLoop.execute {
            self.assumeIsolated {
                $0.channelHandler.cancel(requestID: requestID)
            }
        }
    }
}

// Used in DNSConnection.pipeline
@usableFromInline
struct AutoIncrementingInteger {
    @usableFromInline
    var value: Int = 0

    @inlinable
    init() {
        self.value = 0
    }

    @inlinable
    mutating func next() -> Int {
        value += 1
        return value - 1
    }
}
