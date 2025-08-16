/// An IP address, either IPv4 or IPv6.
///
/// This enum can contain either an `IPv4Address` or an `IPv6Address`, see their
/// respective documentation for more details.
///
/// This enum is marked as indirect to avoid this issue:
/// https://github.com/swiftlang/swift/issues/83774
@available(swiftDNSApplePlatforms 15, *)
public indirect enum IPAddress: Sendable, Hashable {
    /// An IPv4 address.
    case v4(IPv4Address)
    /// An IPv6 address.
    case v6(IPv6Address)
}

@available(swiftDNSApplePlatforms 15, *)
extension IPAddress: CustomStringConvertible {
    public var description: String {
        switch self {
        case .v4(let ipv4):
            return ipv4.description
        case .v6(let ipv6):
            return ipv6.description
        }
    }
}

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

extension IPv4Address: CustomStringConvertible {
    public var description: String {
        var result: String = ""
        /// TODO: Smarter reserving capacity
        result.reserveCapacity(7)
        withUnsafeBytes(of: self.address) {
            for idx in 0..<4 {
                if idx > 0 {
                    result.append(".")
                }
                /// TODO: This can be optimized to not have to convert to a string
                result.append(String($0[idx]))
            }
        }
        return result
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
                    self.address |= UInt32(byte) &<< (8 &* (3 &- idx))
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
            let masked = shifted & 0xFF
            let byte = UInt8(exactly: masked).unsafelyUnwrapped
            buffer.writeInteger(byte)
        }
    }
}

/// An IPv6 address.
///
/// IPv6 addresses are defined as 128-bit integers in [IETF RFC 4291].
/// They are usually represented as eight 16-bit segments.
///
/// [IETF RFC 4291]: https://tools.ietf.org/html/rfc4291
///
/// # Embedding IPv4 Addresses
///
/// See [`IpAddr`] for a type encompassing both IPv4 and IPv6 addresses.
///
/// To assist in the transition from IPv4 to IPv6 two types of IPv6 addresses that embed an IPv4 address were defined:
/// IPv4-compatible and IPv4-mapped addresses. Of these IPv4-compatible addresses have been officially deprecated.
///
/// Both types of addresses are not assigned any special meaning by this implementation,
/// other than what the relevant standards prescribe. This means that an address like `::ffff:127.0.0.1`,
/// while representing an IPv4 loopback address, is not itself an IPv6 loopback address; only `::1` is.
/// To handle these so called "IPv4-in-IPv6" addresses, they have to first be converted to their canonical IPv4 address.
///
/// ### IPv4-Compatible IPv6 Addresses
///
/// IPv4-compatible IPv6 addresses are defined in [IETF RFC 4291 Section 2.5.5.1], and have been officially deprecated.
/// The RFC describes the format of an "IPv4-Compatible IPv6 address" as follows:
///
/// ```text
/// |                80 bits               | 16 |      32 bits        |
/// +--------------------------------------+--------------------------+
/// |0000..............................0000|0000|    IPv4 address     |
/// +--------------------------------------+----+---------------------+
/// ```
/// So `::a.b.c.d` would be an IPv4-compatible IPv6 address representing the IPv4 address `a.b.c.d`.
///
/// [IETF RFC 4291 Section 2.5.5.1]: https://datatracker.ietf.org/doc/html/rfc4291#section-2.5.5.1
///
/// ### IPv4-Mapped IPv6 Addresses
///
/// IPv4-mapped IPv6 addresses are defined in [IETF RFC 4291 Section 2.5.5.2].
/// The RFC describes the format of an "IPv4-Mapped IPv6 address" as follows:
///
/// ```text
/// |                80 bits               | 16 |      32 bits        |
/// +--------------------------------------+--------------------------+
/// |0000..............................0000|FFFF|    IPv4 address     |
/// +--------------------------------------+----+---------------------+
/// ```
/// So `::ffff:a.b.c.d` would be an IPv4-mapped IPv6 address representing the IPv4 address `a.b.c.d`.
///
/// [IETF RFC 4291 Section 2.5.5.2]: https://datatracker.ietf.org/doc/html/rfc4291#section-2.5.5.2
///
/// # Textual representation
///
/// `Ipv6Addr` provides a [`FromStr`] implementation. There are many ways to represent
/// an IPv6 address in text, but in general, each segments is written in hexadecimal
/// notation, and segments are separated by `:`. For more information, see
/// [IETF RFC 5952].
///
/// [IETF RFC 5952]: https://tools.ietf.org/html/rfc5952
@available(swiftDNSApplePlatforms 15, *)
public struct IPv6Address: Sendable, Hashable {
    @usableFromInline
    static var size: Int {
        16
    }

