import NIOCore

/// FIXME: add tests for dot in name string
@available(swiftDNSApplePlatforms 15, *)
extension DomainName {
    public init(ip: IPAddress) {
        switch ip {
        case .v4(let ipv4):
            self.init(ipv4: ipv4)
        case .v6(let ipv6):
            self.init(ipv6: ipv6)
        }
    }

    public init(ipv4: IPv4Address) {
        var buffer = ByteBuffer()
        buffer.reserveCapacity(8)

        let lengthPrefixIndex = buffer.writerIndex
        // Write a zero as a placeholder which will later be overwritten by the actual number of bytes written
        buffer.writeInteger(.zero, as: UInt8.self)

        let startWriterIndex = buffer.writerIndex

        /// TODO: Optimize writing the integers as strings, should not need to allocate a
        /// whole string. Can do manual decimal conversions.
        let bytes = ipv4.bytes
        buffer.writeString(String(bytes.0))
        buffer.writeInteger(UInt8.asciiDot)
        buffer.writeString(String(bytes.1))
        buffer.writeInteger(UInt8.asciiDot)
        buffer.writeString(String(bytes.2))
        buffer.writeInteger(UInt8.asciiDot)
        buffer.writeString(String(bytes.3))

        let endWriterIndex = buffer.writerIndex
        let bytesWritten = endWriterIndex - startWriterIndex

        /// This is safe to unwrap. The implementation above cannot write more bytes than a UInt8 can represent.
        let lengthPrefix = UInt8(exactly: bytesWritten).unsafelyUnwrapped

        buffer.setInteger(
            lengthPrefix,
            at: lengthPrefixIndex,
            as: UInt8.self
        )

        self.init(isFQDN: false, data: buffer)
    }

    public init(ipv6: IPv6Address) {
        var buffer = ByteBuffer()
        buffer.reserveCapacity(26)

        let lengthPrefixIndex = buffer.writerIndex
        // Write a zero as a placeholder which will later be overwritten by the actual number of bytes written
        buffer.writeInteger(.zero, as: UInt8.self)

        let startWriterIndex = buffer.writerIndex

        func add(_ bytePair: UInt16) {
            /// TODO: Optimize writing the integers as strings, should not need to allocate a
            /// whole string. Can do manual hexadecimal conversions.
            buffer.writeString(
                String(bytePair, radix: 16, uppercase: false)
            )
        }

        ipv6.description(writeInto: &buffer)

        let endWriterIndex = buffer.writerIndex
        let bytesWritten = endWriterIndex - startWriterIndex

        /// This is safe to unwrap. The implementation above cannot more bytes than a UInt8 can represent.
        let lengthPrefix = UInt8(exactly: bytesWritten).unsafelyUnwrapped

        buffer.setInteger(
            lengthPrefix,
            at: lengthPrefixIndex,
            as: UInt8.self
        )

        self.init(isFQDN: false, data: buffer)
    }
}
