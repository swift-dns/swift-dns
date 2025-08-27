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
@available(swiftDNSApplePlatforms 15, *)
public struct IPv6Address: Sendable, Hashable {
    @usableFromInline
    static var size: Int {
        16
    }

    public var address: UInt128

    public init(_ address: UInt128) {
        self.address = address
    }

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
        /// Broken into 2 steps so compiler is happy
        self.address = UInt128(_1) &<< 112
        self.address |= UInt128(_2) &<< 96
        self.address |= UInt128(_3) &<< 80
        self.address |= UInt128(_4) &<< 64
        self.address |= UInt128(_5) &<< 48
        self.address |= UInt128(_6) &<< 32
        self.address |= UInt128(_7) &<< 16
        self.address |= UInt128(_8)
    }

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
        /// FIXME: Better way without turning each into a UInt128?
        self.address = UInt128(_1) &<< 120
        self.address |= UInt128(_2) &<< 112
        self.address |= UInt128(_3) &<< 104
        self.address |= UInt128(_4) &<< 96
        self.address |= UInt128(_5) &<< 88
        self.address |= UInt128(_6) &<< 80
        self.address |= UInt128(_7) &<< 72
        self.address |= UInt128(_8) &<< 64
        self.address |= UInt128(_9) &<< 56
        self.address |= UInt128(_10) &<< 48
        self.address |= UInt128(_11) &<< 40
        self.address |= UInt128(_12) &<< 32
        self.address |= UInt128(_13) &<< 24
        self.address |= UInt128(_14) &<< 16
        self.address |= UInt128(_15) &<< 8
        self.address |= UInt128(_16)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
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
extension IPv6Address: CustomStringConvertible {
    /// The textual representation of an IPv6 address, enclosed in `[]`.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://tools.ietf.org/html/rfc5952).
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

        var chunkStartIndex = startIndex

        var partIdx = 0
        /// Have seen '::' or not
        var seenCompressionSign = false
        while let nextSeparatorIdx = scalars[chunkStartIndex..<endIndex].firstIndex(
            where: { IPv6Address.isIDNAEquivalent(to: .asciiColon, scalar: $0) }
        ) {
            let scalarsPart = scalars[chunkStartIndex..<nextSeparatorIdx]
            if scalarsPart.isEmpty {
                if seenCompressionSign {
                    /// We've already seen a compression sign, so this is invalid
                    return nil
                }

                /// If we're at the first index
                if nextSeparatorIdx == startIndex {
                    /// This is guaranteed valid
                    let nextIdx = scalars.index(after: nextSeparatorIdx)

                    guard
                        nextIdx != endIndex,
                        IPv6Address.isIDNAEquivalent(
                            to: .asciiColon,
                            scalar: scalars[nextIdx]
                        )
                    else {
                        return nil
                    }

                    seenCompressionSign = true
                    /// This is safe, nothing will crash with this increase in index
                    chunkStartIndex = scalars.index(after: nextIdx)
                    continue
                } else if nextSeparatorIdx == scalars.index(before: endIndex) {
                    guard partIdx <= 7 else {
                        return nil
                    }
                    /// Must have reached end with no rhs
                    self.init(addressLhs)
                    return
                } else {
                    guard
                        let previousIdx = scalars.index(
                            nextSeparatorIdx,
                            offsetBy: -1,
                            limitedBy: startIndex
                        ),
                        IPv6Address.isIDNAEquivalent(
                            to: .asciiColon,
                            scalar: scalars[previousIdx]
                        )
                    else {
                        return nil
                    }

                    seenCompressionSign = true
                    /// This is safe, nothing will crash with this increase in index
                    chunkStartIndex = scalars.index(after: nextSeparatorIdx)
                    continue
                }
            }

            /// TODO: Don't go through an String conversion here
            guard
                let part = IPv6Address.mapToHexadecimalDigitsBasedOnIDNA(scalarsPart),
                let byte = UInt16(String(part), radix: 16)
            else {
                return nil
            }

            if seenCompressionSign {
                addressRhs |= UInt128(byte) &<< (16 &* (7 &- partIdx))
            } else {
                addressLhs |= UInt128(byte) &<< (16 &* (7 &- partIdx))
            }

            /// This is safe, nothing will crash with this increase in index
            chunkStartIndex = scalars.index(after: nextSeparatorIdx)

            partIdx &+= 1
        }

        guard partIdx <= (7 &- (seenCompressionSign ? 1 : 0)) else {
            return nil
        }

        /// TODO: Don't go through an String conversion here
        /// Read last remaining byte-pair

        let scalarsPart = scalars[chunkStartIndex..<endIndex]
        if scalarsPart.isEmpty {
            if seenCompressionSign {
                /// Must have reached end with no rhs
                self.init(addressLhs)
                return
            } else {
                /// No compression sign, but still have an empty part?!
                return nil
            }
        }

        guard
            let part = IPv6Address.mapToHexadecimalDigitsBasedOnIDNA(scalarsPart),
            let byte = UInt16(String(part), radix: 16)
        else {
            return nil
        }

        /// If we've reached partIdx of 6, then seenCompressionSign must not have happened

        if seenCompressionSign {
            addressRhs |= UInt128(byte) &<< (16 &* (7 &- partIdx))
        } else {
            addressLhs |= UInt128(byte) &<< (16 &* (7 &- partIdx))
        }

        /// We've reached the end of the string

        /// We must have seen a compression sign, or have had enough parts
        guard partIdx == 7 || seenCompressionSign else {
            return nil
        }

        let compressedPartsCount = 8 &- partIdx &- 1
        let shift = 16 &* compressedPartsCount
        addressLhs |= addressRhs &>> shift

        self.init(addressLhs)
    }

    /// Based on https://www.unicode.org/Public/idna/17.0.0/IdnaMappingTable.txt
    static func isIDNAEquivalent(to toScalar: Unicode.Scalar, scalar: Unicode.Scalar) -> Bool {
        switch IDNAMapping.for(scalar: scalar) {
        case .valid:
            return scalar == toScalar
        case .mapped(let mapped), .deviation(let mapped):
            return mapped.count == 1 && mapped.first == toScalar
        case .disallowed, .ignored:
            return false
        }
    }

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
