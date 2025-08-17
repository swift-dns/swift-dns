public import struct DNSModels.DNSRequestOptions
public import struct DNSModels.Message
public import struct DNSModels.MessageFactory
public import typealias DNSModels.RDataConvertible
public import struct NIOCore.NIODeadline

@available(swiftDNSApplePlatforms 15, *)
@usableFromInline
package struct QueryProducer: ~Copyable {
    private var messageIDGenerator: MessageIDGenerator

    package init() {
        self.messageIDGenerator = MessageIDGenerator()
    }

    @usableFromInline
    package mutating func produceMessage(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions
    ) throws(MessageIDGenerator.Errors) -> ProducedMessage {
        let requestID = try self.messageIDGenerator.next()
        factory.apply(options: options)
        factory.apply(requestID: requestID)
        let message = factory.takeMessage()
        return ProducedMessage(message: message)
    }

    @usableFromInline
    package mutating func fullfilQuery(
        pendingQuery: PendingQuery,
        with message: Message
    ) {
        pendingQuery.promise._queryProducer_succeed(with: message)
        messageIDGenerator.remove(pendingQuery.requestID)
    }

    @usableFromInline
    package mutating func fullfilQuery(
        pendingQuery: PendingQuery,
        with error: any Error
    ) {
        pendingQuery.promise._queryProducer_fail(with: error)
        messageIDGenerator.remove(pendingQuery.requestID)
    }
}

/// A message with a handle to create a PendingQuery from it.
@available(swiftDNSApplePlatforms 15, *)
@usableFromInline
package struct ProducedMessage {
    @usableFromInline
    package let message: Message

    @usableFromInline
    package init(message: Message) {
        self.message = message
    }

    @usableFromInline
    package func producePendingQuery(
        promise: PendingQuery.DynamicPromise<Message>,
        deadline: NIODeadline
    ) -> PendingQuery {
        PendingQuery(
            __promise: promise,
            requestID: self.message.header.id,
            deadline: deadline
        )
    }
}
