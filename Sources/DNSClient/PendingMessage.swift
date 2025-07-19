public import struct DNSModels.Message
public import struct NIOCore.EventLoopPromise
public import struct NIOCore.NIODeadline

@usableFromInline
struct PendingMessage {
    @usableFromInline
    init(promise: DynamicPromise<Message>, requestID: Int, deadline: NIODeadline) {
        self.promise = promise
        self.requestID = requestID
        self.deadline = deadline
    }

    var promise: DynamicPromise<Message>
    let requestID: Int
    let deadline: NIODeadline
}

@usableFromInline
enum DynamicPromise<T: Sendable>: Sendable {
    case nio(EventLoopPromise<T>)
    case swift(CheckedContinuation<T, any Error>)

    func succeed(_ value: T) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.succeed(value)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(returning: value)
        }
    }

    func fail(with error: any Error) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.fail(error)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(throwing: error)
        }
    }
}
