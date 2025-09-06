public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address: CustomStringConvertible {
    /// The textual representation of an IPv6 address.
    /// That is, 8 16-bits (2-bytes) separated by `:`, enclosed in `[]`, while using
    /// the compression sign (`::`) when possible.
    ///
    /// Compliant with [RFC 5952, A Recommendation for IPv6 Address Text Representation, August 2010](https://tools.ietf.org/html/rfc5952).
    @inlinable
    public var description: String {
        var string = ""
        self.description(writeInto: &string)
        return string
    }

    @inlinable
    @_specialize(where IPv6Appendable == ByteBuffer)
    @_specialize(where IPv6Appendable == String)
    func description<IPv6Appendable: _IPv6DescriptionAppendable>(
        writeInto buffer: inout IPv6Appendable
    ) {
        /// Short-circuit "0".
        if self.address == 0 {
            buffer.append(contentsOf: "[::]")
            return
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

            buffer.append(.asciiOpeningSquareBracket)
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
            buffer.reserveCapacity(toReserve)

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
                    buffer.append(.asciiColon)
                    if idx == 0 {
                        /// Need 2 colons in this case, so '::'
                        buffer.append(.asciiColon)
                    }
                    idx = rangeToCompress.upperBound &+ 1
                    continue
                }

                let uint16 = uint16(octalIdx: idx)
                let string = String(uint16, radix: 16, uppercase: false)
                buffer.append(contentsOf: string)
                if idx < 7 {
                    buffer.append(.asciiColon)
                }

                idx &+= 1
            }

            buffer.append(.asciiClosingSquareBracket)
        }
    }
}

/// This protocol is only to be used internally so we can write IPv6's description into different
/// types of buffers. Currently using `String` for the `description` of the IPv6, and using
/// `ByteBuffer` for writing the IPv6 into a `DomainName`'s buffer.
@usableFromInline
protocol _IPv6DescriptionAppendable {
    mutating func append(_ byte: UInt8)
    mutating func append(contentsOf string: String)
    mutating func reserveCapacity(_ minimumCapacity: Int)
}

extension String: _IPv6DescriptionAppendable {
    @inlinable
    mutating func append(_ byte: UInt8) {
        self.append(Character(Unicode.Scalar(byte)))
    }
}

extension ByteBuffer: _IPv6DescriptionAppendable {
    @inlinable
    mutating func append(_ byte: UInt8) {
        self.writeInteger(byte)
    }

