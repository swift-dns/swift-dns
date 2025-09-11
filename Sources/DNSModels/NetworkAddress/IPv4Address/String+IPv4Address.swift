public import func DNSCore.debugOnly

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

                IPv4Address._writeUInt8AsDecimalASCII(
                    into: buffer,
                    advancingIdx: &resultIdx,
                    byte: addressBytes[3]
                )

                while let idx = iterator.next() {
                    buffer[resultIdx] = .asciiDot
                    resultIdx &+= 1
                    IPv4Address._writeUInt8AsDecimalASCII(
                        into: buffer,
                        advancingIdx: &resultIdx,
                        byte: addressBytes[3 &- idx]
                    )
                }
            }

            return resultIdx
        }
    }

    @inlinable
    static func _writeUInt8AsDecimalASCII(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        advancingIdx idx: inout Int,
        byte: UInt8
    ) {
        /// The compiler is smart enough to not actually do division by 10, but instead use the
        /// multiply-by-205-then-bitshift-by-11 trick.
        /// See it for yourself: https://godbolt.org/z/vYxTj78qd
        let (q, r1) = byte.quotientAndRemainder(dividingBy: 10)
        let (q2, r2) = q.quotientAndRemainder(dividingBy: 10)
        let r3 = q2 % 10

        var soFarAllZeros = true

        if r3 != 0 {
            soFarAllZeros = false
            _writeASCII(into: buffer, idx: &idx, byte: r3)
        }
        if !(r2 == 0 && soFarAllZeros) {
            _writeASCII(into: buffer, idx: &idx, byte: r2)
        }
        _writeASCII(into: buffer, idx: &idx, byte: r1)
    }

    @inlinable
    static func _writeASCII(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        idx: inout Int,
        byte: UInt8
    ) {
        buffer[idx] = byte &+ UInt8.ascii0
        idx &+= 1
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

        var span = span
        var byteIdx = 0

        /// This will make sure a valid ipv4 domain-name parses fine using this method
        while let nextSeparatorIdx = span.firstIndex(where: { $0 == .asciiDot }) {
            guard
                let byte = UInt8(
                    decimalRepresentation: span.extracting(unchecked: 0..<nextSeparatorIdx)
                )
            else {
                return nil
            }

            /// Unchecked because `byteIdx` can't exceed `3` anyway
            let shift = 8 &* (3 &- byteIdx)
            address |= UInt32(byte) &<< shift

            /// This is safe, nothing will crash with this increase in index
            /// Unchecked because it can't exceed `span.count` anyway
            span = span.extracting(unchecked: (nextSeparatorIdx &+ 1)..<span.count)

            /// Unchecked because it can't exceed `3` anyway
            byteIdx &+= 1

            if byteIdx == 3 {
                guard let byte = UInt8(decimalRepresentation: span) else {
                    return nil
                }

                address |= UInt32(byte)

                self.init(address)
                return
            }
        }

        /// Should not have reached here
        return nil
    }
}
