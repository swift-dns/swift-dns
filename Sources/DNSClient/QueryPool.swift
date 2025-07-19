import DNSModels
import NIOCore
import Synchronization

/// Protected the eventLoop
final class QueryPool: @unchecked Sendable {
    typealias Continuation = CheckedContinuation<Message, any Error>
    private var queries: [UInt16: Continuation] = [:]

    let eventLoop: any EventLoop

    init(eventLoop: any EventLoop) {
        self.eventLoop = eventLoop
    }

    // FIXME: needs some kind of garbage collector?

    /// FIXME: Handle duplicate inserts
    func insert(_ message: borrowing Message, continuation: Continuation) {
        self.eventLoop.assertInEventLoop()
        queries[message.header.id] = continuation
    }

    func contains(_ message: borrowing Message) -> Bool {
        self.eventLoop.assertInEventLoop()
        return queries[message.header.id] != nil
    }

    // FIXME: consuming?
    /// Returns true if the message was found and succeeded, false otherwise.
    /// use `consuming`?
    func succeed(with message: Message) -> Bool {
        self.eventLoop.assertInEventLoop()
        return queries.removeValue(forKey: message.header.id)?.resume(returning: message) != nil
    }

    /// Returns true if the message was found and failed, false otherwise.
    func fail(id: UInt16, with error: any Error) -> Bool {
        self.eventLoop.assertInEventLoop()
        return queries.removeValue(forKey: id)?.resume(throwing: error) != nil
    }
}
