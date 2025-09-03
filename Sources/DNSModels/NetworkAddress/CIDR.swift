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
    /// Example: in 127.0.0.1/8, the mask is the first 8 bits / the first segment of the IP
    /// in 0xFF00::/8, the mask is the first 8 bits / the first 2 letters of the IP
    ///
    /// FIXME: should we store `countOfMaskedBits` for the smaller footprint?
    public let mask: IntegerLiteralType

    /// Create a new CIDR with the given prefix and mask.
    ///
    /// Examples:
    /// In 127.0.0.1/8, `127.0.0.0` is the prefix, and `0b11111111(24 zeros)` == `127.0.0.0` is the mask.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and `0b1111111111(118 zeros)` == `0xFFC0::` is the mask.
    ///
    /// - Parameters:
    ///   - prefix: The IP address that is desired after the masking happens.
    ///   - mask: The masked part of the address.
    @inlinable
    public init?(
        prefix: IPAddressType,
        mask: IntegerLiteralType
    ) {
        /// Make sure the mask is "continuous" and has no leading zeros
        /// e.g. 0b11110000 is good, but 0b11110001 is not. 0b00001111 is not good either.
        guard mask.leadingZeroBitCount == 0,
            Self.makeMaskBasedOn(
                countOfMaskedBits: UInt8(
                    IntegerLiteralType.bitWidth - mask.trailingZeroBitCount
                )
            ) == mask
        else {
            return nil
        }

        self.prefix = IPAddressType(integerLiteral: prefix.address & mask)
        self.mask = mask
    }

    /// Create a new CIDR with the given prefix and mask.
    ///
    /// Examples:
    /// In 127.0.0.1/8, `127.0.0.0` is the prefix, and `0b11111111(24 zeros)` == `127.0.0.0` is the mask.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and `0b1111111111(118 zeros)` == `0xFFC0::` is the mask.
    ///
    /// - Parameters:
    ///   - prefix: The IP address that is desired after the masking happens.
    ///     Extra bits that are not needed for the mask, will be truncated.
    ///     Example: 192.168.1.1/24 will be truncated to 192.168.1.0 since the trailing 1 is insignificant.
    ///   - uncheckedMask: The masked part of the address.
    ///     The mask will not be verified by the initializer but MUST be in a "continuous" form.
    ///     e.g. 0b11110000 is good, but 0b11110001 is not. 0b00001111 is not good either.
    ///     There must be only 1 group of leading ones and 1 group of trailing zeros.
    ///     Also there must be no leading zeros in the mask.
    @inlinable
    public init(
        prefix: IPAddressType,
        uncheckedMask mask: IntegerLiteralType
    ) {
        assert(
            mask.leadingZeroBitCount == 0
                && Self.makeMaskBasedOn(
                    countOfMaskedBits: UInt8(
                        IntegerLiteralType.bitWidth - mask.trailingZeroBitCount
                    )
                ) == mask
        )

        self.prefix = IPAddressType(integerLiteral: prefix.address & mask)
        self.mask = mask
    }

    /// Create a new CIDR with the given prefix and count of masked bits.
    ///
    /// Examples:
    /// In 127.0.0.1/8, `127.0.0.0` is the prefix, and 8 is the count of masked bits.
    /// In 0xFE80::/10, `0xFE80::` is the prefix, and 10 is the count of masked bits.
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
        self.init(prefix: prefix, uncheckedMask: mask)
    }

    /// Ignores bits that are greater than the bit width of the IP address type.
    @inlinable
    static func makeMaskBasedOn(countOfMaskedBits: UInt8) -> IntegerLiteralType {
        let mask: IntegerLiteralType
        if countOfMaskedBits >= IntegerLiteralType.bitWidth {
            mask = .max
        } else {
            let one = IntegerLiteralType.zero.advanced(by: 1)
            let bitWidth = UInt8(IntegerLiteralType.bitWidth)
            let maskBits: IntegerLiteralType = (one &<< countOfMaskedBits) - one
            let maskTrailingZeroCount = bitWidth - countOfMaskedBits
            mask = maskBits &<< maskTrailingZeroCount
        }
        return mask
    }

    /// Whether or not the given IPAddress is within this CIDR.
    @inlinable
    public func contains(_ other: IPAddressType) -> Bool {
        other.address & self.mask == self.prefix.address
    }

    /// Whether or not the given IPAddress is within this CIDR.
    @inlinable
    public func contains(_ other: IPAddress) -> Bool {
        guard let ip = IPAddressType(exactly: other) else {
            return false
        }
        return self.contains(ip)
    }
}
