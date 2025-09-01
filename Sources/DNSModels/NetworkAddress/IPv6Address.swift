import SwiftIDNA

/// An IPv6 address.
///
/// IPv6 addresses are defined as 128-bit integers in [IETF RFC 4291].
/// They are usually represented as eight 16-bit segments.
///
/// [IETF RFC 4291]: https://tools.ietf.org/html/rfc4291
///
/// # Embedding IPv4 Addresses
///
/// See [`IPAddress`] for a type encompassing both IPv4 and IPv6 addresses.
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
/// `IPv6Address` provides an initializer that accepts a string. There are many ways to represent
/// an IPv6 address in text, but in general, each segments is written in hexadecimal
/// notation, and segments are separated by `:`. For more information, see
/// [IETF RFC 5952].
///
/// [IETF RFC 5952]: https://tools.ietf.org/html/rfc5952
@available(swiftDNSApplePlatforms 15, *)
public struct IPv6Address: Sendable, Hashable, _IPAddressProtocol {
    /// The byte size of an IPv6.
    @usableFromInline
    static var size: Int {
        16
    }

    /// The underlying 128 bits (16 bytes) representing this IPv6 address.
    public var address: UInt128

    /// Whether this address is the IPv6 Loopback address, known as localhost, or not.
    /// Equivalent to `::1` or `0:0:0:0:0:0:0:1` in IPv6 description format.
    @inlinable
    public var isLoopback: Bool {
        CIDR<Self>.loopback.contains(self)
    }

    /// Whether this address is an IPv6 Multicast address, or not.
    /// Equivalent to `FF00::/120` in CIDR notation.
    /// That is, any IPv6 address starting with this sequence of bits: `11111111`.
    /// In other words, any IPv6 address starting with `FFxx`. This does not include an address like
    /// `FF::` which is equivalent to `00FF::` and does not start with `FF`.
    @inlinable
    public var isMulticast: Bool {
        CIDR<Self>.multicast.contains(self)
    }

    /// Whether this address is an IPv6 Link Local Unicast address, or not.
    /// Equivalent to `FE80::/10` in CIDR notation.
    /// That is, any IPv6 address starting with this sequence of bits: `1111111010`.
    @inlinable
    public var isLinkLocalUnicast: Bool {
        CIDR<Self>.linkLocalUnicast.contains(self)
    }

