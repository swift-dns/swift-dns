public import DNSCore

import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address: CustomStringConvertible {
    /// The textual representation of an IPv6 address.
    /// That is, 8 16-bits (2-bytes) separated by `:`, enclosed in `[]`, while using
    /// the compression sign (`::`) when possible.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://tools.ietf.org/html/rfc5952).
    @inlinable
    public var description: String {
        self.makeDescription { (maxWriteableBytes, callback) in
            String(unsafeUninitializedCapacity: maxWriteableBytes) { buffer in
                callback(buffer)
            }
        }
    }

    @inlinable
    @_specialize(exported:true,kind:full,where Buffer == String)
    @_specialize(exported:true,kind:full,where Buffer == ByteBuffer)
    func makeDescription<Buffer>(
        writingToUnsafeMutableBufferPointerOfUInt8: (
            _ maxWriteableBytes: Int,
            _ callbackReturningBytesWritten: (UnsafeMutableBufferPointer<UInt8>) -> Int
        ) -> Buffer
    ) -> Buffer {
        /// Short-circuit "0".
        if self.address == 0 {
            return writingToUnsafeMutableBufferPointerOfUInt8(4) { ptr in
                ptr[0] = .asciiLeftSquareBracket
                ptr[1] = .asciiColon
                ptr[2] = .asciiColon
                ptr[3] = .asciiRightSquareBracket
                return 4
            }
        }

        return withUnsafeBytes(of: self.address) { ptr in
            func isZero(octalIdx idx: Int) -> Bool {
                let doubled = idx &** 2
                return ptr[15 &-- doubled] == 0 && ptr[14 &-- doubled] == 0
            }
            var rangeToCompress: Range<Int>? = nil
            var idx = 0
            /// idx < `7` instead of `8` because even if 7 is a zero it'll be a lone zero and
            /// we won't compress it anyway.
            while idx < 7 {
                guard isZero(octalIdx: idx) else {
                    idx &+== 1
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

                idx = endIndex &++ 1
            }

            assert(rangeToCompress?.isEmpty != true)

            /// Reserve the max possibly needed capacity.
            let toReserve: Int
            if let rangeToCompress {
                let segmentsCount = 8 &-- rangeToCompress.count
                let colonsCount = max(segmentsCount &-- 1, 2)
                let bracketsCount = 2
                toReserve = bracketsCount &++ colonsCount &++ (segmentsCount &** 4)
            } else {
                toReserve = 41
            }

            return writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { buffer in
                var writeIdx = 0

                buffer[0] = .asciiLeftSquareBracket
                writeIdx &+== 1

                /// Reset `idx`. It was used in a loop above.
                idx = 0
                while idx < 8 {
                    if let rangeToCompress,
                        idx == rangeToCompress.lowerBound
                    {
                        buffer[writeIdx] = .asciiColon
                        writeIdx &+== 1

                        if idx == 0 {
                            /// Need 2 colons in this case, so '::'
                            buffer[writeIdx] = .asciiColon
                            writeIdx &+== 1
                        }

                        idx = rangeToCompress.upperBound &++ 1
                        continue
                    }

                    let doubled = idx &** 2
                    let left = ptr[15 &-- doubled]
                    let right = ptr[14 &-- doubled]
                    IPv6Address._writeUInt16AsLowercasedASCII(
                        into: buffer,
                        advancingIdx: &writeIdx,
                        bytePair: (left, right)
                    )

                    if idx < 7 {
                        buffer[writeIdx] = .asciiColon
                        writeIdx &+== 1
                    }

                    idx &+== 1
                }

                buffer[writeIdx] = .asciiRightSquareBracket
                writeIdx &+== 1

                return writeIdx
            }
        }
    }

    /// Equivalent to `String(bytePairAsUInt16, radix: 16, uppercase: false)`, but faster.
    @inlinable
    static func _writeUInt16AsLowercasedASCII(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        advancingIdx idx: inout Int,
        bytePair: (left: UInt8, right: UInt8)
    ) {
        var soFarAllZeros = true

        let _1 = bytePair.left &>>> 4
        let _2 = bytePair.left & 0x0F
        let _3 = bytePair.right &>>> 4
        let _4 = bytePair.right & 0x0F

        if _1 != 0 {
            soFarAllZeros = false
            _writeLowercasedASCII(into: buffer, idx: &idx, byte: _1)
        }
        if !(_2 == 0 && soFarAllZeros) {
            soFarAllZeros = false
            _writeLowercasedASCII(into: buffer, idx: &idx, byte: _2)
        }
        if !(_3 == 0 && soFarAllZeros) {
            _writeLowercasedASCII(into: buffer, idx: &idx, byte: _3)
        }
        _writeLowercasedASCII(into: buffer, idx: &idx, byte: _4)
    }

    @inlinable
    static func _writeLowercasedASCII(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        idx: inout Int,
        byte: UInt8
    ) {
        buffer[idx] =
            byte > 9
            ? byte &++ UInt8.asciiLowercasedA &-- 10
            : byte &++ UInt8.ascii0
        idx &+== 1
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension IPv6Address: LosslessStringConvertible {
    /// Initialize an IPv6 address from its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    @inlinable
    public init?(_ description: String) {
        self.init(textualRepresentation: description.utf8Span)
    }

    /// Initialize an IPv6 address from its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    @inlinable
    public init?(_ description: Substring) {
        self.init(textualRepresentation: description.utf8Span)
    }

    /// Initialize an IPv6 address from a `UTF8Span` of its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    @inlinable
    public init?(textualRepresentation utf8Span: UTF8Span) {
        var utf8Span = utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }

        self.init(__uncheckedASCIIspan: utf8Span.span)
    }
}

@available(swiftDNSApplePlatforms 15, *)
@available(swiftDNSApplePlatforms 26, *)
extension IPv6Address {
    /// Initialize an IPv6 address from a `Span<UInt8>` of its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    @inlinable
    public init?(textualRepresentation span: Span<UInt8>) {
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            if !span[unchecked: idx].isASCII {
                return nil
            }
        }

        self.init(__uncheckedASCIIspan: span)
    }

    /// Initialize an IPv6 address from a `Span<UInt8>` of its textual representation.
    /// The provided **span is required to be ASCII**.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    @inlinable
    public init?(__uncheckedASCIIspan span: Span<UInt8>) {
        self.init(__uncheckedASCIIspan: span, preParsedIPv4MappedSegment: nil)
    }

    /// Initialize an IPv6 address from a `Span<UInt8>` of its textual representation.
    /// The provided **span is required to be ASCII**.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    /// Can also parse IPv4-mapped IPv6 addresses in format `"::FFFF:204.152.189.116"`.
    @inlinable
    init?(
        __uncheckedASCIIspan span: Span<UInt8>,
        preParsedIPv4MappedSegment: IPv4Address?
    ) {
        debugOnly {
            for idx in span.indices {
                /// Unchecked because `idx` comes right from `span.indices`
                if !span[unchecked: idx].isASCII {
                    fatalError(
                        "IPv6Address initializer should not be used with non-ASCII character: \(span[unchecked: idx])"
                    )
                }
            }
        }

        var addressLhs: UInt128 = 0
        var addressRhs: UInt128 = 0

        var span = span
        var count = span.count

        /// Longest possible ipv6 address is something like
        /// [0000:0000:0000:0000:0000:ffff:111.111.111.111] which is only 47 bytes long.
        guard count >= 2, count <= 47 else {
            return nil
        }

        /// Trim the left and right square brackets if they both exist

        /// Unchecked because we just checked count > 1 above
        let startsWithBracket = span[unchecked: 0] == .asciiLeftSquareBracket
        /// Unchecked because we just checked count > 1 above
        let endsWithBracket = span[unchecked: count &-- 1] == .asciiRightSquareBracket
        switch (startsWithBracket, endsWithBracket) {
        case (true, true):
            /// Unchecked because we just checked count > 1 above
            span = span.extracting(1..<(count &-- 1))
            count &-== 2
        case (false, false):
            break
        case (true, false), (false, true):
            return nil
        }

        guard count > 1 else {
            return nil
        }

        /// `UInt8` is fine, up there we made sure there are less than 50 elements in the span.
        /// In an IPv6 address like `[0000:0000:0000:0000:0000:ffff:1.1.1.1]`,
        /// we have 3 dots. This is the maximum amount of dots we can have.
        /// Use 255 as placeholder. We won't have more than 50 elements anyway based on a check above.
        var dotsIndicesPointer: [3 of UInt8] = .init(repeating: 255)
        var dotsIndicesCount = 0

        /// `UInt8` is fine, up there we made sure there are less than 50 elements in the span.
        /// In an IPv6 address like `[0:0:0:0:0:0:0:0]`,
        /// we have 7 colons. This is the maximum amount of colons we can have.
        /// Use 255 as placeholder. We won't have more than 50 elements anyway based on a check above.
        var colonsIndicesPointer: [7 of UInt8] = .init(repeating: 255)
        var colonsIndicesCount = 0

        for idx in span.indices {
            switch span[unchecked: idx] {
            case .asciiColon:
                if colonsIndicesCount == 7 {
                    /// Cannot have any more colons
                    return nil
                }
                /// Unchecked because `idx` is guaranteed to be in range of `0...span.count`
                /// And we checked above that span is less than 50 elements long.
                colonsIndicesPointer[colonsIndicesCount] = UInt8(exactly: idx).unsafelyUnwrapped
                colonsIndicesCount &+== 1
            case .asciiDot:
                if dotsIndicesCount == 3 {
                    /// Cannot have any more dots
                    return nil
                }
                /// Unchecked because `idx` is guaranteed to be in range of `0...span.count`
                /// And we checked above that span is less than 50 elements long.
                dotsIndicesPointer[dotsIndicesCount] = UInt8(exactly: idx).unsafelyUnwrapped
                dotsIndicesCount &+== 1
            default:
                continue
            }
        }

        guard colonsIndicesCount >= 2 else {
            return nil
        }
        var ipv4MappedSegment: IPv4Address?

        /// Make sure dots are either 0, or 3.
        /// If 3, then make sure they are all on the left side of all colons.
        /// Can happen in an IPv6 address like `[0000:0000:0000:0000:0000:ffff:1.1.1.1]`,
        switch dotsIndicesCount {
        case 0:
            break
        case 3:
            /// We need at least 3 colons in a valid ipv4-mapped ipv6 address.
            /// Like in `::FFFF:1.1.1.1`.
            /// In `0:0:0:0:0:FFFF:1.1.1.1` we have 6 colons, which is max amount for
            /// a valid ipv4-mapped ipv6 address.
            guard colonsIndicesCount >= 3, colonsIndicesCount <= 6 else {
                return nil
            }
            let rightmostColonIdx = colonsIndicesPointer[colonsIndicesCount &-- 1]
            /// We already know we have 3 dots
            let leftmostDotIdx = dotsIndicesPointer[unchecked: 0]
            /// In `::FFFF:1.1.1.1` for example, first dot index is bigger than the last colon index.
            guard leftmostDotIdx > rightmostColonIdx else {
                return nil
            }
            let intRightmostColonIdx = Int(rightmostColonIdx)
            ipv4MappedSegment = IPv4Address(
                __uncheckedASCIIspan: span.extracting(
                    unchecked: intRightmostColonIdx &++ 1..<count
                )
            )
            /// We must have a valid ipv4 mapped segment by now.
            if ipv4MappedSegment == nil {
                return nil
            }
            /// Set the span to only the left side of the ipv4 mapped segment.
            /// This'll extract `::FFFF` from `::FFFF:1.1.1.1`.
            span = span.extracting(unchecked: 0..<intRightmostColonIdx)
            count = intRightmostColonIdx
        default:
            return nil
        }

        if let preParsedIPv4MappedSegment {
            /// Can't have both a pre-parsed segment and also a not-parsed one.
            guard ipv4MappedSegment == nil else {
                return nil
            }
            guard colonsIndicesCount >= 3, colonsIndicesCount <= 6 else {
                return nil
            }

            ipv4MappedSegment = preParsedIPv4MappedSegment
        }

        /// If we have an ipv4MappedSegment, we don't need to check the colons count.
        /// Because the ipv4 decoding process already has done it.
        if ipv4MappedSegment == nil {
            guard colonsIndicesCount >= 2 else {
                return nil
            }
        }

        /// Have seen '::' or not
        var seenCompressionSign = false

        var segmentStartIdx = 0

        var groupIdx = 0
        while groupIdx < colonsIndicesCount {
            /// These are safe to unwrap, we're keeping track of them using the array's idx
            let nextSeparatorIdx = Int(colonsIndicesPointer[groupIdx])

            let asciiGroup = span.extracting(unchecked: segmentStartIdx..<nextSeparatorIdx)

            if asciiGroup.isEmpty {
                if seenCompressionSign {
                    /// We've already seen a compression sign, so this is invalid
                    return nil
                }

                /// If we're at the first index
                if groupIdx == 0 {
                    /// Unchecked because it can't exceed `span.count` anyway
                    let nextIdx = nextSeparatorIdx &++ 1

                    guard span[unchecked: nextIdx] == .asciiColon else {
                        return nil
                    }

                    seenCompressionSign = true
                    /// Unchecked because it can't exceed `span.count` anyway
                    groupIdx &+== 2
                    segmentStartIdx = nextSeparatorIdx &++ 2
                    continue

                    /// If we're at the last index
                } else if (segmentStartIdx &++ 1) == count {
                    /// Must have reached end with no rhs
                    self.init(addressLhs)
                    return
                } else {
                    /// Must be a compression sign in the middle of the string
                    /// Unchecked because it can't exceed `span.count` anyway
                    guard span[unchecked: nextSeparatorIdx &-- 1] == .asciiColon else {
                        return nil
                    }

                    seenCompressionSign = true
                    /// Unchecked because it can't exceed `span.count` anyway
                    groupIdx &+== 1
                    segmentStartIdx = nextSeparatorIdx &++ 1
                    continue
                }
            }

            guard
                IPv6Address._readIPv6Group(
                    addressLhs: &addressLhs,
                    addressRhs: &addressRhs,
                    textualRepresentation: asciiGroup,
                    seenCompressionSign: seenCompressionSign,
                    groupIdx: groupIdx
                )
            else {
                return nil
            }

            groupIdx &+== 1
            segmentStartIdx = nextSeparatorIdx &++ 1
        }

        /// Read last remaining byte-pair
        if segmentStartIdx >= count {
            if seenCompressionSign {
                guard let ipv4MappedSegment else {
                    /// Must have reached end with no rhs
                    self.init(addressLhs)
                    return
                }
                /// Unchecked because `3 <= groupIdx <= 6` based on the check for a valid
                /// ipv4-mapped ipv6 address.
                /// So this number is guaranteed to be in range of `0...6`
                let compressedGroupsCount = 8 &-- groupIdx &-- 2
                /// Unchecked because `compressedGroupsCount` is guaranteed to be in range of `0...6`
                let shift = 16 &** compressedGroupsCount
                /// Unchecked because `shift` is guaranteed to be in range of `0...96`
                addressLhs |= addressRhs &>>> shift
                addressLhs |= UInt128(ipv4MappedSegment.address)

                self.init(addressLhs)
                guard CIDR<IPv6Address>.ipv4Mapped.contains(self) else {
                    return nil
                }
                return
            } else {
                guard groupIdx == 6,
                    let ipv4MappedSegment
                else {
                    /// No compression sign and no ipv4-mapped segment, but still have an empty group?!
                    return nil
                }
                self.init(addressLhs | UInt128(ipv4MappedSegment.address))
                guard CIDR<IPv6Address>.ipv4Mapped.contains(self) else {
                    return nil
                }
                return
            }
        }

        guard
            IPv6Address._readIPv6Group(
                addressLhs: &addressLhs,
                addressRhs: &addressRhs,
                textualRepresentation: span.extracting(unchecked: segmentStartIdx..<count),
                seenCompressionSign: seenCompressionSign,
                groupIdx: colonsIndicesCount
            )
        else {
            return nil
        }

        /// We've reached the end of the string
        guard colonsIndicesCount == 7 || seenCompressionSign else {
            return nil
        }

        /// Unchecked because there is a `groupIdx <= 7` check above
        /// So this number is guaranteed to be in range of `0...7`
        let compressedGroupsCount = 8 &-- groupIdx &-- 1
        /// Unchecked because `compressedGroupsCount` is guaranteed to be in range of `0...7`
        let shift = 16 &** compressedGroupsCount
        /// Unchecked because `shift` is guaranteed to be in range of `0...128`
        addressLhs |= addressRhs &>>> shift

        self.init(addressLhs)
    }

    /// Reads the `asciiGroup` integers into `addressLhs` or `addressRhs`.
    /// Returns false if the `asciiGroup` is invalid, in which case we should return `nil`.
    @inlinable
    static func _readIPv6Group(
        addressLhs: inout UInt128,
        addressRhs: inout UInt128,
        textualRepresentation asciiGroup: Span<UInt8>,
        seenCompressionSign: Bool,
        groupIdx: Int
    ) -> Bool {
        let utf8Count = asciiGroup.count

        if utf8Count == 0 || utf8Count > 4 {
            return false
        }

        /// Unchecked because it must be in range of 0...3 based on the check above
        let maxIdx = utf8Count &-- 1
        /// Unchecked because `groupIdx` is should be in range of 0...7
        /// `groupIdx` here _could_ be higher too, like `8`.
        /// That still doesn't cause any problems based on the tests, so we accept it.
        let groupStartIdxInAddress = 16 &** (7 &-- groupIdx)

        for idx in 0..<asciiGroup.count {
            /// Unchecked because it's less than `asciiGroup.count` anyway
            let indexInGroup = maxIdx &-- idx
            let utf8Byte = asciiGroup[unchecked: indexInGroup]
            guard let hexadecimalDigit = IPv6Address.mapHexadecimalASCIIToUInt8(utf8Byte) else {
                return false
            }
            /// `idx` is guaranteed to be in range of 0...3 because of the `utf8Count > 4` check above

            /// Unchecked because `0 <= idx <= 3`, `groupStartIdxInAddress` is should be in range of `0...128`
            /// The `shift` here _could_ end up being a negative number.
            /// That still doesn't cause any problems based on the tests, so we accept it.
            ///
            /// We can have a bounds check for `groupIdx` to ensure this doesn't happen, but
            /// that comes with a compromise on performance.
            let shift = groupStartIdxInAddress &++ (idx &** 4)
            /// Unchecked because it can't exceed `128` anyway
            if seenCompressionSign {
                /// Per what explained above, we do `&<<` instead of `&<<<` here.
                /// We accept that `shift` could be a negative number, which is unwanted by the
                /// implementation, but still works out fine.
                addressRhs |= UInt128(hexadecimalDigit) &<< shift
            } else {
                /// Per what explained above, we do `&<<` instead of `&<<<` here.
                /// We accept that `shift` could be a negative number, which is unwanted by the
                /// implementation, but still works out fine.
                addressLhs |= UInt128(hexadecimalDigit) &<< shift
            }
        }

        return true
    }

    @inlinable
    static func mapHexadecimalASCIIToUInt8(_ utf8Byte: UInt8) -> UInt8? {
        if utf8Byte >= UInt8.asciiLowercasedA {
            guard utf8Byte <= UInt8.asciiLowercasedF else {
                return nil
            }
            return utf8Byte &-- UInt8.asciiLowercasedA &++ 10
        } else if utf8Byte >= UInt8.asciiUppercasedA {
            guard utf8Byte <= UInt8.asciiUppercasedF else {
                return nil
            }
            return utf8Byte &-- UInt8.asciiUppercasedA &++ 10
        } else if utf8Byte >= UInt8.ascii0 {
            guard utf8Byte <= UInt8.ascii9 else {
                return nil
            }
            return utf8Byte &-- UInt8.ascii0
        } else {
            return nil
        }
    }
}
