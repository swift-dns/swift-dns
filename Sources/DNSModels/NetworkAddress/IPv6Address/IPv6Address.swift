public import DNSCore

/// An IPv6 address.
///
/// IPv6 addresses are defined as 128-bit integers in [IETF RFC 4291].
/// They are usually represented as eight 16-bit segments.
///
/// [IETF RFC 4291]: https://tools.ietf.org/html/rfc4291
///
/// # Embedding IPv4 Addresses
///
/// See [`IPAddress`] for a type encompassing both IPv4 and IPv6 addresses.
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
/// `IPv6Address` provides an initializer that accepts a string. There are many ways to represent
/// an IPv6 address in text, but in general, each segments is written in hexadecimal
/// notation, and segments are separated by `:`. For more information, see
/// [IETF RFC 5952].
///
/// [IETF RFC 5952]: https://tools.ietf.org/html/rfc5952
@available(swiftDNSApplePlatforms 15, *)
public struct IPv6Address: Sendable, Hashable, _IPAddressProtocol {
    /// The byte size of an IPv6.
    @usableFromInline
    static var size: Int {
        16
    }

    /// The underlying 128 bits (16 bytes) representing this IPv6 address.
    public var address: UInt128

    /// Whether this address is the IPv6 Loopback address, known as localhost, or not.
    /// Equivalent to `::1` or `0:0:0:0:0:0:0:1` in IPv6 description format.
    @inlinable
    public var isLoopback: Bool {
        CIDR<Self>.loopback.contains(self)
    }

    /// Whether this address is an IPv6 Multicast address, or not.
    /// Equivalent to `FF00::/120` in CIDR notation.
    /// That is, any IPv6 address starting with this sequence of bits: `11111111`.
    /// In other words, any IPv6 address starting with `FFxx`. This does not include an address like
    /// `FF::` which is equivalent to `00FF::` and does not start with `FF`.
    @inlinable
    public var isMulticast: Bool {
        CIDR<Self>.multicast.contains(self)
    }

    /// Whether this address is an IPv6 Link Local Unicast address, or not.
    /// Equivalent to `FE80::/10` in CIDR notation.
    /// That is, any IPv6 address starting with this sequence of bits: `1111111010`.
    @inlinable
    public var isLinkLocalUnicast: Bool {
        CIDR<Self>.linkLocalUnicast.contains(self)
    }

    /// Initialize an `IPv6Address` from its raw 128-bit unsigned integer representation.
    public init(_ address: UInt128) {
        self.address = address
    }

    /// Initialize an IPv6 from the 8 16-bits (2-bytes) representing it.
    /// For example `IPv6Address(0x0102, 0x0304, 0x0506, 0x0708, 0x090A, 0x0B0C, 0x0D0E, 0x0F10)`
    /// will result in an IP address equal to `0102:0304:0506:0708:090A:0B0C:0D0E:0F10`.
    @inlinable
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
        self.address = 0
        withUnsafeMutableBytes(of: &self.address) { ptr in
            ptr[15] = UInt8(_1 &>>> 8)
            ptr[14] = UInt8(truncatingIfNeeded: _1)
            ptr[13] = UInt8(_2 &>>> 8)
            ptr[12] = UInt8(truncatingIfNeeded: _2)
            ptr[11] = UInt8(_3 &>>> 8)
            ptr[10] = UInt8(truncatingIfNeeded: _3)
            ptr[9] = UInt8(_4 &>>> 8)
            ptr[8] = UInt8(truncatingIfNeeded: _4)
            ptr[7] = UInt8(_5 &>>> 8)
            ptr[6] = UInt8(truncatingIfNeeded: _5)
            ptr[5] = UInt8(_6 &>>> 8)
            ptr[4] = UInt8(truncatingIfNeeded: _6)
            ptr[3] = UInt8(_7 &>>> 8)
            ptr[2] = UInt8(truncatingIfNeeded: _7)
            ptr[1] = UInt8(_8 &>>> 8)
            ptr[0] = UInt8(truncatingIfNeeded: _8)
        }
    }

    /// Initialize an IPv6 from the 16 bytes representing it.
    /// For example `IPv6Address(0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10)`
    /// will result in an IP address equal to `0102:0304:0506:0708:090A:0B0C:0D0E:0F10`.
    @inlinable
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
        self.address = 0
        withUnsafeMutableBytes(of: &self.address) { ptr in
            ptr[15] = _1
            ptr[14] = _2
            ptr[13] = _3
            ptr[12] = _4
            ptr[11] = _5
            ptr[10] = _6
            ptr[9] = _7
            ptr[8] = _8
            ptr[7] = _9
            ptr[6] = _10
            ptr[5] = _11
            ptr[4] = _12
            ptr[3] = _13
            ptr[2] = _14
            ptr[1] = _15
            ptr[0] = _16
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    /// The 16 bytes representing this IPv6 address.
    @inlinable
    public var bytes:
        (
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
        )
    {
        withUnsafeBytes(of: self.address) { ptr in
            (
                ptr[15], ptr[14], ptr[13], ptr[12], ptr[11], ptr[10], ptr[9], ptr[8],
                ptr[7], ptr[6], ptr[5], ptr[4], ptr[3], ptr[2], ptr[1], ptr[0]
            )
        }
    }

    /// The 8 16-bits (2-bytes) representing this IPv6 address.
    /// The same as 8-segments / groups divided by colons (`:`) in the textual representation.
    @inlinable
    public var bytePairs:
        (
            UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16
        )
    {
        withUnsafeBytes(of: self.address) { ptr in
            (
                UInt16(ptr[15]) &<<< 8 | UInt16(ptr[14]),
                UInt16(ptr[13]) &<<< 8 | UInt16(ptr[12]),
                UInt16(ptr[11]) &<<< 8 | UInt16(ptr[10]),
                UInt16(ptr[9]) &<<< 8 | UInt16(ptr[8]),
                UInt16(ptr[7]) &<<< 8 | UInt16(ptr[6]),
                UInt16(ptr[5]) &<<< 8 | UInt16(ptr[4]),
                UInt16(ptr[3]) &<<< 8 | UInt16(ptr[2]),
                UInt16(ptr[1]) &<<< 8 | UInt16(ptr[0])
            )
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address: ExpressibleByIntegerLiteral {
    /// Initialize an `IPv6Address` from its raw 128-bit unsigned integer representation.
    public init(integerLiteral value: UInt128) {
        self.address = value
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
