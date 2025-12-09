public import struct DNSModels.Message
public import struct NIOCore.EventLoopPromise
public import struct NIOCore.NIODeadline

@available(swiftDNSApplePlatforms 10.15, *)
@usableFromInline
package struct PendingQuery: Sendable {
    @usableFromInline
    package enum DynamicPromise<T: Sendable>: Sendable {
        case nio(EventLoopPromise<T>)
        case swift(CheckedContinuation<T, any Error>)

        /// Only supposed to be used in `QueryProducer`
        @usableFromInline
        func _queryProducer_succeed(with value: T) {
            switch self {
            case .nio(let eventLoopPromise):
                eventLoopPromise.succeed(value)
            case .swift(let checkedContinuation):
                checkedContinuation.resume(returning: value)
            }
        }

        /// Only supposed to be used in `QueryProducer`
        @usableFromInline
        func _queryProducer_fail(with error: any Error) {
            switch self {
            case .nio(let eventLoopPromise):
                eventLoopPromise.fail(error)
            case .swift(let checkedContinuation):
                checkedContinuation.resume(throwing: error)
            }
        }
    }

    @usableFromInline
    package var promise: DynamicPromise<Message>
    @usableFromInline
    package let requestID: UInt16
    @usableFromInline
    package let deadline: NIODeadline

    /// Use ProducedMessage.producePendingQuery instead.
    @usableFromInline
    package init(__promise: DynamicPromise<Message>, requestID: UInt16, deadline: NIODeadline) {
        self.promise = __promise
        self.requestID = requestID
        self.deadline = deadline
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension PendingQuery: CustomDebugStringConvertible {
    public var debugDescription: String {
        "PendingQuery(promise: \(self.promise), requestID: \(self.requestID), deadline: \(self.deadline))"
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension PendingQuery.DynamicPromise: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nio(let eventLoopPromise):
            return ".nio(\(eventLoopPromise))"
        case .swift(let checkedContinuation):
            return ".swift(\(checkedContinuation))"
        }
    }
}
