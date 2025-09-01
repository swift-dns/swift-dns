import NIOCore

/// FIXME: add tests for dot in name string
@available(swiftDNSApplePlatforms 15, *)
extension Name {
    public init(ipAddress: IPAddress) {
        switch ipAddress {
        case .v4(let ipv4):
            self.init(ipAddress: ipv4)
        case .v6(let ipv6):
            self.init(ipAddress: ipv6)
        }
    }

    public init(ipAddress: IPv4Address) {
        var buffer = ByteBuffer()
        buffer.reserveCapacity(8)

        let lengthPrefixIndex = buffer.writerIndex
        buffer.writeInteger(.zero, as: UInt8.self)

        let startWriterIndex = buffer.writerIndex

        /// TODO: Optimize writing the integers as strings, should not need to allocate a
        /// whole string. Can do manual decimal conversions.
        let bytes = ipAddress.bytes
        buffer.writeString(String(bytes.0))
        buffer.writeInteger(UInt8.asciiDot)
        buffer.writeString(String(bytes.1))
        buffer.writeInteger(UInt8.asciiDot)
        buffer.writeString(String(bytes.2))
        buffer.writeInteger(UInt8.asciiDot)
        buffer.writeString(String(bytes.3))

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

    public init(ipAddress: IPv6Address) {
        var buffer = ByteBuffer()
        buffer.reserveCapacity(26)

        var totalBytesWritten = 0

        let lengthPrefixIndex = buffer.writerIndex
        // Write a zero as a placeholder which will later be overwritten by the actual number of bytes written
        totalBytesWritten += buffer.writeInteger(.zero, as: UInt8.self)

        let startWriterIndex = buffer.writerIndex

        func add(_ bytePair: UInt16) {
            /// TODO: Optimize writing the integers as strings, should not need to allocate a
            /// whole string. Can do manual hexadecimal conversions.
            buffer.writeString(
                String(bytePair, radix: 16, uppercase: false)
            )
        }

        /// TODO: This should write the compact form of the ipv6, not the full form.
        /// e.g. `[2a01:5cc0:1:2::4]`, not `[2a01:5cc0:1:2:0:0:0:4]`
        let bytePairs = ipAddress.bytePairs

        buffer.writeInteger(UInt8.asciiOpeningSquareBracket)
        /// FIXME: Turn this into a loop with reading unsafeBytes?
        add(bytePairs.0)
        buffer.writeInteger(UInt8.asciiColon)
        add(bytePairs.1)
        buffer.writeInteger(UInt8.asciiColon)
        add(bytePairs.2)
        buffer.writeInteger(UInt8.asciiColon)
        add(bytePairs.3)
        buffer.writeInteger(UInt8.asciiColon)
        add(bytePairs.4)
        buffer.writeInteger(UInt8.asciiColon)
        add(bytePairs.5)
        buffer.writeInteger(UInt8.asciiColon)
        add(bytePairs.6)
        buffer.writeInteger(UInt8.asciiColon)
        add(bytePairs.7)
        buffer.writeInteger(UInt8.asciiClosingSquareBracket)

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
