import Logging
import NIOCore
import NIOPosix

public import struct DNSModels.Message

public struct Client {
    public static func query(message: Message) async throws -> Message {
        let queryPool = QueryPool()
        // FIXME: catch connection target to socket address translation errors
        let connectionFactory = try ConnectionFactory(
            queryPool: queryPool,
            connectionTarget: .domain(
                name: "8.8.4.4",
                port: 53
            )
        )
        let logger = Logger(label: "DNSClient")
        let channel = try await connectionFactory.makeChannel(
            deadline: .now() + .seconds(10),
            eventLoop: MultiThreadedEventLoopGroup.singleton.next(),
            logger: logger
        ).get()
        return try await withCheckedThrowingContinuation { (continuation: QueryPool.Continuation) in
            queryPool.insert(message, continuation: continuation)
            // FIXME: what if the channel is closed and all and rejects this write?
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
