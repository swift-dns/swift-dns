public import struct DNSModels.DNSRequestOptions
public import struct DNSModels.Message
public import struct DNSModels.MessageFactory
public import typealias DNSModels.RDataConvertible
public import struct NIOCore.NIODeadline

@usableFromInline
@available(swiftDNSApplePlatforms 26, *)
package struct QueryProducer: ~Copyable {
    private var messageIDGenerator: MessageIDGenerator

    package init() {
        self.messageIDGenerator = MessageIDGenerator()
    }

    @usableFromInline
    package mutating func produceMessage(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions
    ) throws(MessageIDGenerator.Errors) -> Message {
        let requestID = try self.messageIDGenerator.next()
        factory.apply(options: options)
        factory.apply(requestID: requestID)
        let message = factory.takeMessage()
        return message
    }

    /// A description
    /// - Parameters:
    ///   - alreadyProducedMessage: The message that was produced by `produceMessage`.
    ///     This is a REQUIREMENT. Only pass a message here that was produced by `produceMessage`.
    ///   - promise: The promise that will be fulfilled when query is over.
    ///   - deadline: The deadline for the query.
    ///
    /// - Throws: MessageIDGenerator.Errors
    /// - Returns: PendingQuery
    @usableFromInline
    package mutating func producePendingQuery(
        alreadyProducedMessage message: Message,
        promise: PendingQuery.DynamicPromise<Message>,
        deadline: NIODeadline
    ) -> PendingQuery {
        PendingQuery(
            promise: promise,
            requestID: message.header.id,
            deadline: deadline
        )
    }

    @usableFromInline
    package mutating func fullfilQuery(
        pendingQuery: PendingQuery,
        with message: Message
    ) {
        pendingQuery.promise.queryProducer_succeed(with: message)
        messageIDGenerator.remove(pendingQuery.requestID)
    }

    @usableFromInline
    package mutating func fullfilQuery(
        pendingQuery: PendingQuery,
        with error: any Error
    ) {
        pendingQuery.promise.queryProducer_fail(with: error)
        messageIDGenerator.remove(pendingQuery.requestID)
    }
}
