@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    /// The exact translation of an `IPAddress` to an `IPv4Address`.
    ///
    /// This does not handle ipv4-to-ipv6 mappings. Use `init(ipv4:)` for that.
    @available(swiftDNSApplePlatforms 15, *)
    public init?(exactly ipAddress: IPAddress) {
        switch ipAddress {
        case .v4:
            return nil
        case .v6(let ipv6):
            self = ipv6
        }
    }

    /// Maps an IPv4 address to an IPv6 address in the reserved address space by [RFC 4291, IP Version 6 Addressing Architecture, February 2006](https://datatracker.ietf.org/doc/rfc4291#section-2.5.5.2).
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
    @inlinable
    public init(ipv4: IPv4Address) {
        self.address = UInt128(ipv4.address)
        withUnsafeMutableBytes(of: &self.address) { ptr in
            ptr[4] = 0xFF
            ptr[5] = 0xFF
        }
    }
}
