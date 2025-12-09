public import struct DNSModels.DNSBuffer
public import struct DNSModels.Message
public import typealias DNSModels.RDataConvertible
public import struct NIOCore.ByteBuffer
public import struct NIOCore.ByteBufferAllocator
public import struct NIOCore.NIODeadline

@available(swiftDNSApplePlatforms 10.15, *)
@usableFromInline
package struct QueryProducer: Sendable, ~Copyable {
    @usableFromInline
    var messageIDGenerator: MessageIDGenerator

    @inlinable
    package init() {
        self.messageIDGenerator = MessageIDGenerator()
    }

    @usableFromInline
    package mutating func produceDNSMessage(
        message factory: consuming MessageFactory<some RDataConvertible>
    ) throws -> Message {
        let requestID = try self.messageIDGenerator.next()
        factory.apply(requestID: requestID)
        return factory.takeMessage()
    }

    @usableFromInline
    package mutating func produceMessage(
        message factory: consuming MessageFactory<some RDataConvertible>,
        allocator: ByteBufferAllocator
    ) throws -> ProducedMessage {
        let message = try self.produceDNSMessage(
            message: factory
        )
        return try ProducedMessage(
            message: message,
            allocator: allocator
        )
    }

    @usableFromInline
    package mutating func fulfillQuery(
        pendingQuery: PendingQuery,
        with message: Message
    ) {
        pendingQuery.promise._queryProducer_succeed(with: message)
        messageIDGenerator.remove(pendingQuery.requestID)
    }

    @usableFromInline
    package mutating func fulfillQuery(
        pendingQuery: PendingQuery,
        with error: any Error
    ) {
        pendingQuery.promise._queryProducer_fail(with: error)
        messageIDGenerator.remove(pendingQuery.requestID)
    }
}

/// A message with a handle to create a PendingQuery from it.
@available(swiftDNSApplePlatforms 10.15, *)
@usableFromInline
package struct ProducedMessage: Sendable {
    @usableFromInline
    let _message: Message
    @inlinable
    package var messageID: UInt16 {
        self._message.header.id
    }
    @usableFromInline
    package let encodedMessage: DNSBuffer

    @usableFromInline
    package init(message: Message, allocator: ByteBufferAllocator) throws {
        self._message = message
        var buffer = DNSBuffer(
            buffer: allocator.buffer(capacity: 512)
        )
        try message.encode(into: &buffer)
        self.encodedMessage = buffer
    }

    @usableFromInline
    package func producePendingQuery(
        promise: PendingQuery.DynamicPromise<Message>,
        deadline: NIODeadline
    ) -> PendingQuery {
        PendingQuery(
            __promise: promise,
            requestID: self.messageID,
            deadline: deadline
        )
    }
}
