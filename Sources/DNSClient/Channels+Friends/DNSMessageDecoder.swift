package import DNSModels
package import NIOCore

@available(swiftDNSApplePlatforms 26, *)
package struct DNSMessageDecoder: NIOSingleStepByteToMessageDecoder {
    package enum DecodingResult {
        case message(Message)
        case identifiableError(id: UInt16, error: any Error)

        var messageID: UInt16 {
            switch self {
            case .message(let message):
                return message.header.id
            case .identifiableError(let id, _):
                return id
            }
        }
    }

    package typealias InboundOut = DecodingResult

    package init() {}

    package func decode(buffer: inout ByteBuffer) -> DecodingResult? {
        /// Make sure we have at least 12 bytes to read as the DNS header
        /// We might receive and empty buffer when the channel goes inactive and not having a check
        /// like this will cause issues with false Message decoding failures when the buffer
        /// didn't even contain any bytes to decode.
        ///
        /// Warning: the error-catching logic below relies on the fact that the buffer is guaranteed
        /// to contain at least 2 bytes when the code reaches there, so if you change this, you
        /// need to change the error-catching logic below as well.
        guard buffer.readableBytes >= 12 else {
            return nil
        }

        var dnsBuffer = DNSBuffer(buffer: buffer)
        let startIndex = dnsBuffer.readerIndex
        /// Avoid CoW when used in dnsBuffer
        buffer = ByteBuffer()
        defer {
            /// Need to keep the buffer up to date so `NIOSingleStepByteToMessageDecoder` knows
            buffer = ByteBuffer(dnsBuffer: dnsBuffer)
        }
        do {
            let message = try Message(from: &dnsBuffer)
            return .message(message)
        } catch {
            /// The first 2 bytes of a DNS message are the message's ID
            /// We use the message ID as the identifier throughout the lifecycle of a query,
            /// so this can be useful to specifically fail a query with the error.
            ///
            /// We need to set back the end index otherwise NIOSingleStepByteToMessageDecoder will
            /// call this function in a non-ending loop and that's not good.
            let endIndex = dnsBuffer.readerIndex
            dnsBuffer.moveReaderIndex(to: startIndex)
            /// We are guaranteed to have these 2 bytes based in the check above, so we can safely
            /// force-unwrap the ID.
            let id = dnsBuffer.readInteger(as: UInt16.self)!
            dnsBuffer.moveReaderIndex(to: endIndex)

            precondition(
                startIndex != endIndex,
                """
                The readerIndex has not changed after a decoding failure.
                This should never happen and might result in an infinite loop.
                The header reads must have moved the reader index forward.
                Please file a bug report at https://github.com/mahdibm/swift-dns/issues.
                Buffer dump (max 512 bytes):
                \(buffer.hexDump(format: .detailed(maxBytes: 512)))
                """
            )

            return .identifiableError(id: id, error: error)
        }
    }

    package func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) -> DecodingResult? {
        self.decode(buffer: &buffer)
    }
}
