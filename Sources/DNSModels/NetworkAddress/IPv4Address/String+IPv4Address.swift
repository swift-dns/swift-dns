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
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(_ description: String) {
        var address: UInt32 = 0

        let scalars = description.unicodeScalars

        var byteIdx = 0
        var chunkStartIndex = scalars.startIndex
        let endIndex = scalars.endIndex

        /// We accept any of the 4 IDNA label separators (including `.`)
        /// This will make sure a valid ipv4 domain-name parses fine using this method
        while let nextSeparatorIdx = scalars[chunkStartIndex..<endIndex].firstIndex(where: {
            $0 == .asciiDot
        }) {
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

        if scalarsCount == 0 {
            return false
        }

        var byte: UInt8 = 0

        let maxIdx = scalarsCount &- 1
        let startIndex = scalarsGroup.startIndex

        for idx in 0..<scalarsCount {
            let indexInGroup = scalarsGroup.index(
                startIndex,
                offsetBy: maxIdx - idx
            )
            let scalar = scalarsGroup[indexInGroup]
            guard let decimalDigit = IPv4Address.mapScalarToUInt8(scalar) else {
                return false
            }

            let factor: UInt8
            switch idx {
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
        }

        let shift = 8 &* (3 &- byteIdx)
        address |= UInt32(byte) &<< shift

        return true
    }

    @inlinable
    static func mapScalarToUInt8(_ scalar: Unicode.Scalar) -> UInt8? {
        let newValue = scalar.value
        guard
            newValue >= Unicode.Scalar.asciiZero.value,
            newValue <= Unicode.Scalar.ascii9.value
        else {
            return nil
        }
        return UInt8(
            exactly: newValue &- Unicode.Scalar.asciiZero.value
        ).unsafelyUnwrapped
    }
}
