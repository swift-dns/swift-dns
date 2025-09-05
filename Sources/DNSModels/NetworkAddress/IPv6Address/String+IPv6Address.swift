public import SwiftIDNA

public import struct NIOCore.ByteBuffer

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
    @inlinable
    public init?(_ description: String) {
        var addressLhs: UInt128 = 0
        var addressRhs: UInt128 = 0

        let scalars = description.unicodeScalars

        var startIndex = scalars.startIndex
        var endIndex = scalars.endIndex

        let startsWithBracket =
            (scalars.first).map({
                IDNAMapping.isIDNAEquivalentAssumingSingleScalarMapping(
                    to: .asciiLeftSquareBracket,
                    scalar: $0
                )
            }) == true
        let endsWithBracket =
            (scalars.last).map({
                IDNAMapping.isIDNAEquivalentAssumingSingleScalarMapping(
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

        while let nextSeparatorIdx = scalars[chunkStartIndex..<endIndex].firstIndex(where: {
            IDNAMapping.isIDNAEquivalentAssumingSingleScalarMapping(
                to: .asciiColon,
                scalar: $0
            )
        }) {
            let scalarsGroup = scalars[chunkStartIndex..<nextSeparatorIdx]
            let scalarsCount = scalarsGroup.count
            switch scalarsCount {
            case 0:
                if seenCompressionSign {
                    /// We've already seen a compression sign, so this is invalid
                    return nil
                }

                /// If we're at the first index
                if nextSeparatorIdx == startIndex {
                    let nextIdx = scalars.index(after: nextSeparatorIdx)

                    guard
                        IDNAMapping.isIDNAEquivalentAssumingSingleScalarMapping(
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
                        IDNAMapping.isIDNAEquivalentAssumingSingleScalarMapping(
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
            case 1, 2, 3, 4:
                break
            default:
                return nil
            }

            guard
                IPv6Address._read(
                    addressLhs: &addressLhs,
                    addressRhs: &addressRhs,
                    scalarsGroup: scalarsGroup,
                    scalarsCount: scalarsCount,
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
        let scalarsCount = scalarsGroup.count
        switch scalarsCount {
        case 0:
            if seenCompressionSign {
                /// Must have reached end with no rhs
                self.init(addressLhs)
                return
            } else {
                /// No compression sign, but still have an empty group?!
                return nil
            }
        case 1, 2, 3, 4:
            break
        default:
            return nil
        }

        guard
            IPv6Address._read(
                addressLhs: &addressLhs,
                addressRhs: &addressRhs,
                scalarsGroup: scalarsGroup,
                scalarsCount: scalarsCount,
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
        scalarsCount: Int,
        seenCompressionSign: Bool,
        groupIdx: Int
    ) -> Bool {
        var ignored = 0
        let groupStartIdxInAddress = 16 &* (7 &- groupIdx)
        let maxIdx = scalarsCount &- 1
        for idx in 0..<scalarsCount {
            /// We're doing a reversed iteration of the elements so we can properly
            /// ignore the `ignored` scalars.
            let indexInGroup = scalarsGroup.index(
                scalarsGroup.startIndex,
                offsetBy: maxIdx &- idx
            )
            let scalar = scalarsGroup[indexInGroup]
            switch IPv6Address.mapScalarToUInt8(scalar) {
            case .valid(let byte):
                /// Ignored can't be greater than idx
                /// We still need to compute the shift using the `idx`
                let idxWithoutIgnored = idx &- ignored
                let shift = groupStartIdxInAddress &+ (idxWithoutIgnored &* 4)
                if seenCompressionSign {
                    addressRhs |= UInt128(byte) &<< shift
                } else {
                    addressLhs |= UInt128(byte) &<< shift
                }
            case .invalid:
                return false
            case .ignore:
                let (newIgnored, overflew) = ignored.addingReportingOverflow(1)
                if overflew { return false }

                ignored = newIgnored

                continue
            }
        }
        if ignored == scalarsCount {
            return false
        }
        return true
    }

    @usableFromInline
    enum ScalarTranslationResult: Sendable {
        case valid(UInt8)
        case invalid
        case ignore
    }

    @inlinable
    static func mapScalarToUInt8(
        _ scalar: Unicode.Scalar
    ) -> ScalarTranslationResult {
        switch IDNAMapping.for(scalar: scalar) {
        case .valid, .deviation(_):
            /// Deviations should not be mapped.
            /// See https://www.unicode.org/reports/tr46/#Processing for more info.
            return mapValidatedScalarToUInt8(scalar)
        case .mapped(let mapped):
            guard mapped.count == 1 else {
                /// If this was a decimal number it would have never had a mapped value of > 1
                return .invalid
            }
            return mapValidatedScalarToUInt8(mapped[unchecked: 0])
        case .ignored:
            return .ignore
        case .disallowed:
            return .invalid
        }
    }

    @inlinable
    static func mapValidatedScalarToUInt8(
        _ scalar: Unicode.Scalar
    ) -> ScalarTranslationResult {
        let newValue = scalar.value

        if newValue < Unicode.Scalar.asciiLowercasedA.value {
            guard
                newValue >= Unicode.Scalar.asciiZero.value,
                newValue <= Unicode.Scalar.ascii9.value
            else {
                return .invalid
            }
            return .valid(
                UInt8(exactly: newValue &- Unicode.Scalar.asciiZero.value).unsafelyUnwrapped
            )
        } else {
            guard newValue <= Unicode.Scalar.asciiLowercasedF.value else {
                return .invalid
            }
            return .valid(
                UInt8(
                    exactly: newValue &- Unicode.Scalar.asciiLowercasedA.value &+ 10
                ).unsafelyUnwrapped
            )
        }
    }
}
