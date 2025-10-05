import DNSCore

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    package init(from buffer: inout DNSBuffer) throws {
        self.init(
            try buffer.readInteger(as: UInt128.self).unwrap(
                or: .failedToRead("IPv6Address", buffer)
            )
        )
    }

    package init(from buffer: inout DNSBuffer, addressLength: Int) throws {
        guard addressLength <= 16 else {
            throw ProtocolError.failedToValidate(
                "IPv6Address.addressLength",
                buffer
            )
        }
        guard buffer.readableBytes >= addressLength else {
            throw ProtocolError.failedToRead(
                "IPv6Address_with_addressLength",
                buffer
            )
        }

        self.init(0)

        buffer.withUnsafeReadableBytes { ptr in
            for idx in 0..<16 {
                switch idx < addressLength {
                case true:
                    let byte = ptr[idx]
                    /// All these unchecked operations are safe because idx is always in 0..<16
                    let shift = 8 &** (15 &-- idx)
                    self.address |= UInt128(byte) &<<< shift
                case false:
                    break
                }
            }
        }
        buffer.moveReaderIndex(forwardBy: addressLength)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.address)
    }

    package func encode(into buffer: inout DNSBuffer, addressLength: Int) throws {
        guard addressLength <= 16 else {
            throw ProtocolError.failedToValidate(
                "IPv6Address.addressLength",
                buffer
            )
        }
        buffer.reserveCapacity(minimumWritableBytes: addressLength)

        for idx in 0..<addressLength {
            /// All these unchecked operations are safe because idx is always in 0..<16
            let shift = 8 &** (15 &-- idx)
            let shifted = self.address &>>> shift
            let masked = shifted & 0xFF
            let byte = UInt8(exactly: masked).unsafelyUnwrapped
            buffer.writeInteger(byte)
        }
    }
}
