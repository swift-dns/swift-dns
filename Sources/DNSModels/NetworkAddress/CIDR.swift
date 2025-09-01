@available(swiftDNSApplePlatforms 15, *)
/// FIXME: inline or specialize or whatever
public struct CIDR<IPAddressType: _IPAddressProtocol>: Sendable, Hashable {
    public let prefix: IPAddressType
    public let mask: IPAddressType.AddressType

    public typealias AddressType = IPAddressType.AddressType

    public init(
        prefix: IPAddressType,
        mask: IPAddressType.AddressType
    ) {
        /// Fix the prefix if it is not the same as the masked address.
        let masked = prefix.address & mask
        if masked != prefix.address {
            self.prefix = IPAddressType(integerLiteral: masked)
        } else {
            self.prefix = prefix
        }

        self.mask = mask
    }

    public init(
        uncheckedPrefix prefix: IPAddressType,
        mask: IPAddressType.AddressType
    ) {
        assert((prefix.address & mask) == prefix.address)

        self.prefix = prefix
        self.mask = mask
    }

    public init(
        prefix: IPAddressType,
        countOfMaskedBits: UInt8
    ) {
        precondition(countOfMaskedBits >= 0)
        precondition(countOfMaskedBits <= IPAddressType.AddressType.bitWidth)

        let mask: AddressType
        if countOfMaskedBits == AddressType.bitWidth {
            mask = .max
        } else {
            let one = AddressType.zero.advanced(by: 1)
            let bitWidth = UInt8(AddressType.bitWidth)
            let maskBits: AddressType = (one &<< countOfMaskedBits) - one
            let maskTrailingZeroCount = bitWidth - countOfMaskedBits
            mask = maskBits &<< maskTrailingZeroCount
        }

        self.init(prefix: prefix, mask: mask)
    }

    public init(
        uncheckedPrefix prefix: IPAddressType,
        countOfMaskedBits: UInt8
    ) {
        assert(countOfMaskedBits <= AddressType.bitWidth)

        let mask: AddressType
        if countOfMaskedBits == AddressType.bitWidth {
            mask = .max
        } else {
            let one = AddressType.zero.advanced(by: 1)
            let bitWidth = UInt8(AddressType.bitWidth)
            let maskBits: AddressType = (one &<< countOfMaskedBits) - one
            let maskTrailingZeroCount = bitWidth - countOfMaskedBits
            mask = maskBits &<< maskTrailingZeroCount
        }

        self.init(uncheckedPrefix: prefix, mask: mask)
    }

    public func contains(_ other: IPAddressType) -> Bool {
        other.address & self.mask == self.prefix.address
    }
}
