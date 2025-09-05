public import SwiftIDNA

extension IPv4Address: CustomStringConvertible {
    /// The textual representation of an IPv4 address.
    @inlinable
    public var description: String {
        var result: String = ""
        /// TODO: Smarter reserving capacity
        result.reserveCapacity(7)
        withUnsafeBytes(of: self.address) {
            let range = 0..<4
            var iterator = range.makeIterator()

            let first = iterator.next().unsafelyUnwrapped
            /// TODO: This can be optimized to not have to convert to a string
            result.append(String($0[3 &- first]))

            while let idx = iterator.next() {
                result.append(".")
                /// TODO: This can be optimized to not have to convert to a string
                result.append(String($0[3 &- idx]))
            }
        }
        return result
    }
}

extension IPv4Address: LosslessStringConvertible {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// This implementation is IDNA compliant.
    /// That means the following addresses are considered equal: `₁₉₂｡₁₆₈｡₁｡₉₈`, `192.168.1.98`.
    @inlinable
    public init?(_ description: String) {
        var address: UInt32 = 0

        let scalars = description.unicodeScalars

        var byteIdx = 0
        var chunkStartIndex = scalars.startIndex
        let endIndex = scalars.endIndex

        /// We accept any of the 4 IDNA label separators (including `.`)
        /// This will make sure a valid ipv4 domain-name parses fine using this method
        while let nextSeparatorIdx = scalars[chunkStartIndex..<endIndex].firstIndex(
            where: \.isIDNALabelSeparator
        ) {
            guard
                IPv4Address._read(
                    into: &address,
                    scalarsGroup: scalars[chunkStartIndex..<nextSeparatorIdx],
                    byteIdx: byteIdx
                )
            else {
                return nil
            }

            /// This is safe, nothing will crash with this increase in index
            chunkStartIndex = scalars.index(nextSeparatorIdx, offsetBy: 1)

            byteIdx &+= 1

            if byteIdx == 3 {
                guard
                    IPv4Address._read(
                        into: &address,
                        scalarsGroup: scalars[chunkStartIndex..<endIndex],
                        byteIdx: byteIdx
                    )
                else {
                    return nil
                }

                self.init(address)
                return
            }
        }

        /// Should not have reached here
        return nil
    }

    @inlinable
    static func _read(
        into address: inout UInt32,
        scalarsGroup: String.UnicodeScalarView.SubSequence,
        byteIdx: Int
    ) -> Bool {
        let scalarsCount = scalarsGroup.count
        let maxIdx = scalarsCount &- 1

        var byte: UInt8 = 0
        var ignored = 0

        for idx in 0..<scalarsCount {
            let indexInGroup = scalarsGroup.index(
                scalarsGroup.startIndex,
                offsetBy: maxIdx &- idx
            )
            let scalar = scalarsGroup[indexInGroup]
            switch IPv4Address.mapScalarToUInt8(scalar) {
            case .valid(let decimalDigit):
                let factor: UInt8
                switch idx &- ignored {
                case 0: factor = 1
                case 1: factor = 10
                case 2: factor = 100
                default: return false
                }

                let (value, overflew1) = decimalDigit.multipliedReportingOverflow(by: factor)
                if overflew1 { return false }

                let (newByte, overflew2) = byte.addingReportingOverflow(value)
                if overflew2 { return false }

                byte = newByte
            case .invalid:
                return false
            case .ignore:
                let (newIgnored, overflew) = ignored.addingReportingOverflow(1)
                if overflew { return false }

                ignored = newIgnored

                continue
            }
        }
        /// This will catch `scalarsCount == 0` as well.
        if ignored == scalarsCount {
            return false
        }

        let shift = 8 &* (3 &- byteIdx)
        address |= UInt32(byte) &<< shift

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
        guard
            newValue >= Unicode.Scalar.asciiZero.value,
            newValue <= Unicode.Scalar.ascii9.value
        else {
            return .invalid
        }
        return .valid(UInt8(exactly: newValue &- Unicode.Scalar.asciiZero.value).unsafelyUnwrapped)
    }
}
