public import SwiftIDNA

/// An IPv4 address.
///
/// IPv4 addresses are defined as 32-bit integers in [IETF RFC 791].
/// They are usually represented as four octets.
///
/// See [`IPAddress`] for a type encompassing both IPv4 and IPv6 addresses.
///
/// [IETF RFC 791]: https://tools.ietf.org/html/rfc791
///
/// # Textual representation
///
/// `IPv4Address` provides an initializer that accepts a string. The four octets are in decimal
/// notation, divided by `.` (this is called "dot-decimal notation").
/// Notably, octal numbers (which are indicated with a leading `0`) and hexadecimal numbers (which
/// are indicated with a leading `0x`) are not allowed per [IETF RFC 6943].
///
/// [IETF RFC 6943]: https://tools.ietf.org/html/rfc6943#section-3.1.1
public struct IPv4Address: Sendable, Hashable, _IPAddressProtocol {
    /// The byte size of an IPv4.
    @usableFromInline
    static var size: Int {
        4
    }

    /// The underlying 32 bits (4 bytes) representing this IPv4 address.
    public var address: UInt32

    /// Whether this address is an IPv4 Loopback address, known as localhost, or not.
    /// Equivalent to `127.0.0.0/8` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `01111111`.
    /// In other words, any IPv4 address starting with `127`.
    @available(swiftDNSApplePlatforms 15, *)
    @inlinable
    public var isLoopback: Bool {
        CIDR<Self>.loopback.contains(self)
    }

    /// Whether this address is an IPv4 Multicast address, or not.
    /// Equivalent to `224.0.0.0/4` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `1110`.
    /// In other words, any IPv4 address whose first byte is within the range of `224 ... 239`.
    /// For example `224.1.2.3` and `239.255.2.44` but not `223.x.x.x` and not `240.x.x.x`.
    @available(swiftDNSApplePlatforms 15, *)
    @inlinable
    public var isMulticast: Bool {
        CIDR<Self>.multicast.contains(self)
    }

    /// Whether this address is an IPv4 Link Local address, or not.
    /// Equivalent to `169.254.0.0/16` in CIDR notation.
    /// That is, any IPv4 address starting with this sequence of bits: `1010100111111110`.
    /// In other words, any IPv4 address starting with `169.254`.
    @available(swiftDNSApplePlatforms 15, *)
    @inlinable
    public var isLinkLocal: Bool {
        CIDR<Self>.linkLocal.contains(self)
    }

    public init(_ address: UInt32) {
        self.address = address
    }

    /// Maps an IPv6 address to an IPv4 address if the ipv6 is in a specific address space mentioned in [RFC 4291, IP Version 6 Addressing Architecture, February 2006](https://datatracker.ietf.org/doc/rfc4291#section-2.5.5.2).
    ///
    /// ```text
    /// 2.5.5.2.  IPv4-Mapped IPv6 Address
    ///
    ///    A second type of IPv6 address that holds an embedded IPv4 address is
    ///    defined.  This address type is used to represent the addresses of
    ///    IPv4 nodes as IPv6 addresses.  The format of the "IPv4-mapped IPv6
    ///    address" is as follows:
    ///
    /// Hinden                      Standards Track                    [Page 10]
    /// RFC 4291              IPv6 Addressing Architecture         February 2006
    ///
    ///    |                80 bits               | 16 |      32 bits        |
    ///    +--------------------------------------+--------------------------+
    ///    |0000..............................0000|FFFF|    IPv4 address     |
    ///    +--------------------------------------+----+---------------------+
    ///
    ///    See [RFC4038] for background on the usage of the "IPv4-mapped IPv6
    ///    address".
    /// ```
    @available(swiftDNSApplePlatforms 15, *)
    @inlinable
    public init?(ipv6: IPv6Address) {
        guard
            withUnsafeBytes(
                of: ipv6.address,
                { ptr in
                    ptr[4] == 0xFF
                        && ptr[5] == 0xFF
                        && (6..<16).allSatisfy { ptr[$0] == 0x00 }
                }
            )
        else {
            return nil
        }

        self.address = UInt32(truncatingIfNeeded: ipv6.address)
    }

    @inlinable
    public init(_ _1: UInt8, _ _2: UInt8, _ _3: UInt8, _ _4: UInt8) {
        self.address = 0
        withUnsafeMutableBytes(of: &self.address) { ptr in
            ptr[3] = _1
            ptr[2] = _2
            ptr[1] = _3
            ptr[0] = _4
        }
    }
}

extension IPv4Address {
    /// The 4 bytes representing this IPv4 address.
    public var bytes: (UInt8, UInt8, UInt8, UInt8) {
        withUnsafeBytes(of: self.address) { ptr in
            (ptr[3], ptr[2], ptr[1], ptr[0])
        }
    }
}

extension IPv4Address: CustomStringConvertible {
    /// The textual representation of an IPv4 address.
    @inlinable
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

extension IPv4Address: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt32) {
        self.address = value
    }
}

extension IPv4Address: LosslessStringConvertible {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// This implementation is IDNA compliant.
    /// That means the following addresses are considered equal: `192｡₁₆₈｡₁｡98`, `192.168.1.98`.
    @inlinable
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

    @usableFromInline
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