    public var address: UInt128

    public init(_ address: UInt128) {
        self.address = address
    }

    public init(
        _ _1: UInt16,
        _ _2: UInt16,
        _ _3: UInt16,
        _ _4: UInt16,
        _ _5: UInt16,
        _ _6: UInt16,
        _ _7: UInt16,
        _ _8: UInt16
    ) {
        /// Broken into 2 steps so compiler is happy
        self.address =
            (UInt128(_1) &<< 112)
            | (UInt128(_2) &<< 96)
            | (UInt128(_3) &<< 80)
            | (UInt128(_4) &<< 64)
        self.address =
            self.address
            | (UInt128(_5) &<< 48)
            | (UInt128(_6) &<< 32)
            | (UInt128(_7) &<< 16)
            | UInt128(_8)
    }

    public init(
        _ _1: UInt8,
        _ _2: UInt8,
        _ _3: UInt8,
        _ _4: UInt8,
        _ _5: UInt8,
        _ _6: UInt8,
        _ _7: UInt8,
        _ _8: UInt8,
        _ _9: UInt8,
        _ _10: UInt8,
        _ _11: UInt8,
        _ _12: UInt8,
        _ _13: UInt8,
        _ _14: UInt8,
        _ _15: UInt8,
        _ _16: UInt8
    ) {
        self.address =
            (UInt128(_1) &<< 120)
            | (UInt128(_2) &<< 112)
        self.address =
            self.address
            | (UInt128(_3) &<< 104)
            | (UInt128(_4) &<< 96)
        self.address =
            self.address
            | (UInt128(_5) &<< 88)
            | (UInt128(_6) &<< 80)
        self.address =
            self.address
            | (UInt128(_7) &<< 72)
            | (UInt128(_8) &<< 64)
        self.address =
            self.address
            | (UInt128(_9) &<< 56)
            | (UInt128(_10) &<< 48)
        self.address =
            self.address
            | (UInt128(_11) &<< 40)
            | (UInt128(_12) &<< 32)
        self.address =
            self.address
            | (UInt128(_13) &<< 24)
            | (UInt128(_14) &<< 16)
        self.address =
            self.address
            | (UInt128(_15) &<< 8)
            | UInt128(_16)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address: CustomStringConvertible {
    public var description: String {
        /// FIXME: use proper formatting, e.g. using `::`.
        var result: String = ""
        result.reserveCapacity(39)
        for idx in 0..<8 {
            if idx > 0 {
                result.append(":")
            }
            let shift = 8 &* (14 &- idx)
            let shifted = self.address &>> shift
            let masked = shifted & 0xFFFF
            let string = String(masked, radix: 16, uppercase: false)
            result.append(string)
        }
        return result
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    package init(from buffer: inout DNSBuffer) throws {
        self.address = try buffer.readInteger(as: UInt128.self).unwrap(
            or: .failedToRead("IPv6Address", buffer)
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
                    self.address |= UInt128(byte) &<< (8 &* (15 &- idx))
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
            let shift = 8 &* (15 &- idx)
            let shifted = self.address &>> shift
            let masked = shifted & 0xFF
            let byte = UInt8(exactly: masked).unsafelyUnwrapped
            buffer.writeInteger(byte)
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    func makeCompactDescriptionIterator() -> CompactDescriptionIterator {
        CompactDescriptionIterator(base: self)
    }

    /// [RFC 5952, A Recommendation for IPv6 Address Text Representation]: https://tools.ietf.org/html/rfc5952
    struct CompactDescriptionIterator: IteratorProtocol {
        let base: IPv6Address
        // var state: State

        mutating func next() -> String? {
            nil
        }
    }
}