    @inlinable
    mutating func append(contentsOf string: String) {
        self.writeString(string)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address: LosslessStringConvertible {
    /// Initialize an IPv6 address from its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:0DB8:1111:0:0:0:0:0`.
    @inlinable
    public init?(_ description: String) {
        var addressLhs: UInt128 = 0
        var addressRhs: UInt128 = 0

        let scalars = description.unicodeScalars

        var startIndex = scalars.startIndex
        var endIndex = scalars.endIndex

        var count = scalars.distance(from: startIndex, to: endIndex)

        guard count > 1 else {
            return nil
        }

        /// Trim the left and right square brackets if they both exist
        let startsWithBracket = scalars.first == .asciiLeftSquareBracket
        let endsWithBracket = scalars.last == .asciiRightSquareBracket
        switch (startsWithBracket, endsWithBracket) {
        case (true, true):
            count &-= 2
            startIndex = scalars.index(after: startIndex)
            endIndex = scalars.index(before: endIndex)
        case (false, false):
            break
        case (true, false), (false, true):
            return nil
        }

        guard count > 1 else {
            return nil
        }

        let lastIndex = scalars.index(before: endIndex)
        var chunkStartIndex = startIndex

        var groupIdx = 0
        /// Have seen '::' or not
        var seenCompressionSign = false

        while let nextSeparatorIdx = scalars[chunkStartIndex..<endIndex].firstIndex(where: {
            $0 == .asciiColon
        }) {
            let scalarsGroup = scalars[chunkStartIndex..<nextSeparatorIdx]
            if scalarsGroup.isEmpty {
                if seenCompressionSign {
                    /// We've already seen a compression sign, so this is invalid
                    return nil
                }

                /// If we're at the first index
                if nextSeparatorIdx == startIndex {
                    let nextIdx = scalars.index(after: nextSeparatorIdx)

                    guard scalars[nextIdx] == .asciiColon else {
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
                    guard scalars[scalars.index(before: nextSeparatorIdx)] == .asciiColon else {
                        return nil
                    }

                    seenCompressionSign = true
                    chunkStartIndex = scalars.index(after: nextSeparatorIdx)
                    continue
                }
            }

            guard
                IPv6Address._read(
                    addressLhs: &addressLhs,
                    addressRhs: &addressRhs,
                    scalarsGroup: scalarsGroup,
                    seenCompressionSign: seenCompressionSign,
                    groupIdx: groupIdx
                )
            else {
                return nil
            }

            chunkStartIndex = scalars.index(after: nextSeparatorIdx)

            groupIdx &+= 1
        }

        let compressionSignFactor = seenCompressionSign ? 1 : 0
        guard groupIdx <= (7 &- compressionSignFactor) else {
            return nil
        }

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
            IPv6Address._read(
                addressLhs: &addressLhs,
                addressRhs: &addressRhs,
                scalarsGroup: scalarsGroup,
                seenCompressionSign: seenCompressionSign,
                groupIdx: groupIdx
            )
        else {
            return nil
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

    /// Reads the scalars group integers into addressLhs or addressRhs
    /// Returns false if the scalars group is invalid, in which case we should return `nil`.
    @inlinable
    static func _read(
        addressLhs: inout UInt128,
        addressRhs: inout UInt128,
        scalarsGroup: String.UnicodeScalarView.SubSequence,
        seenCompressionSign: Bool,
        groupIdx: Int
    ) -> Bool {
        let groupStartIdxInAddress = 16 &* (7 &- groupIdx)
        var idx = 0
        var indexInGroup = scalarsGroup.endIndex
        let startIndex = scalarsGroup.startIndex

        while scalarsGroup.formIndex(
            &indexInGroup,
            offsetBy: -1,
            limitedBy: startIndex
        ) {
            let scalar = scalarsGroup[indexInGroup]
            guard let hexadecimalDigit = IPv6Address.mapScalarToUInt8(scalar) else {
                return false
            }
            if idx > 3 { return false }

            let shift = groupStartIdxInAddress &+ (idx &* 4)
            if seenCompressionSign {
                addressRhs |= UInt128(hexadecimalDigit) &<< shift
            } else {
                addressLhs |= UInt128(hexadecimalDigit) &<< shift
            }

            let (newIdx, overflew) = idx.addingReportingOverflow(1)
            if overflew { return false }

            idx = newIdx
        }

        if idx == 0 {
            return false
        }

        return true
    }

    @inlinable
    static func mapScalarToUInt8(_ scalar: Unicode.Scalar) -> UInt8? {
        let newValue = scalar.value

        if newValue >= Unicode.Scalar.asciiLowercasedA.value {
            guard newValue <= Unicode.Scalar.asciiLowercasedF.value else {
                return nil
            }
            return UInt8(
                exactly: newValue &- Unicode.Scalar.asciiLowercasedA.value &+ 10
            ).unsafelyUnwrapped
        } else if newValue >= Unicode.Scalar.asciiUppercasedA.value {
            guard newValue <= Unicode.Scalar.asciiUppercasedF.value else {
                return nil
            }
            return UInt8(
                exactly: newValue &- Unicode.Scalar.asciiUppercasedA.value &+ 10
            ).unsafelyUnwrapped
        } else if newValue >= Unicode.Scalar.ascii0.value {
            guard newValue <= Unicode.Scalar.ascii9.value else {
                return nil
            }
            return UInt8(
                exactly: newValue &- Unicode.Scalar.ascii0.value
            ).unsafelyUnwrapped
        } else {
            return nil
        }
    }
}