    public init(_ address: UInt128) {
        self.address = address
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

    /// Directly construct an IPv6 from the 8 16-bits (2-bytes) representing it.
    /// Example: `IPv6Address(0x0102, 0x0304, 0x0506, 0x0708, 0x090A, 0x0B0C, 0x0D0E, 0x0F10)`
    /// That is equivalent to this UInt128: `0x0102_0304_0506_0708_090A_0B0C_0D0E_0F10`.
    @inlinable
    public init(
        _ _1: UInt16,
        _ _2: UInt16,
        _ _3: UInt16,
        _ _4: UInt16,
        _ _5: UInt16,
        _ _6: UInt16,
        _ _7: UInt16,
        _ _8: UInt16
    ) {
        self.address = 0
        withUnsafeMutableBytes(of: &self.address) { ptr in
            ptr[15] = UInt8(_1 &>> 8)
            ptr[14] = UInt8(truncatingIfNeeded: _1)
            ptr[13] = UInt8(_2 &>> 8)
            ptr[12] = UInt8(truncatingIfNeeded: _2)
            ptr[11] = UInt8(_3 &>> 8)
            ptr[10] = UInt8(truncatingIfNeeded: _3)
            ptr[9] = UInt8(_4 &>> 8)
            ptr[8] = UInt8(truncatingIfNeeded: _4)
            ptr[7] = UInt8(_5 &>> 8)
            ptr[6] = UInt8(truncatingIfNeeded: _5)
            ptr[5] = UInt8(_6 &>> 8)
            ptr[4] = UInt8(truncatingIfNeeded: _6)
            ptr[3] = UInt8(_7 &>> 8)
            ptr[2] = UInt8(truncatingIfNeeded: _7)
            ptr[1] = UInt8(_8 &>> 8)
            ptr[0] = UInt8(truncatingIfNeeded: _8)
        }
    }

    /// Directly construct an IPv6 from the 16 bytes representing it.
    /// Example: `IPv6Address(0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10)`
    /// That is equivalent to this UInt128: `0x0102_0304_0506_0708_090A_0B0C_0D0E_0F10`.
    @inlinable
    public init(
        _ _1: UInt8,
        _ _2: UInt8,
        _ _3: UInt8,
        _ _4: UInt8,
        _ _5: UInt8,
        _ _6: UInt8,
        _ _7: UInt8,
        _ _8: UInt8,
        _ _9: UInt8,
        _ _10: UInt8,
        _ _11: UInt8,
        _ _12: UInt8,
        _ _13: UInt8,
        _ _14: UInt8,
        _ _15: UInt8,
        _ _16: UInt8
    ) {
        self.address = 0
        withUnsafeMutableBytes(of: &self.address) { ptr in
            ptr[15] = _1
            ptr[14] = _2
            ptr[13] = _3
            ptr[12] = _4
            ptr[11] = _5
            ptr[10] = _6
            ptr[9] = _7
            ptr[8] = _8
            ptr[7] = _9
            ptr[6] = _10
            ptr[5] = _11
            ptr[4] = _12
            ptr[3] = _13
            ptr[2] = _14
            ptr[1] = _15
            ptr[0] = _16
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    /// The 16 bytes representing this IPv6 address.
    @inlinable
    public var bytes:
        (
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
        )
    {
        withUnsafeBytes(of: self.address) { ptr in
            (
                ptr[15], ptr[14], ptr[13], ptr[12], ptr[11], ptr[10], ptr[9], ptr[8],
                ptr[7], ptr[6], ptr[5], ptr[4], ptr[3], ptr[2], ptr[1], ptr[0]
            )
        }
    }

    /// The 8 16-bits (2-bytes) representing this IPv6 address.
    @inlinable
    public var bytePairs:
        (
            UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16
        )
    {
        withUnsafeBytes(of: self.address) { ptr in
            (
                UInt16(ptr[15]) &<< 8 | UInt16(ptr[14]),
                UInt16(ptr[13]) &<< 8 | UInt16(ptr[12]),
                UInt16(ptr[11]) &<< 8 | UInt16(ptr[10]),
                UInt16(ptr[9]) &<< 8 | UInt16(ptr[8]),
                UInt16(ptr[7]) &<< 8 | UInt16(ptr[6]),
                UInt16(ptr[5]) &<< 8 | UInt16(ptr[4]),
                UInt16(ptr[3]) &<< 8 | UInt16(ptr[2]),
                UInt16(ptr[1]) &<< 8 | UInt16(ptr[0])
            )
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt128) {
        self.address = value
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address: CustomStringConvertible {
    /// The textual representation of an IPv6 address.
    /// That is, 8 16-bits (2-bytes) separated by `:`, enclosed in `[]`, while using
    /// the compression sign (`::`) when possible.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://tools.ietf.org/html/rfc5952).
    ///
    /// This implementation is IDNA compliant as well.
    /// That means the following addresses are considered equal:
    /// `﹇₂₀₀₁︓₀ⒹⒷ₈︓₈₅Ⓐ₃︓Ⓕ₁₀₉︓₁₉₇Ⓐ︓₈Ⓐ₂Ⓔ︓₀₃₇₀︓₇₃₃₄﹈`
    /// `[2001:db8:85a3:f109:197a:8a2e:370:7334]`
    @inlinable
    public var description: String {
        /// Short-circuit "0".
        if self.address == 0 {
            return "[::]"
        }

        return withUnsafeBytes(of: self.address) { ptr in
            func isZero(octalIdx idx: Int) -> Bool {
                let doubled = idx &* 2
                return ptr[15 &- doubled] == 0 && ptr[14 &- doubled] == 0
            }
            var rangeToCompress: Range<Int>? = nil
            var idx = 0
            /// idx < `7` instead of `8` because even if 7 is a zero it'll be a lone zero and
            /// we won't compress it anyway.
            while idx < 7 {
                guard isZero(octalIdx: idx) else {
                    idx &+= 1
                    continue
                }

                var endIndex = idx

                /// This range is guaranteed to be non-empty because we know idx < 7 (6 max)
                /// and (6+1)..<8 is still a range with 1 number in it.
                for nextIdx in (idx + 1)..<8 {
                    guard isZero(octalIdx: nextIdx) else {
                        break
                    }
                    endIndex = nextIdx
                }

                if endIndex != idx {
                    /// If a `rangeToCompress` already exists and is not smaller than the new range,
                    /// then don't do anything.
                    /// Otherwise use the `newRange` as the `rangeToCompress`.
                    let newRange = idx..<endIndex
                    if let existingRange = rangeToCompress {
                        if existingRange.count < newRange.count {
                            rangeToCompress = newRange
                        }
                    } else {
                        rangeToCompress = newRange
                    }
                }

                idx = endIndex &+ 1
            }

            assert(rangeToCompress?.isEmpty != true)

            var result = "["
            /// Reserve the max possibly needed capacity.
            let toReserve: Int
            if let rangeToCompress {
                let segmentsCount = 8 &- rangeToCompress.count
                let colonsCount = max(segmentsCount &- 1, 2)
                let bracketsCount = 2
                toReserve = bracketsCount &+ colonsCount &+ (segmentsCount &* 4)
            } else {
                toReserve = 41
            }
            result.reserveCapacity(toReserve)

            func uint16(octalIdx idx: Int) -> UInt16 {
                let doubled = idx &* 2
                let left = UInt16(ptr[15 &- doubled]) &<< 8
                let right = UInt16(ptr[14 &- doubled])
                return left | right
            }

            /// Reset `idx`. It was used in a loop above.
            idx = 0
            while idx < 8 {
                if let rangeToCompress,
                    idx == rangeToCompress.lowerBound
                {
                    if idx == 0 {
                        result.append("::")
                    } else {
                        result.append(":")
                    }
                    idx = rangeToCompress.upperBound &+ 1
                    continue
                }

                let uint16 = uint16(octalIdx: idx)
                let string = String(uint16, radix: 16, uppercase: false)
                result.append(string)
                if idx < 7 {
                    result.append(":")
                }

                idx &+= 1
            }

            result += "]"

            return result
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        var addressLhs: UInt128 = 0
        var addressRhs: UInt128 = 0

        let scalars = description.unicodeScalars

        var startIndex = scalars.startIndex
        var endIndex = scalars.endIndex

        let startsWithBracket =
            (scalars.first).map({
                IPv6Address.isIDNAEquivalent(
                    to: .asciiLeftSquareBracket,
                    scalar: $0
                )
            }) == true
        let endsWithBracket =
            (scalars.last).map({
                IPv6Address.isIDNAEquivalent(
                    to: .asciiRightSquareBracket,
                    scalar: $0
                )
            }) == true

        switch (startsWithBracket, endsWithBracket) {
        case (true, true):
            startIndex = scalars.index(after: startIndex)
            endIndex = scalars.index(before: endIndex)
        case (false, false):
            break
        case (true, false), (false, true):
            return nil
        }

        guard scalars.count > 1 else {
            return nil
        }

        let lastIndex = scalars.index(before: endIndex)
        var chunkStartIndex = startIndex

        var groupIdx = 0
        /// Have seen '::' or not
        var seenCompressionSign = false
        while let nextSeparatorIdx = scalars[chunkStartIndex..<endIndex].firstIndex(
            where: { IPv6Address.isIDNAEquivalent(to: .asciiColon, scalar: $0) }
        ) {
            let scalarsGroup = scalars[chunkStartIndex..<nextSeparatorIdx]
            if scalarsGroup.isEmpty {
                if seenCompressionSign {
                    /// We've already seen a compression sign, so this is invalid
                    return nil
                }

                /// If we're at the first index
                if nextSeparatorIdx == startIndex {
                    let nextIdx = scalars.index(after: nextSeparatorIdx)

                    guard
                        IPv6Address.isIDNAEquivalent(
                            to: .asciiColon,
                            scalar: scalars[nextIdx]
                        )
                    else {
                        return nil
                    }

                    seenCompressionSign = true
                    chunkStartIndex = scalars.index(after: nextIdx)
                    continue

                    /// If we're at the last index
                } else if nextSeparatorIdx == lastIndex {
                    guard groupIdx <= 7 else {
                        return nil
                    }
                    /// Must have reached end with no rhs
                    self.init(addressLhs)
                    return
                } else {
                    guard
                        IPv6Address.isIDNAEquivalent(
                            to: .asciiColon,
                            scalar: scalars[scalars.index(before: nextSeparatorIdx)]
                        )
                    else {
                        return nil
                    }

                    seenCompressionSign = true
                    chunkStartIndex = scalars.index(after: nextSeparatorIdx)
                    continue
                }
            }

            /// TODO: Don't go through an String conversion here
            guard
                let group = IPv6Address.mapToHexadecimalDigitsBasedOnIDNA(scalarsGroup),
                let byte = UInt16(String(group), radix: 16)
            else {
                return nil
            }

            if seenCompressionSign {
                addressRhs |= UInt128(byte) &<< (16 &* (7 &- groupIdx))
            } else {
                addressLhs |= UInt128(byte) &<< (16 &* (7 &- groupIdx))
            }

            chunkStartIndex = scalars.index(after: nextSeparatorIdx)

            groupIdx &+= 1
        }

        let compressionSignFactor = seenCompressionSign ? 1 : 0
        guard groupIdx <= (7 &- compressionSignFactor) else {
            return nil
        }

        /// TODO: Don't go through an String conversion here
        /// Read last remaining byte-pair

        let scalarsGroup = scalars[chunkStartIndex..<endIndex]
        if scalarsGroup.isEmpty {
            if seenCompressionSign {
                /// Must have reached end with no rhs
                self.init(addressLhs)
                return
            } else {
                /// No compression sign, but still have an empty group?!
                return nil
            }
        }

        guard
            let group = IPv6Address.mapToHexadecimalDigitsBasedOnIDNA(scalarsGroup),
            let byte = UInt16(String(group), radix: 16)
        else {
            return nil
        }

        /// If we've reached groupIdx of 6, then seenCompressionSign must not have happened

        if seenCompressionSign {
            addressRhs |= UInt128(byte) &<< (16 &* (7 &- groupIdx))
        } else {
            addressLhs |= UInt128(byte) &<< (16 &* (7 &- groupIdx))
        }

        /// We've reached the end of the string

        /// We must have seen a compression sign, or have had enough groups
        guard groupIdx == 7 || seenCompressionSign else {
            return nil
        }

        let compressedGroupsCount = 8 &- groupIdx &- 1
        let shift = 16 &* compressedGroupsCount
        addressLhs |= addressRhs &>> shift

        self.init(addressLhs)
    }

    /// Based on https://www.unicode.org/Public/idna/17.0.0/IdnaMappingTable.txt
    @usableFromInline
    static func isIDNAEquivalent(to toScalar: Unicode.Scalar, scalar: Unicode.Scalar) -> Bool {
        switch IDNAMapping.for(scalar: scalar) {
        case .valid:
            return scalar == toScalar
        case .mapped(let mapped), .deviation(let mapped):
            return mapped.count == 1 && mapped.first.unsafelyUnwrapped == toScalar
        case .disallowed, .ignored:
            return false
        }
    }

    @usableFromInline
    static func mapToHexadecimalDigitsBasedOnIDNA(
        _ scalars: String.UnicodeScalarView.SubSequence
    ) -> String.UnicodeScalarView.SubSequence? {
        /// Short-circuit if all scalars are ASCII
        if scalars.allSatisfy(\.isASCII) {
            /// Still might not be a valid number
            return scalars
        }

        var newScalars = [Unicode.Scalar]()
        newScalars.reserveCapacity(scalars.count)

        for idx in scalars.indices {
            let scalar = scalars[idx]
            if scalar.isUppercasedASCIILetter {
                /// Uppercased letters are fine, the Swift String-to-Int conversion accepts them.
                newScalars.append(scalar)
                continue
            }

            switch IDNAMapping.for(scalar: scalar) {
            case .valid:
                newScalars.append(scalar)
            case .mapped(let mapped), .deviation(let mapped):
                guard mapped.count == 1 else {
                    /// If this was a hexadecimal number it would have never had a mapped value of > 1
                    return nil
                }
                newScalars.append(mapped.first.unsafelyUnwrapped)
            case .ignored:
                continue
            case .disallowed:
                return nil
            }
        }

        return String.UnicodeScalarView.SubSequence(newScalars)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    package init(from buffer: inout DNSBuffer) throws {
        self.address = try buffer.readInteger(as: UInt128.self).unwrap(
            or: .failedToRead("IPv6Address", buffer)
        )
    }

    package init(from buffer: inout DNSBuffer, addressLength: Int) throws {
        guard addressLength <= 16 else {
            throw ProtocolError.failedToValidate(
                "IPv6Address.addressLength",
                buffer
            )
        }
        guard buffer.readableBytes >= addressLength else {
            throw ProtocolError.failedToRead(
                "IPv6Address_with_addressLength",
                buffer
            )
        }

        self.init(0)

        buffer.withUnsafeReadableBytes { ptr in
            for idx in 0..<16 {
                switch idx < addressLength {
                case true:
                    let byte = ptr[idx]
                    /// All these unchecked operations are safe because idx is always in 0..<16
                    let shift = 8 &* (15 &- idx)
                    self.address |= UInt128(byte) &<< shift
                case false:
                    break
                }
            }
        }
        buffer.moveReaderIndex(forwardBy: addressLength)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.address)
    }

    package func encode(into buffer: inout DNSBuffer, addressLength: Int) throws {
        guard addressLength <= 16 else {
            throw ProtocolError.failedToValidate(
                "IPv6Address.addressLength",
                buffer
            )
        }
        buffer.reserveCapacity(minimumWritableBytes: addressLength)

        for idx in 0..<addressLength {
            /// All these unchecked operations are safe because idx is always in 0..<16
            let shift = 8 &* (15 &- idx)
            let shifted = self.address &>> shift
            let masked = shifted & 0xFF
            let byte = UInt8(exactly: masked).unsafelyUnwrapped
            buffer.writeInteger(byte)
        }
    }
}
