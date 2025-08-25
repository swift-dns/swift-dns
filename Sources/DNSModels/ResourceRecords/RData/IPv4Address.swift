/// An IPv4 address.
///
/// IPv4 addresses are defined as 32-bit integers in [IETF RFC 791].
/// They are usually represented as four octets.
///
/// See [`IpAddr`] for a type encompassing both IPv4 and IPv6 addresses.
///
/// [IETF RFC 791]: https://tools.ietf.org/html/rfc791
///
/// # Textual representation
///
/// `Ipv4Addr` provides a [`FromStr`] implementation. The four octets are in decimal
/// notation, divided by `.` (this is called "dot-decimal notation").
/// Notably, octal numbers (which are indicated with a leading `0`) and hexadecimal numbers (which
/// are indicated with a leading `0x`) are not allowed per [IETF RFC 6943].
///
/// [IETF RFC 6943]: https://tools.ietf.org/html/rfc6943#section-3.1.1
public struct IPv4Address: Sendable, Hashable {
    @usableFromInline
    static var size: Int {
        4
    }

    public var address: UInt32

    public init(_ address: UInt32) {
        self.address = address
    }

    public init(_ _1: UInt8, _ _2: UInt8, _ _3: UInt8, _ _4: UInt8) {
        /// All these unchecked operations are safe because _1, _2, _3, _4 are always in 0..<256
        self.address = UInt32(_1) &<< 24 | UInt32(_2) &<< 16 | UInt32(_3) &<< 8 | UInt32(_4)
    }
}

extension IPv4Address {
    public var bytes: (UInt8, UInt8, UInt8, UInt8) {
        withUnsafeBytes(of: self.address) { ptr in
            (ptr[3], ptr[2], ptr[1], ptr[0])
        }
    }
}

extension IPv4Address: CustomStringConvertible {
    public var description: String {
        var result: String = ""
        /// TODO: Smarter reserving capacity
        result.reserveCapacity(7)
        withUnsafeBytes(of: self.address) {
            let range = 0..<4
            var iterator = range.makeIterator()

            let first = iterator.next().unsafelyUnwrapped
            /// TODO: This can be optimized to not have to convert to a string
            result.append(String($0[3 - first]))

            while let idx = iterator.next() {
                result.append(".")
                /// TODO: This can be optimized to not have to convert to a string
                result.append(String($0[3 - idx]))
            }
        }
        return result
    }
}

extension IPv4Address: LosslessStringConvertible {
    public init?(_ description: String) {
        var address: UInt32 = 0

        let utf8 = description.utf8

        var byteIdx = 0
        var startIndex = utf8.startIndex
        /// We accept any of the 4 IDNA label separators (including `.`)
        /// This will make sure a valid ipv4 domain-name parses fine using this method
        while let nextSeparatorIdx = utf8[startIndex...].firstIndex(where: \.isIDNALabelSeparator) {
            /// TODO: Don't go through an String conversion here
            guard let string = String(utf8[startIndex..<nextSeparatorIdx]),
                let byte = UInt8(string)
            else {
                return nil
            }

            address |= UInt32(byte) &<< (8 &* (3 &- byteIdx))

            /// This is safe, nothing will crash with this increase in index
            startIndex = utf8.index(nextSeparatorIdx, offsetBy: 1)

            if byteIdx == 2 {
                /// Read last byte and return
                guard let string = String(utf8[startIndex...]),
                    let byte = UInt8(string)
                else {
                    return nil
                }

                address |= UInt32(byte)

                self.init(address)
                return
            }

            byteIdx &+= 1
        }

        /// Should not have reached here
        return nil
    }
}

extension IPv4Address {
    package init(from buffer: inout DNSBuffer) throws {
        self.address = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("IPv4Address", buffer)
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
                    let shift = 8 &* (3 &- idx)
                    self.address |= UInt32(byte) &<< shift
                case false:
                    break
                }
            }
        }
        buffer.moveReaderIndex(forwardBy: addressLength)
    }
}

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
            let shift = 8 &* (3 &- idx)
            let shifted = self.address &>> shift
            let byte = UInt8(truncatingIfNeeded: shifted)
            buffer.writeInteger(byte)
        }
    }
}
