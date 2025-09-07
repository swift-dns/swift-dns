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

@available(swiftDNSApplePlatforms 26, *)
extension IPv4Address: LosslessStringConvertible {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(_ description: String) {
        var address: UInt32 = 0

        var utf8Span = description.utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }

        var span = utf8Span.span
        var byteIdx = 0

        /// This will make sure a valid ipv4 domain-name parses fine using this method
        while let nextSeparatorIdx = span.firstIndex(where: { $0 == .asciiDot }) {
            guard
                IPv4Address._read(
                    into: &address,
                    utf8Group: span.extracting(unchecked: 0..<nextSeparatorIdx),
                    byteIdx: byteIdx
                )
            else {
                return nil
            }

            /// This is safe, nothing will crash with this increase in index
            span = span.extracting(unchecked: (nextSeparatorIdx &+ 1)..<span.count)

            byteIdx &+= 1

            if byteIdx == 3 {
                guard
                    IPv4Address._read(
                        into: &address,
                        utf8Group: span,
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
        utf8Group: Span<UInt8>,
        byteIdx: Int
    ) -> Bool {
        let utf8Count = utf8Group.count

        if utf8Count == 0 {
            return false
        }

        var byte: UInt8 = 0

        let maxIdx = utf8Count &- 1

        for idx in 0..<utf8Count {
            let indexInGroup = maxIdx &- idx
            let utf8Byte = utf8Group[unchecked: indexInGroup]
            guard let decimalDigit = IPv4Address.mapUTF8ByteToUInt8(utf8Byte) else {
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
