/// An IP address, either IPv4 or IPv6.
///
/// This enum can contain either an [`Ipv4Addr`] or an [`Ipv6Addr`], see their
/// respective documentation for more details.
@available(macOS 9999, *)
public enum IPAddress {
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
@available(macOS 9999, *)
public struct IPv4Address {
    public let octets: InlineArray<4, UInt8>
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
@available(macOS 9999, *)
public struct IPv6Address {
    public let octets: InlineArray<16, UInt8>
}
