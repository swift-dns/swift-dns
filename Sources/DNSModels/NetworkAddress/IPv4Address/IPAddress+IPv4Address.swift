extension IPv4Address {
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
        guard CIDR<IPv6Address>.ipv4Mapped.contains(ipv6) else {
            return nil
        }

        self.address = UInt32(truncatingIfNeeded: ipv6.address)
    }
}
