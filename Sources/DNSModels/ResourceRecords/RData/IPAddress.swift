package import struct NIOCore.ByteBuffer

/// An IP address, either IPv4 or IPv6.
///
/// This enum can contain either an [`Ipv4Addr`] or an [`Ipv6Addr`], see their
/// respective documentation for more details.
public enum IPAddress: Sendable, Hashable {
    /// An IPv4 address.
    case v4(IPv4Address)
    /// An IPv6 address.
    case v6(IPv6Address)
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
public struct IPv4Address: Sendable {
    @inlinable
    static var size: Int {
        4
    }

    public var bytes: InlineArray<4, UInt8>

    public init(bytes: InlineArray<4, UInt8>) {
        self.bytes = bytes
    }
}

extension IPv4Address: Equatable {
    public static func == (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
        /// TODO: use memcmp or span, whenever InlineArray supports those
        /// https://github.com/swiftlang/swift/issues/81072#event-17584092368
        for idx in lhs.bytes.indices {
            if lhs.bytes[unchecked: idx] != rhs.bytes[unchecked: idx] {
                return false
            }
        }
        return true
    }
}

extension IPv4Address: Hashable {
    public func hash(into hasher: inout Hasher) {
        /// FIXME: optimize writing bytes
        for idx in self.bytes.indices {
            hasher.combine(self.bytes[idx])
        }
    }
}

extension IPv4Address: CustomStringConvertible {
    public var description: String {
        var result: String = ""
        result.reserveCapacity(15)
        for idx in self.bytes.indices {
            if idx > 0 {
                result.append(".")
            }
            result.append(String(self.bytes[unchecked: idx]))
        }
        return result
    }
}

extension IPv4Address {
    package init(from buffer: inout ByteBuffer) throws {
        self.bytes =
            try buffer.readInlineArray()
            ?? {
                throw ProtocolError.failedToRead("IPv4Address", buffer)
            }()
    }

    package init(from buffer: inout ByteBuffer, addressLength: Int) throws {
        self.bytes = try InlineArray<4, UInt8> { idx in
            switch idx < addressLength {
            case true:
                /// TODO: optimize reading bytes
                return try buffer.readInteger(as: UInt8.self)
                    ?? {
                        throw ProtocolError.failedToRead("IPv4Address", buffer)
                    }()
            case false:
                return 0
            }
        }
    }
}

extension IPv4Address {
    package func encode(into buffer: inout ByteBuffer) {
        /// TODO: optimize writing bytes
        buffer.writeBytes(self.bytes)
    }

    package func encode(into buffer: inout ByteBuffer, addressLength: Int) {
        for idx in 0..<addressLength {
            guard idx < addressLength else {
                return
            }
            /// TODO: optimize writing bytes
            buffer.writeInteger(self.bytes[idx])
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
public struct IPv6Address: Sendable {
    @inlinable
    static var size: Int {
        16
    }

    public var bytes: InlineArray<16, UInt8>

    public init(bytes: InlineArray<16, UInt8>) {
        self.bytes = bytes
    }
}

extension IPv6Address: Equatable {
    public static func == (lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        /// TODO: use memcmp or span, whenever InlineArray supports those
        /// https://github.com/swiftlang/swift/issues/81072#event-17584092368
        for idx in lhs.bytes.indices {
            if lhs.bytes[unchecked: idx] != rhs.bytes[unchecked: idx] {
                return false
            }
        }
        return true
    }
}

extension IPv6Address: Hashable {
    public func hash(into hasher: inout Hasher) {
        /// FIXME: optimize writing bytes
        for idx in self.bytes.indices {
            hasher.combine(self.bytes[idx])
        }
    }
}

extension IPv6Address: CustomStringConvertible {
    public var description: String {
        /// FIXME: use proper formatting, e.g. using `::`.
        var result: String = ""
        result.reserveCapacity(39)
        for idx in self.bytes.indices {
            if idx > 0 {
                result.append(":")
            }
            result.append(String(self.bytes[unchecked: idx], radix: 16))
        }
        return result
    }
}

extension IPv6Address {
    package init(from buffer: inout ByteBuffer) throws {
        self.bytes =
            try buffer.readInlineArray()
            ?? {
                throw ProtocolError.failedToRead("IPv6Address", buffer)
            }()
    }

    package init(from buffer: inout ByteBuffer, addressLength: Int) throws {
        self.bytes = try InlineArray<16, UInt8> { idx in
            switch idx < addressLength {
            case true:
                /// TODO: optimize reading bytes
                return try buffer.readInteger(as: UInt8.self)
                    ?? {
                        throw ProtocolError.failedToRead("IPv4Address", buffer)
                    }()
            case false:
                return 0
            }
        }
    }
}

extension IPv6Address {
    package func encode(into buffer: inout ByteBuffer) {
        /// TODO: optimize writing bytes
        buffer.writeBytes(self.bytes)
    }

    package func encode(into buffer: inout ByteBuffer, addressLength: Int) {
        for idx in 0..<addressLength {
            guard idx < addressLength else {
                return
            }
            /// TODO: optimize writing bytes
            buffer.writeInteger(self.bytes[idx])
        }
    }
}
