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

            buffer.append(.asciiLeftSquareBracket)
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

            buffer.append(.asciiRightSquareBracket)
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

@available(swiftDNSApplePlatforms 26, *)
extension IPv6Address: LosslessStringConvertible {
    /// Initialize an IPv6 address from its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:0DB8:1111:0:0:0:0:0`.
    @inlinable
    public init?(_ description: String) {
        var addressLhs: UInt128 = 0
        var addressRhs: UInt128 = 0

        var utf8Span = description.utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }
        var span = utf8Span.span

        var count = span.count

        guard count > 1 else {
            return nil
        }

        /// Trim the left and right square brackets if they both exist
        let startsWithBracket = span[unchecked: 0] == .asciiLeftSquareBracket
        let endsWithBracket = span[unchecked: count &- 1] == .asciiRightSquareBracket
        switch (startsWithBracket, endsWithBracket) {
        case (true, true):
            span = span.extracting(1..<count &- 1)
            count &-= 2
        case (false, false):
            break
        case (true, false), (false, true):
            return nil
        }

        guard count > 1 else {
            return nil
        }

        var groupIdx = 0
        /// Have seen '::' or not
        var seenCompressionSign = false

        while let nextSeparatorIdx = span.firstIndex(where: { $0 == .asciiColon }) {
            let utf8Group = span.extracting(unchecked: 0..<nextSeparatorIdx)
            if utf8Group.isEmpty {
                if seenCompressionSign {
                    /// We've already seen a compression sign, so this is invalid
                    return nil
                }

                /// If we're at the first index
                if groupIdx == 0 {
                    let nextIdx = nextSeparatorIdx &+ 1

                    guard span[unchecked: nextIdx] == .asciiColon else {
                        return nil
                    }

                    seenCompressionSign = true
                    groupIdx &+= 2
                    span = span.extracting((nextIdx &+ 1)...)
                    continue

                    /// If we're at the last index
                } else if span.count == 1 {
                    guard groupIdx <= 7 else {
                        return nil
                    }
                    /// Must have reached end with no rhs
                    self.init(addressLhs)
                    return
                } else {
                    /// Must be a compression sign in the middle of the string
                    guard span[unchecked: nextSeparatorIdx &- 1] == .asciiColon else {
                        return nil
                    }

                    seenCompressionSign = true
                    groupIdx &+= 1
                    span = span.extracting((nextSeparatorIdx &+ 1)...)
                    continue
                }
            }

            guard
                IPv6Address._read(
                    addressLhs: &addressLhs,
                    addressRhs: &addressRhs,
                    utf8Group: utf8Group,
                    seenCompressionSign: seenCompressionSign,
                    groupIdx: groupIdx
                )
            else {
                return nil
            }

            /// This is safe, nothing will crash with this increase in index
            span = span.extracting((nextSeparatorIdx + 1)...)

            groupIdx &+= 1
        }

        guard groupIdx <= 7 else {
            return nil
        }

        /// Read last remaining byte-pair
        if span.isEmpty {
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
                utf8Group: span,
                seenCompressionSign: seenCompressionSign,
                groupIdx: groupIdx
            )
        else {
            return nil
        }

        /// We've reached the end of the string
        guard groupIdx == 7 || seenCompressionSign else {
            return nil
        }

        let compressedGroupsCount = 8 &- groupIdx &- 1
        let shift = 16 &* compressedGroupsCount
        addressLhs |= addressRhs &>> shift

        self.init(addressLhs)
    }

    /// Reads the `utf8Group` integers into addressLhs or addressRhs
    /// Returns false if the `utf8Group` is invalid, in which case we should return `nil`.
    @inlinable
    static func _read(
        addressLhs: inout UInt128,
        addressRhs: inout UInt128,
        utf8Group: Span<UInt8>,
        seenCompressionSign: Bool,
        groupIdx: Int
    ) -> Bool {
        let utf8Count = utf8Group.count

        if utf8Count == 0 || utf8Count > 4 {
            return false
        }

        let maxIdx = utf8Count &- 1

        let groupStartIdxInAddress = 16 &* (7 &- groupIdx)

        for idx in 0..<utf8Group.count {
            let indexInGroup = maxIdx - idx
            let utf8Byte = utf8Group[unchecked: indexInGroup]
            guard let hexadecimalDigit = IPv6Address.mapUTF8ByteToUInt8(utf8Byte) else {
                return false
            }
            /// idx guaranteed to be in 0..<4 because of the `utf8Count > 4` check above

            let shift = groupStartIdxInAddress &+ (idx &* 4)
            if seenCompressionSign {
                addressRhs |= UInt128(hexadecimalDigit) &<< shift
            } else {
                addressLhs |= UInt128(hexadecimalDigit) &<< shift
            }
        }

        return true
    }

    @inlinable
    static func mapUTF8ByteToUInt8(_ utf8Byte: UInt8) -> UInt8? {
        if utf8Byte >= UInt8.asciiLowercasedA {
            guard utf8Byte <= UInt8.asciiLowercasedF else {
                return nil
            }
            return utf8Byte &- UInt8.asciiLowercasedA &+ 10
        } else if utf8Byte >= UInt8.asciiUppercasedA {
            guard utf8Byte <= UInt8.asciiUppercasedF else {
                return nil
            }
            return utf8Byte &- UInt8.asciiUppercasedA &+ 10
        } else if utf8Byte >= UInt8.ascii0 {
            guard utf8Byte <= UInt8.ascii9 else {
                return nil
            }
            return utf8Byte &- UInt8.ascii0
        } else {
            return nil
        }
    }
}
