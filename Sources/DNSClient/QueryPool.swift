import DNSModels
import Synchronization

final class QueryPool: @unchecked Sendable /* Protected by Mutex */ {
    typealias Continuation = CheckedContinuation<Message, any Error>
    private let queries: Mutex<[UInt16: Continuation]> = .init([:])

    // FIXME: needs some kind of garbage collector?

    /// FIXME: Handle duplicate inserts
    func insert(_ message: borrowing Message, continuation: Continuation) {
        queries.withLock { queries in
            queries[message.header.id] = continuation
        }
    }

    func contains(_ message: borrowing Message) -> Bool {
        queries.withLock { queries in
            queries[message.header.id] != nil
        }
    }

    // FIXME: consuming?
    /// Returns true if the message was found and succeeded, false otherwise.
    func succeed(with message: /*consuming*/ Message) -> Bool {
        queries.withLock { queries in
            queries.removeValue(forKey: message.header.id)?.resume(returning: message) != nil
        }
    }

    /// Returns true if the message was found and failed, false otherwise.
    func fail(id: UInt16, with error: any Error) -> Bool {
        queries.withLock { queries in
            queries.removeValue(forKey: id)?.resume(throwing: error) != nil
        }
    }
}
