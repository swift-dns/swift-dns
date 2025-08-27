import SwiftIDNA

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
        self.address = UInt32(_1) &<< 24
        self.address |= UInt32(_2) &<< 16
        self.address |= UInt32(_3) &<< 8
        self.address |= UInt32(_4)
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

        let scalars = description.unicodeScalars

        var byteIdx = 0
        var chunkStartIndex = scalars.startIndex
        let endIndex = scalars.endIndex
        /// We accept any of the 4 IDNA label separators (including `.`)
        /// This will make sure a valid ipv4 domain-name parses fine using this method
        while let nextSeparatorIdx = scalars[chunkStartIndex..<endIndex].firstIndex(
            where: \.isIDNALabelSeparator
        ) {
            /// TODO: Don't go through an String conversion here
            guard
                let part = IPv4Address.mapToDecimalDigitsBasedOnIDNA(
                    scalars[chunkStartIndex..<nextSeparatorIdx]
                ),
                let byte = UInt8(String(part))
            else {
                return nil
            }

            let shift = 8 &* (3 &- byteIdx)
            address |= UInt32(byte) &<< shift

            /// This is safe, nothing will crash with this increase in index
            chunkStartIndex = scalars.index(nextSeparatorIdx, offsetBy: 1)

            if byteIdx == 2 {
                /// TODO: Don't go through an String conversion here
                /// Read last byte and return
                guard
                    let part = IPv4Address.mapToDecimalDigitsBasedOnIDNA(
                        scalars[chunkStartIndex..<endIndex]
                    ),
                    let byte = UInt8(String(part))
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

    static func mapToDecimalDigitsBasedOnIDNA(
        _ scalars: String.UnicodeScalarView.SubSequence
    ) -> String.UnicodeScalarView.SubSequence? {
        /// Short-circuit if all scalars are ASCII
        if scalars.allSatisfy(\.isASCII) {
            /// Still might not be a valid number
            return scalars
        }

        var newScalars = [Unicode.Scalar]()
        newScalars.reserveCapacity(scalars.count)

        for idx in scalars.indices {
            let scalar = scalars[idx]
            switch IDNAMapping.for(scalar: scalar) {
            case .valid:
                newScalars.append(scalar)
            case .mapped(let mapped), .deviation(let mapped):
                guard mapped.count == 1 else {
                    /// If this was a number it would have never had a mapped value of > 1
                    return nil
                }
                newScalars.append(mapped.first.unsafelyUnwrapped)
            case .ignored:
                continue
            case .disallowed:
                return nil
            }
        }

        return String.UnicodeScalarView.SubSequence(newScalars)
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
