import DNSModels

enum Utils {
    @available(swiftDNSApplePlatforms 10.15, *)
    static func buffer(
        from resource: Resources,
        changingIDTo messageID: UInt16?
    ) -> DNSBuffer {
        var buffer = resource.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)
        if let messageID {
            buffer.setInteger(messageID, at: 42)
        }
        let readerIndex = buffer.readerIndex
        /// Reset the reader index to reuse the buffer
        buffer.moveReaderIndex(to: readerIndex)
        return buffer
    }

    @available(swiftDNSApplePlatforms 10.15, *)
    static func bufferAndMessage(
        from resource: Resources,
        changingIDTo messageID: UInt16?
    ) -> (buffer: DNSBuffer, message: Message) {
        var buffer = resource.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)
        if let messageID {
            buffer.setInteger(messageID, at: 42)
        }
        let readerIndex = buffer.readerIndex
        let message = try! Message(from: &buffer)
        /// Reset the reader index to reuse the buffer
        buffer.moveReaderIndex(to: readerIndex)
        return (buffer, message)
    }
}
