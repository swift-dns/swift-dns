public import Logging
/// FIXME: as of writing this comment we only need EventLoopGroup as public, but Swift 6.2 doesn't
/// accept multiple access levels for the same module, so can't import the symbols one by one with
/// different access levels.
public import NIOCore
import NIOPosix

public import struct DNSModels.Message

public struct DNSClient {
    public var connectionTarget: ConnectionTarget
    let eventLoopGroup: any EventLoopGroup
    let queryPool: QueryPool
    let logger: Logger

    /// FIXME: shouldn't expose EventLoopGroup anymore?
    public init(
        connectionTarget: ConnectionTarget,
        eventLoopGroup: any EventLoopGroup,
        logger: Logger = .noopLogger
    ) {
        self.connectionTarget = connectionTarget
        self.eventLoopGroup = eventLoopGroup
        self.queryPool = QueryPool()
        self.logger = logger
    }

    public init(
        connectionTarget: ConnectionTarget,
        logger: Logger = .noopLogger
    ) {
        self.connectionTarget = connectionTarget
        self.eventLoopGroup = MultiThreadedEventLoopGroup.singleton
        self.queryPool = QueryPool()
        self.logger = logger
    }

    public func query(message: Message) async throws -> Message {
        // FIXME: catch connection target to socket address translation errors
        let connectionFactory = try ConnectionFactory(
            queryPool: queryPool,
            connectionTarget: connectionTarget
        )
        /// FIXME: use a connection pool and all
        let channel = try await connectionFactory.makeChannel(
            deadline: .now() + .seconds(10),
            eventLoop: eventLoopGroup.next(),
            logger: logger
        ).get()
        return try await withCheckedThrowingContinuation { (continuation: QueryPool.Continuation) in
            queryPool.insert(message, continuation: continuation)
            // FIXME: what if the channel is closed and rejects this write?
            channel.writeAndFlush(message).whenComplete { result in
                switch result {
                case .success:
                    // Good
                    break
                case .failure(let error):
                    // FIXME: should have a better way to handle this
                    preconditionFailure(
                        "Failed to write message: \(String(reflecting: error))"
                    )
                }
            }
        }
    }
}
