/// An IPv4 address.
///
/// IPv4 addresses are defined as 32-bit integers in [IETF RFC 791].
/// They are usually represented as four bytes.
///
/// See [`IPAddress`] for a type encompassing both IPv4 and IPv6 addresses.
///
/// [IETF RFC 791]: https://tools.ietf.org/html/rfc791
///
/// # Textual representation
///
/// `IPv4Address` provides an initializer that accepts a string. The four bytes are in decimal
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

    /// The exact translation of an `IPAddress` to an `IPv4Address`.
    ///
    /// This does not handle ipv6-to-ipv4 mappings. Use `init?(ipv6:)` for that.
    @available(swiftDNSApplePlatforms 15, *)
    public init?(exactly ipAddress: IPAddress) {
        switch ipAddress {
        case .v4(let ipv4):
            self = ipv4
        case .v6:
            return nil
        }
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

extension IPv4Address: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt32) {
        self.address = value
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
