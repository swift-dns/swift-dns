import DNSModels
import Synchronization

final class QueryPool: @unchecked Sendable /* Protected by Mutex */ {
    typealias Continuation = CheckedContinuation<Message, any Error>
    private let queries: Mutex<[UInt16: Continuation]> = .init([:])

    // FIXME: needs some kind of garbage collector?

    func insert(_ message: borrowing Message, continuation: Continuation) {
        queries.withLock { queries in
            queries[message.header.id] = continuation
        }
    }

    // FIXME: consuming?
    func succeed(with message: /*consuming*/ Message) {
        queries.withLock { queries in
            queries[message.header.id]?.resume(returning: message)
        }
    }

    func fail(id: UInt16, with error: any Error) {
        queries.withLock { queries in
            queries[id]?.resume(throwing: error)
        }
    }
}
