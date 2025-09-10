@available(swiftDNSApplePlatforms 13, *)
extension UInt8 {
    /// Reads bytes like "127" as a `UInt8` into `address` at the given `byteIdx` (left to right).
    /// Returns `nil` if the `span` is invalid.
    @inlinable
    init?(decimalRepresentation span: Span<UInt8>) {
        let count = span.count

        if count == 0 {
            return nil
        }

        self = 0

        /// Unchecked because it must be in range of 1...
        let maxIdx = count &- 1

        for idx in 0..<count {
            /// Unchecked because both originate from `span.count`
            let indexInGroup = maxIdx &- idx
            /// Unchecked because `indexInGroup` is guaranteed to be in range of `0..<count`
            let utf8Byte = span[unchecked: indexInGroup]
            guard let decimalDigit = UInt8.mapUTF8ByteToUInt8(utf8Byte) else {
                return nil
            }

            let factor: UInt8
            switch idx {
            case 0: factor = 1
            case 1: factor = 10
            case 2: factor = 100
            default: return nil
            }

            let (value, overflew1) = decimalDigit.multipliedReportingOverflow(by: factor)
            if overflew1 { return nil }

            let (newByte, overflew2) = self.addingReportingOverflow(value)
            if overflew2 { return nil }

            self = newByte
        }
    }

    @inlinable
    static func mapUTF8ByteToUInt8(_ utf8Byte: UInt8) -> UInt8? {
        guard
            utf8Byte >= UInt8.ascii0,
            utf8Byte <= UInt8.ascii9
        else {
            return nil
        }
        return utf8Byte &- UInt8.ascii0
    }
}
