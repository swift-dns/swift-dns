import DNSCore

@available(swiftDNSApplePlatforms 10.15, *)
extension IPv4Address {
    package init(from buffer: inout DNSBuffer) throws {
        self.init(
            try buffer.readInteger(as: UInt32.self).unwrap(
                or: .failedToRead("IPv4Address", buffer)
            )
        )
    }

    package init(from buffer: inout DNSBuffer, addressLength: Int) throws {
        guard addressLength <= 4 else {
            throw ProtocolError.failedToValidate(
                "IPv4Address.addressLength",
                buffer
            )
        }
        guard buffer.readableBytes >= addressLength else {
            throw ProtocolError.failedToRead(
                "IPv4Address_with_addressLength",
                buffer
            )
        }

        self.init(0)

        buffer.withUnsafeReadableBytes { ptr in
            for idx in 0..<4 {
                switch idx < addressLength {
                case true:
                    let byte = ptr[idx]
                    /// All these unchecked operations are safe because idx is always in 0..<4
                    let shift = 8 &** (3 &-- idx)
                    self.address |= UInt32(byte) &<<< shift
                case false:
                    break
                }
            }
        }
        buffer.moveReaderIndex(forwardBy: addressLength)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension IPv4Address {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.address)
    }

    package func encode(into buffer: inout DNSBuffer, addressLength: Int) throws {
        guard addressLength <= 4 else {
            throw ProtocolError.failedToValidate(
                "IPv4Address.addressLength",
                buffer
            )
        }
        buffer.reserveCapacity(minimumWritableBytes: addressLength)

        for idx in 0..<addressLength {
            /// All these unchecked operations are safe because idx is always in 0..<4
            let shift = 8 &** (3 &-- idx)
            let shifted = self.address &>>> shift
            let byte = UInt8(truncatingIfNeeded: shifted)
            buffer.writeInteger(byte)
        }
    }
}
