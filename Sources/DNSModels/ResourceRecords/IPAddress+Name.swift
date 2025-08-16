import NIOCore

/// FIXME: add tests for dot in name string
@available(swiftDNSApplePlatforms 26, *)
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

        for idx in 0..<4 {
            let shift = 8 &* (3 &- idx)
            let shifted = ipAddress.address &>> shift
            let byte = UInt8(truncatingIfNeeded: shifted)
            let string = String(byte)

            let lengthPrefixIndex = buffer.writerIndex
            buffer.writeInteger(.zero, as: UInt8.self)

            let startWriterIndex = buffer.writerIndex

            /// TODO: Optimize writing the integers as strings, should not need to allocate a
            /// whole string. Can do manual decimal conversions.
            buffer.writeString(string)

            let endWriterIndex = buffer.writerIndex
            let bytesWritten = endWriterIndex - startWriterIndex

            /// This is safe to unwrap. The implementation above cannot more bytes than a UInt8 can represent.
            let lengthPrefix = UInt8(exactly: bytesWritten).unsafelyUnwrapped

            buffer.setInteger(
                lengthPrefix,
                at: lengthPrefixIndex,
                as: UInt8.self
            )
        }

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

        buffer.writeInteger(UInt8.asciiOpeningSquareBracket)

        /// TODO: This should write the compact form of the ipv6, not the full form.
        /// e.g. `[2a01:5cc0:1:2::4]`, not `[2a01:5cc0:1:2:0:0:0:4]`
        for idx in 0..<8 {
            let doubledIdx = idx * 2
            let shift = 8 &* (14 &- doubledIdx)
            let shifted = ipAddress.address &>> shift
            let combined = UInt16(truncatingIfNeeded: shifted)

            /// TODO: Optimize writing the integers as strings, should not need to allocate a
            /// whole string. Can do manual hexadecimal conversions.
            let string = String(combined, radix: 16, uppercase: false)

            /// This is safe to unwrap. No integer is larger than 255 characters in hexadecimal.
            buffer.writeString(string)

            if idx < 7 {
                buffer.writeInteger(UInt8.asciiColon)
            }
        }

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
