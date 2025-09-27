public import DNSCore

@available(swiftDNSApplePlatforms 13, *)
extension IPv4Address: CustomStringConvertible {
    /// The textual representation of an IPv4 address.
    @inlinable
    public var description: String {
        /// 15 is enough for the biggest possible IPv4Address description.
        /// For example for "255.255.255.255".
        /// Coincidentally, Swift's `_SmallString` supports up to 15 bytes, which helps make this
        /// implementation as fast as possible.
        String(unsafeUninitializedCapacity: 15) { buffer in
            var resultIdx = 0

            withUnsafeBytes(of: self.address) { addressBytes in
                let range = 1..<4
                var iterator = range.makeIterator()

                let byte = addressBytes[3]
                byte.asDecimal(
                    writeUTF8Byte: {
                        buffer[resultIdx] = $0
                        resultIdx &+== 1
                    }
                )

                while let idx = iterator.next() {
                    buffer[resultIdx] = .asciiDot
                    resultIdx &+== 1

                    let byte = addressBytes[3 &-- idx]
                    byte.asDecimal(
                        writeUTF8Byte: {
                            buffer[resultIdx] = $0
                            resultIdx &+== 1
                        }
                    )
                }
            }

            return resultIdx
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension IPv4Address: LosslessStringConvertible {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(_ description: String) {
        self.init(textualRepresentation: description.utf8Span)
    }

    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(_ description: Substring) {
        self.init(textualRepresentation: description.utf8Span)
    }

    /// Initialize an IPv4 address from a `UTF8Span` of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(textualRepresentation utf8Span: UTF8Span) {
        var utf8Span = utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }

        self.init(__uncheckedASCIIspan: utf8Span.span)
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension IPv4Address {
    /// Initialize an IPv4 address from a `Span<UInt8>` of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
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

    /// Initialize an IPv4 address from a `Span<UInt8>` of its textual representation.
    /// The provided **span is required to be ASCII**.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(__uncheckedASCIIspan span: Span<UInt8>) {
        debugOnly {
            for idx in span.indices {
                /// Unchecked because `idx` comes right from `span.indices`
                if !span[unchecked: idx].isASCII {
                    fatalError(
                        "IPv4Address initializer should not be used with non-ASCII character: \(span[unchecked: idx])"
                    )
                }
            }
        }

        var address: UInt32 = 0

        var currentSegment: UInt8 = 0
        var digitIdx: UInt8 = 0
        var segmentIdx: UInt8 = 0

        let spanLastIdx = span.count &-- 1
        for idx in span.indices {
            /// Unchecked because `idx` comes right from `span.indices`
            let backwardsIdx = spanLastIdx &-- idx
            /// Unchecked because `backwardsIdx` is guaranteed to be in range of `0...spanLastIdx`
            let byte = span[unchecked: backwardsIdx]

            switch byte {
            case .asciiDot:
                if segmentIdx > 3 || digitIdx == 0 {
                    return nil
                }

                /// segmentIdx is guaranteed to be in range of 0...3
                let shift = 8 &** segmentIdx
                address |= UInt32(currentSegment) &<<< shift

                currentSegment = 0
                digitIdx = 0
                segmentIdx &+== 1
            default:
                guard
                    byte >= UInt8.ascii0,
                    byte <= UInt8.ascii9
                else {
                    return nil
                }
                let byte = byte &-- UInt8.ascii0

                let multiplier: UInt8
                switch digitIdx {
                case 0: multiplier = 1
                case 1: multiplier = 10
                case 2: multiplier = 100
                default: return nil
                }

                let (multipliedByte, overflew1) = byte.multipliedReportingOverflow(
                    by: multiplier
                )
                if overflew1 {
                    return nil
                }

                let (newSegment, overflew2) = multipliedByte.addingReportingOverflow(
                    currentSegment
                )
                if overflew2 {
                    return nil
                }

                currentSegment = newSegment
                digitIdx &+== 1
            }
        }

        if segmentIdx == 3, digitIdx != 0 {
            address |= UInt32(currentSegment) &<<< 24
            self.address = address
        } else {
            return nil
        }
    }
}
