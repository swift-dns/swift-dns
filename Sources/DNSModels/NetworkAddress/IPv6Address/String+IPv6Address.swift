public import func DNSCore.debugOnly
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

            return writingToUnsafeMutableBufferPointerOfUInt8(toReserve) { buffer in
                var writeIdx = 0

                buffer[0] = .asciiLeftSquareBracket
                writeIdx &+= 1

                /// Reset `idx`. It was used in a loop above.
                idx = 0
                while idx < 8 {
                    if let rangeToCompress,
                        idx == rangeToCompress.lowerBound
                    {
                        buffer[writeIdx] = .asciiColon
                        writeIdx &+= 1

                        if idx == 0 {
                            /// Need 2 colons in this case, so '::'
                            buffer[writeIdx] = .asciiColon
                            writeIdx &+= 1
                        }

                        idx = rangeToCompress.upperBound &+ 1
                        continue
                    }

                    let doubled = idx &* 2
                    let left = ptr[15 &- doubled]
                    let right = ptr[14 &- doubled]
                    IPv6Address._writeUInt16AsLowercasedASCII(
                        into: buffer,
                        advancingIdx: &writeIdx,
                        bytePair: (left, right)
                    )

                    if idx < 7 {
                        buffer[writeIdx] = .asciiColon
                        writeIdx &+= 1
                    }

                    idx &+= 1
                }

                buffer[writeIdx] = .asciiRightSquareBracket
                writeIdx &+= 1

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

        let _1 = bytePair.left &>> 4
        let _2 = bytePair.left & 0x0F
        let _3 = bytePair.right &>> 4
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
            ? byte &+ UInt8.asciiLowercasedA &- 10
            : byte &+ UInt8.ascii0
        idx &+= 1
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension IPv6Address: LosslessStringConvertible {
    /// Initialize an IPv6 address from its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    @inlinable
    public init?(_ description: String) {
        self.init(utf8Span: description.utf8Span)
    }

    /// Initialize an IPv6 address from its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    @inlinable
    public init?(_ description: Substring) {
        self.init(utf8Span: description.utf8Span)
    }

    /// Initialize an IPv6 address from a `UTF8Span` of its textual representation.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    @inlinable
    public init?(utf8Span: UTF8Span) {
        var utf8Span = utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }

        self.init(_uncheckedASCIIspan: utf8Span.span)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPv6Address {
    /// Initialize an IPv6 address from a `Span<UInt8>` of its textual representation.
    /// The provided span is expected to be ASCII.
    /// For example `"[2001:db8:1111::]"` will parse into `2001:DB8:1111:0:0:0:0:0`,
    /// or in other words `0x2001_0DB8_1111_0000_0000_0000_0000_0000`.
    @inlinable
    init?(_uncheckedASCIIspan span: Span<UInt8>) {
        debugOnly {
            for idx in span.indices {
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

        guard count > 1 else {
            return nil
        }

        /// Trim the left and right square brackets if they both exist

        /// Unchecked because we just checked count > 1 above
        let startsWithBracket = span[unchecked: 0] == .asciiLeftSquareBracket
        /// Unchecked because we just checked count > 1 above
        let endsWithBracket = span[unchecked: count &- 1] == .asciiRightSquareBracket
        switch (startsWithBracket, endsWithBracket) {
        case (true, true):
            span = span.extracting(1..<(count &- 1))
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
                    span = span.extracting(unchecked: (nextIdx &+ 1)..<span.count)
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
                    span = span.extracting(unchecked: (nextSeparatorIdx &+ 1)..<span.count)
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
            span = span.extracting((nextSeparatorIdx &+ 1)...)

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

    /// Reads the `utf8Group` integers into `addressLhs` or `addressRhs`.
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
            let indexInGroup = maxIdx &- idx
            let utf8Byte = utf8Group[unchecked: indexInGroup]
            guard let hexadecimalDigit = IPv6Address.mapHexadecimalASCIIToUInt8(utf8Byte) else {
                return false
            }
            /// `idx` is guaranteed to be in range of 0...3 because of the `utf8Count > 4` check above

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
    static func mapHexadecimalASCIIToUInt8(_ utf8Byte: UInt8) -> UInt8? {
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
