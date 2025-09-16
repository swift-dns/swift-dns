public import DNSCore

@available(swiftDNSApplePlatforms 15, *)
public struct CIDR<IPAddressType: _IPAddressProtocol>: Sendable, Hashable {

    /// The underlying type of the IP address.
    /// This is always either `UInt32` or `UInt128`.
    /// There is no need to assume any other type will be added in the future, as that would
    /// require a new IP version to be introduced, in which case it'll take years before that
    /// new IP version is adopted, and at that point we'll just have released a new major version.
    public typealias IntegerLiteralType = IPAddressType.IntegerLiteralType

    /// The IP address that is desired after the masking happens.
    /// Of type `IPv4Address` or `IPv6Address`.
    /// Example: in 127.0.0.1/8, the prefix is 127.0.0.0 (notice last segment is 0, not 1).
    /// in 0xFF00::/8, the prefix is 0xFF00::.
    public let prefix: IPAddressType
    /// The masked part of the address.
    /// Of type `UInt32` for `IPv4Address` or `UInt128` for `IPv6Address`.
    /// Example: in 127.0.0.1/8, the mask is the first 8 bits / the first segment of the IP.
    /// in 0xFF00::/8, the mask is the first 8 bits / the first 2 letters of the IP.
    /// That means in those 2 cases, the mask is an integer with 8 leading 1s and all the rest bits
    /// set to zeros. For example for IPv4 that'd be: `0b11111111_00000000_00000000_00000000`,
    /// which is equal to `127.0.0.0`.
    public let mask: IPAddressType

    @inlinable
    init(
        prefix: IPAddressType,
        uncheckedUnsafeMask mask: IPAddressType
    ) {
        self.prefix = IPAddressType(integerLiteral: prefix.address & mask.address)
        self.mask = mask
    }

    /// Create a new CIDR with the given prefix and mask.
    ///
    /// Examples:
    /// In 92.0.0.0/8, `92.0.0.0` is the prefix, and `0b11111111(24 zeros)` == `127.0.0.0` is the mask.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and `0b1111111111(118 zeros)` == `0xFFC0::` is the mask.
    ///
    /// - Parameters:
    ///   - prefix: The IP address that is desired after the masking happens.
    ///   - mask: The masked part of the address.
    @inlinable
    public init?(
        prefix: IPAddressType,
        mask: IPAddressType
    ) {
        /// Make sure the mask is "continuous" and has no leading zeros
        /// e.g. 0b11110000 is good, but 0b11110001 is not. 0b00001111 is not good either.
        guard
            Self.makeMaskBasedOn(
                uncheckedCountOfTrailingZeros: UInt8(mask.address.trailingZeroBitCount)
            ) == mask
        else {
            return nil
        }

        self.init(prefix: prefix, uncheckedUnsafeMask: mask)
    }

    /// Create a new CIDR with the given prefix and mask.
    ///
    /// Examples:
    /// In 92.0.0.0/8, `92.0.0.0` is the prefix, and `0b11111111(24 zeros)` == `127.0.0.0` is the mask.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and `0b1111111111(118 zeros)` == `0xFFC0::` is the mask.
    ///
    /// - Parameters:
    ///   - prefix: The IP address that is desired after the masking happens.
    ///     Extra bits that are not needed for the mask, will be truncated.
    ///     Example: 192.168.1.1/24 will be truncated to 192.168.1.0 since the trailing 1 is insignificant.
    ///   - uncheckedMask: The masked part of the address.
    ///     The mask will not be verified by the initializer in optimized builds, and MUST be
    ///     in a "continuous" form.
    ///     e.g. 0b11110000 is good, but 0b11110001 is not. 0b00001111 is not good either.
    ///     There must be only 1 group of leading ones and 1 group of trailing zeros.
    @inlinable
    public init(
        prefix: IPAddressType,
        uncheckedMask mask: IPAddressType
    ) {
        assert(
            Self.makeMaskBasedOn(
                uncheckedCountOfTrailingZeros: UInt8(mask.address.trailingZeroBitCount)
            ) == mask
        )

        self.init(prefix: prefix, uncheckedUnsafeMask: mask)
    }

    /// Create a new CIDR with the given prefix and count of masked bits.
    ///
    /// Examples:
    /// In 92.0.0.0/8, `92.0.0.0` is the prefix, and `0b11111111(24 zeros)` == `127.0.0.0` is the mask.
    /// In the example above, the prefix and mask are equal, but that's not always the case.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and `0b1111111111(118 zeros)` == `0xFFC0::` is the mask.
    ///
    /// - Parameters:
    ///   - prefix: The IP address that is desired after the masking happens.
    ///     Extra bits that are not needed for the mask, will be truncated.
    ///     Example: 192.168.1.1/24 will be truncated to 192.168.1.0 since the trailing 1 is insignificant.
    ///   - countOfMaskedBits: The number of leading bits to mask.
    ///     This shouldn't be greater than 32 for IPv4 or 128 for IPv6. The extra bits will be ignored.
    @inlinable
    public init(
        prefix: IPAddressType,
        countOfMaskedBits: UInt8
    ) {
        let mask = Self.makeMaskBasedOn(countOfMaskedBits: countOfMaskedBits)
        self.init(prefix: prefix, uncheckedUnsafeMask: mask)
    }

    /// Creates a number with `countOfMaskedBits` amount of leading 1s followed by all zeros.
    /// Parameters:
    ///   - countOfMaskedBits: The number of leading 1s to have, followed by all zeros.
    ///     Ignores amounts that are greater than the bit width of the IP address type,
    ///     which means 32 for IPv4 or 128 for IPv6.
    @inlinable
    package static func makeMaskBasedOn(countOfMaskedBits: UInt8) -> IPAddressType {
        let bitWidth = UInt8(IntegerLiteralType.bitWidth)
        if countOfMaskedBits >= bitWidth {
            return IPAddressType(integerLiteral: IntegerLiteralType.max)
        }
        let mask = ~(IntegerLiteralType.max &>>> countOfMaskedBits)
        return IPAddressType(integerLiteral: mask)
    }

    /// Makes a mask based on the number of trailing zeros.
    /// Parameters:
    ///   - countOfTrailingZeros: The number of trailing zeros to have.
    ///     This MUST NOT be greater than the bit width of `IntegerLiteralType`,
    ///     which means 32 for IPv4 or 128 for IPv6.
    @inlinable
    package static func makeMaskBasedOn(
        uncheckedCountOfTrailingZeros countOfTrailingZeros: UInt8
    ) -> IPAddressType {
        if countOfTrailingZeros == IntegerLiteralType.bitWidth {
            return 0
        } else {
            /// ~IntegerLiteralType((IntegerLiteralType(1) &<<< countOfTrailingZeros) &-- 1)
            /// also works. The compiler optimizes these anyway, so doesn't matter which
            /// one to use.
            let mask = (IntegerLiteralType.max &>>> countOfTrailingZeros) &<<< countOfTrailingZeros
            return IPAddressType(integerLiteral: mask)
        }
    }

    /// Whether or not the given IPAddress is within this CIDR.
    /// Complexity: O(1)
    @inlinable
    public func contains(_ other: IPAddressType) -> Bool {
        print(2, other)
        return other.address & self.mask.address == self.prefix.address
    }

    /// Whether or not the given IPAddress is within this CIDR.
    /// Complexity: O(1)
    @inlinable
    public func contains(_ other: IPAddress) -> Bool {
        guard let ip = IPAddressType(exactly: other) else {
            return false
        }
        return self.contains(ip)
    }
}
