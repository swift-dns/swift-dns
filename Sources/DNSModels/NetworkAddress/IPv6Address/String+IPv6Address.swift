public import DNSCore

import struct NIOCore.ByteBuffer

#if os(Linux) || os(FreeBSD) || os(Android)

#if canImport(Glibc)
@preconcurrency public import Glibc
#elseif canImport(Musl)
@preconcurrency public import Musl
#elseif canImport(Android)
@preconcurrency public import Android
#endif

#elseif os(Windows)
public import ucrt
#elseif canImport(Darwin)
public import Darwin
#elseif canImport(WASILibc)
@preconcurrency public import WASILibc
#else
#error("The String+IPv6Address module was unable to identify your C library.")
#endif

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
    ///
    /// `preParsedIPv4MappedSegment` is helpful when redirecting a domain name parsing to this
    /// initializer. Because a `.` is a label separator in domain names, and because this library's
    /// `DomainName` type stores wire-format character-strings in its storage, the efficient way
    /// to parse an IPv4-mapped IPv6 address is to first parse the IPv4 address using ipv4
    /// initializers, then pass that ipv4 to this initializer.
    /// This helps us avoid reallocating memory, which would happen if we wanted to convert the
    /// domain name to a proper ipv6 address.
    @inlinable
    package init?(
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

        self.init(0)

        /// Swift stores integers in little-endian, so we need to do a little bit of gymnastics here
        /// and write backwards.
        var noIPv4MappedSegments = true
        let success = withUnsafeMutableBytes(of: &self.address) { addressPtr -> Bool in
            IPv6Address.parseIPv6(
                span: span,
                addressBufferPtr: addressPtr,
                noIPv4MappedSegments: &noIPv4MappedSegments,
                preParsedIPv4MappedSegment: preParsedIPv4MappedSegment
            )
        }

        guard success,
            noIPv4MappedSegments || CIDR<IPv6Address>.ipv4Mapped.contains(self)
        else {
            return nil
        }
    }

    @inlinable
    static func parseIPv6(
        span: Span<UInt8>,
        addressBufferPtr: UnsafeMutableRawBufferPointer,
        noIPv4MappedSegments: inout Bool,
        preParsedIPv4MappedSegment: IPv4Address?
    ) -> Bool {
        let addressPtr = addressBufferPtr.baseAddress.unsafelyUnwrapped
        var span = span

        guard span.count >= "::".count else {
            return false
        }

        /// Trim the left and right square brackets if they both exist

        /// Unchecked because we just checked count > 1 above
        let startsWithBracket = span[unchecked: 0] == .asciiLeftSquareBracket
        /// Unchecked because we just checked count > 1 above
        let endsWithBracket = span[unchecked: span.count &-- 1] == .asciiRightSquareBracket
        switch (startsWithBracket, endsWithBracket) {
        case (false, false):
            break
        case (true, true):
            /// Unchecked because we just checked count > 1 above
            span = span.extracting(Range(uncheckedBounds: (1, span.count &-- 1)))
        case (true, false), (false, true):
            return false
        }

        guard span.count >= "::".count else {
            return false
        }

        /// Special-case handling for when there is a compression sign at the beginning
        if span[unchecked: 0] == .asciiColon {
            span = span.extracting(Range(uncheckedBounds: (1, span.count)))
            if span[unchecked: 0] != .asciiColon {
                return false
            }
        }

        let endIdx = span.count &-- 1
        var segmentDigitIdx = 0
        var latestColonIdx = -1
        var currentSegmentValue: UInt16 = 0
        var remainingBytesCount = 16
        /// cs == compression sign
        var beforeCsBytesCountRemaining = -1
        for idx in span.indices {
            let byte = span[unchecked: idx]

            if let digit = IPv6Address.mapHexadecimalASCIIToUInt8(byte) {
                if segmentDigitIdx == 4 {
                    return false
                }

                currentSegmentValue &<<== 4
                currentSegmentValue |= UInt16(digit)
                segmentDigitIdx &+== 1

                continue
            }

            if byte == .asciiColon {
                latestColonIdx = idx
                if segmentDigitIdx == 0 {
                    if beforeCsBytesCountRemaining != -1 {
                        return false
                    }
                    beforeCsBytesCountRemaining = remainingBytesCount
                    continue
                } else if idx == endIdx {
                    return false
                }

                /// We only do decrements of 2x to remainingBytesCount so it can't be 1.
                if remainingBytesCount == 0 {
                    return false
                }

                remainingBytesCount &-== 2
                withUnsafeBytes(of: &currentSegmentValue) {
                    addressPtr.advanced(by: remainingBytesCount).copyMemory(
                        from: $0.baseAddress.unsafelyUnwrapped,
                        byteCount: 2
                    )
                }

                segmentDigitIdx = 0
                currentSegmentValue = 0

                continue
            }

            if byte == .asciiDot {
                guard
                    remainingBytesCount >= 4,
                    preParsedIPv4MappedSegment == nil,
                    var ipv4 = IPv4Address(
                        __uncheckedASCIIspan: span.extracting(
                            unchecked: Range(
                                uncheckedBounds: (latestColonIdx &++ 1, span.count)
                            )
                        )
                    )
                else {
                    return false
                }

                remainingBytesCount &-== 4
                withUnsafeBytes(of: &ipv4.address) {
                    addressPtr.advanced(by: remainingBytesCount).copyMemory(
                        from: $0.baseAddress.unsafelyUnwrapped,
                        byteCount: 4
                    )
                }

                noIPv4MappedSegments = false
                segmentDigitIdx = 0
                currentSegmentValue = 0

                break
            }

            /// Bad character
            return false
        }

        if segmentDigitIdx > 0 {
            guard remainingBytesCount >= 2 else {
                return false
            }
            remainingBytesCount &-== 2
            withUnsafeBytes(of: &currentSegmentValue) {
                addressPtr.advanced(by: remainingBytesCount).copyMemory(
                    from: $0.baseAddress.unsafelyUnwrapped,
                    byteCount: 2
                )
            }
        }

        if var ipv4 = preParsedIPv4MappedSegment {
            guard remainingBytesCount >= 4 else {
                return false
            }
            remainingBytesCount &-== 4
            withUnsafeBytes(of: &ipv4.address) {
                addressPtr.advanced(by: remainingBytesCount).copyMemory(
                    from: $0.baseAddress.unsafelyUnwrapped,
                    byteCount: 4
                )
            }

            noIPv4MappedSegments = false
        }

        if beforeCsBytesCountRemaining != -1 {
            guard remainingBytesCount >= 4 else {
                return false
            }
            /// cs == compression sign
            let afterCsBytesCount = beforeCsBytesCountRemaining &-- remainingBytesCount

            /// Swift stores integers in little-endian, so we need to do a little bit of gymnastics.
            ///
            /// Example:
            /// Assume at the end of this parsing process we need to have:
            /// 0x2001 0db8 85a3 0000 0000 0000 0100 0020
            ///
            /// For that, at this point in the process, the `self.address` looks like this:
            /// 0x2001 0db8 85a3 0100 0020 0000 0000 0000
            ///
            /// We need to move the bytes so it becomes like the first one.
            ///
            /// In little endian the integer we have right here looks like:
            /// 0x0000 0000 0000 0200 0010 3a58 08bd 1002
            ///
            /// For clearer demonstration, i'll use the big-endian representation in each ipv6 segment.
            /// So we assume in little-endian the integer looks like this:
            /// 0x0000 0000 0000 0020 0100 85a3 0db8 2001

            /// In this example, the memmove below will turn this:
            /// 0x0000 0000 0000 0020 0100 85a3 0db8 2001
            /// into this:
            /// 0x0020 0100 0000 0020 0100 85a3 0db8 2001
            ///   ~~^  ~~^
            memmove(
                addressPtr,
                addressPtr.advanced(by: beforeCsBytesCountRemaining &-- afterCsBytesCount),
                afterCsBytesCount
            )

            /// Now that we have:
            /// 0x0020 0100 0000 0020 0100 85a3 0db8 2001
            ///
            /// We set the middle 0020 0100 to zeros:
            /// 0x0020 0100 0000 0000 0000 85a3 0db8 2001
            ///                  ~~^  ~~^
            memset(
                addressPtr.advanced(by: beforeCsBytesCountRemaining &-- remainingBytesCount),
                0,
                remainingBytesCount
            )
            /// Hurray! Now we have the correct ipv6 address!
            /// Swift will read this as:
            /// 0x2001 0db8 85a3 0000 0000 0000 0100 0020
            /// which is what we aimed for.
            return true
        } else {
            return remainingBytesCount == 0
        }
    }

    @inlinable
    static func mapHexadecimalASCIIToUInt8(_ asciiByte: UInt8) -> UInt8? {
        /// The order here is intentional.
        /// First check for lower-or-equal to 9, then higher-or-equal to 0.
        ///
        /// In a correct IPv6 string, if this byte is not 0-9, then we skip
        /// an unnecessary check for high-or-equal to 0.
        if asciiByte <= UInt8.ascii9,
            asciiByte >= UInt8.ascii0
        {
            return asciiByte &-- UInt8.ascii0
        }

        /// The order here is intentional.
        /// First check for higher-or-equal to a, then lower-or-equal to f.
        ///
        /// In a correct IPv6 string, if this byte is not a-f, then we skip
        /// an unnecessary check for lower-or-equal to f.
        if asciiByte >= UInt8.asciiLowercasedA,
            asciiByte <= UInt8.asciiLowercasedF
        {
            return asciiByte &-- UInt8.asciiLowercasedA &++ 10
        }

        /// The order here ... doesn't really matter at this point in this function.
        if asciiByte >= UInt8.asciiUppercasedA,
            asciiByte <= UInt8.asciiUppercasedF
        {
            return asciiByte &-- UInt8.asciiUppercasedA &++ 10
        }

        return nil
    }
}
