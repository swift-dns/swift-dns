import NIOCore

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

        let bytes = ipv4.bytes
        bytes.0.asDecimal(
            writeUTF8Byte: {
                buffer.writeInteger($0)
            }
        )
        buffer.writeInteger(UInt8.asciiDot)

        bytes.1.asDecimal(
            writeUTF8Byte: {
                buffer.writeInteger($0)
            }
        )
        buffer.writeInteger(UInt8.asciiDot)

        bytes.2.asDecimal(
            writeUTF8Byte: {
                buffer.writeInteger($0)
            }
        )
        buffer.writeInteger(UInt8.asciiDot)

        bytes.3.asDecimal(
            writeUTF8Byte: {
                buffer.writeInteger($0)
            }
        )

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

        buffer = ipv6.makeDescription { (maxWriteableBytes, callback) in
            buffer.writeWithUnsafeMutableBytes(minimumWritableBytes: maxWriteableBytes) { ptr in
                callback(ptr.bindMemory(to: UInt8.self))
            }
            return buffer
        }

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
