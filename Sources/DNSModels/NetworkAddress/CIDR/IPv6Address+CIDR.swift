@available(swiftDNSApplePlatforms 15, *)
extension CIDR<IPv6Address> {
    /// Representing ::1/128
    @inlinable
    public static var loopback: Self {
        Self(
            prefix: 0x0000_0000_0000_0000_0000_0000_0000_0001,
            countOfMaskedBits: 128
        )
    }

    /// Representing FF00::/8
    @inlinable
    public static var multicast: Self {
        Self(
            prefix: 0xFF00_0000_0000_0000_0000_0000_0000_0000,
            countOfMaskedBits: 8
        )
    }

    /// Representing FE80::/10
    @inlinable
    public static var linkLocalUnicast: Self {
        Self(
            prefix: 0xFE80_0000_0000_0000_0000_0000_0000_0000,
            countOfMaskedBits: 10
        )
    }

@inlinable
    public static var ipv4Mapped: Self {
        Self(
            prefix: 0x0000_0000_0000_0000_0000_FFFF_0000_0000,
            countOfMaskedBits: 96
        )
    }
}
