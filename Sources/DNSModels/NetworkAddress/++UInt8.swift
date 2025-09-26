public import DNSCore

@available(swiftDNSApplePlatforms 13, *)
extension UInt8 {
    /// Reads a span of a text like "127" as a `UInt8`, if the bytes are in correct form.
    /// Otherwise returns `nil`.
    /// Equivalent to `UInt8(string, radix: 10)` but faster.
    @inlinable
    package init?(decimalRepresentation span: Span<UInt8>) {
        let count = span.count

        guard count > 0, count < 4 else {
            return nil
        }

        /// Unchecked because it must be in range of 1...3
        let maxIdx = count &-- 1

        guard let first = UInt8.mapUTF8ByteToUInt8(span[unchecked: maxIdx]) else {
            return nil
        }
        self = first

        if count > 1 {
            guard let second = UInt8.mapUTF8ByteToUInt8(span[unchecked: maxIdx &-- 1]) else {
                return nil
            }

            /// Unchecked because `(self == (0...9)) + (10 * (0...9))` is always in range of `0...99`,
            /// which is a valid `UInt8`.
            self &+== 10 &** second

            if count == 3 {
                /// `count == 3` means `maxIdx == 2`. So instead of
                /// `span[unchecked: maxIdx &-- 2]` we can directly go for `span[unchecked: 0]`.
                guard let third = UInt8.mapUTF8ByteToUInt8(span[unchecked: 0]) else {
                    return nil
                }

                let (value, overflew1) = third.multipliedReportingOverflow(by: 100)
                if overflew1 { return nil }

                let (newByte, overflew2) = self.addingReportingOverflow(value)
                if overflew2 { return nil }

                self = newByte
            }
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
        return utf8Byte &-- UInt8.ascii0
    }
}

extension UInt8 {
    @inlinable
    package func asDecimal(writeUTF8Byte: (UInt8) -> Void) {
        /// The compiler is smart enough to not actually do division by 10, but instead use the
        /// multiply-by-205-then-bitshift-by-11 trick.
        /// See it for yourself: https://godbolt.org/z/vYxTj78qd
        let (q, r1) = self.quotientAndRemainder(dividingBy: 10)
        let (q2, r2) = q.quotientAndRemainder(dividingBy: 10)
        let r3 = q2 % 10

        var soFarAllZeros = true

        if r3 != 0 {
            soFarAllZeros = false
            writeUTF8Byte(r3 &++ UInt8.ascii0)
        }
        if !(r2 == 0 && soFarAllZeros) {
            writeUTF8Byte(r2 &++ UInt8.ascii0)
        }
        writeUTF8Byte(r1 &++ UInt8.ascii0)
    }
}
