@available(swiftDNSApplePlatforms 15, *)
/// FIXME: inline or specialize or whatever
public struct CIDR<IPAddressType: _IPAddressProtocol>: Sendable, Hashable {

    /// The underlying type of the IP address.
    public typealias IntegerLiteralType = IPAddressType.IntegerLiteralType

    /// The IP address that is desired after the masking happens.
    /// Example: in 127.0.0.1/8, the prefix is 127.0.0.0 (notice last segment is 0, not 1).
    /// in 0xFF00::/8, the prefix is 0xFF00::.
    public let prefix: IPAddressType
    /// The masked part of the address.
    /// Example: in 127.0.0.1/8, the mask is the first 8 bits / the first segment of the IP
    /// in 0xFF00::/8, the mask is the first 8 bits / the first segment of the IP
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
    public init(
        prefix: IPAddressType,
        mask: IntegerLiteralType
    ) {
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
    ///   - countOfMaskedBits: The number of leading bits to mask.
    public init(
        prefix: IPAddressType,
        countOfMaskedBits: UInt8
    ) {
        precondition(countOfMaskedBits <= IntegerLiteralType.bitWidth)

        let mask: IntegerLiteralType
        if countOfMaskedBits == IntegerLiteralType.bitWidth {
            mask = .max
        } else {
            let one = IntegerLiteralType.zero.advanced(by: 1)
            let bitWidth = UInt8(IntegerLiteralType.bitWidth)
            let maskBits: IntegerLiteralType = (one &<< countOfMaskedBits) - one
            let maskTrailingZeroCount = bitWidth - countOfMaskedBits
            mask = maskBits &<< maskTrailingZeroCount
        }

        self.init(prefix: prefix, mask: mask)
    }

    /// Whether or not the given IPAddress is within this CIDR.
    public func contains(_ other: IPAddressType) -> Bool {
        other.address & self.mask == self.prefix.address
    }

    /// Whether or not the given IPAddress is within this CIDR.
    public func contains(_ other: IPAddress) -> Bool {
        switch IntegerLiteralType.bitWidth {
        /// IPv4
        case 32:
            switch other {
            case .v4(let ipv4):
                return self.contains(ipv4 as! IPAddressType)
            case .v6:
                return false
            }
        /// IPv6
        case 128:
            switch other {
            case .v4:
                return false
            case .v6(let ipv6):
                return self.contains(ipv6 as! IPAddressType)
            }
        default:
            fatalError("Unsupported IP address type")
        }
    }
}
