public import DNSCore

public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 26, *)
extension IPv4Address {
    /// Initialize an `IPv4Address` from a `DomainName`.
    /// The domain name must correspond to a valid IPv4 address.
    /// For example a domain name like `"127.0.0.1"` will parse into the IPv4 address `127.0.0.1`.
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result = domainName.data.withUnsafeReadableBytes({ ptr -> IPv4Address? in
                var ipv4 = IPv4Address(0)
                var iterator = domainName.makePositionIterator()
                /// `DomainName.data` always only contains ASCII bytes
                let asciiSpan = ptr.bindMemory(to: UInt8.self).span

                guard let position1 = iterator.next() else {
                    return nil
                }
                let range1 = position1.startIndex..<(position1.startIndex &++ position1.length)
                let byteSpan1 = asciiSpan.extracting(unchecked: range1)
                guard let byte1 = UInt8(decimalRepresentation: byteSpan1) else {
                    return nil
                }
                ipv4.address |= UInt32(byte1) &<<< 24

                guard let position2 = iterator.next() else {
                    return nil
                }
                let range2 = position2.startIndex..<(position2.startIndex &++ position2.length)
                let byteSpan2 = asciiSpan.extracting(unchecked: range2)
                guard let byte2 = UInt8(decimalRepresentation: byteSpan2) else {
                    return nil
                }
                ipv4.address |= UInt32(byte2) &<<< 16

                guard let position3 = iterator.next() else {
                    return nil
                }
                let range3 = position3.startIndex..<(position3.startIndex &++ position3.length)
                let byteSpan3 = asciiSpan.extracting(unchecked: range3)
                guard let byte3 = UInt8(decimalRepresentation: byteSpan3) else {
                    return nil
                }
                ipv4.address |= UInt32(byte3) &<<< 8

                guard let position4 = iterator.next() else {
                    return nil
                }
                let range4 = position4.startIndex..<(position4.startIndex &++ position4.length)
                let byteSpan4 = asciiSpan.extracting(unchecked: range4)
                guard let byte4 = UInt8(decimalRepresentation: byteSpan4) else {
                    return nil
                }
                ipv4.address |= UInt32(byte4)

                if iterator.reachedEnd() {
                    /// We've had exactly enough labels, let's return
                    return ipv4
                } else {
                    return nil
                }
            })
        else {
            return nil
        }

        self = result
    }

    /// Initialize an `IPv4Address` from a `DomainName`.
    /// The domain name must correspond to a valid IPv4 address.
    /// For example a domain name like `"127.0.0.1"` will parse into the IPv4 address `127.0.0.1`.
    @inlinable
    init?(
        __domainNameSpan asciiSpan: Span<UInt8>,
        iterator: inout DomainName.PositionIterator,
        firstRange: Range<Int>,
        expectingRightSquareBracketAtTheEnd: Bool
    ) {
        self.init(0)

        let byteSpan1 = asciiSpan.extracting(unchecked: firstRange)
        guard let byte1 = UInt8(decimalRepresentation: byteSpan1) else {
            return nil
        }
        self.address |= UInt32(byte1) &<<< 24

        guard let position2 = iterator.next() else {
            return nil
        }
        let range2 = position2.startIndex..<(position2.startIndex &++ position2.length)
        let byteSpan2 = asciiSpan.extracting(unchecked: range2)
        guard let byte2 = UInt8(decimalRepresentation: byteSpan2) else {
            return nil
        }
        self.address |= UInt32(byte2) &<<< 16

        guard let position3 = iterator.next() else {
            return nil
        }
        let range3 = position3.startIndex..<(position3.startIndex &++ position3.length)
        let byteSpan3 = asciiSpan.extracting(unchecked: range3)
        guard let byte3 = UInt8(decimalRepresentation: byteSpan3) else {
            return nil
        }
        self.address |= UInt32(byte3) &<<< 8

        guard let position4 = iterator.next() else {
            return nil
        }
        var endIndex = position4.startIndex &++ position4.length
        if expectingRightSquareBracketAtTheEnd {
            /// Domain name parts can't be empty based on contract, so this &--1 is safe
            guard asciiSpan[unchecked: endIndex &-- 1] == UInt8.asciiRightSquareBracket else {
                return nil
            }
            endIndex &-== 1
        }
        let range4 = position4.startIndex..<endIndex
        let byteSpan4 = asciiSpan.extracting(unchecked: range4)
        guard let byte4 = UInt8(decimalRepresentation: byteSpan4) else {
            return nil
        }
        self.address |= UInt32(byte4)

        if iterator.reachedEnd() {
            /// We've had exactly enough labels, let's return
            return
        } else {
            return nil
        }
    }
}
