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
                var iterator = domainName.makeIterator()
                /// `DomainName.data` always only contains ASCII bytes
                let asciiSpan = ptr.bindMemory(to: UInt8.self).span

                var idx = 0
                while let position = iterator.nextLabelPositionInNameData() {
                    let range = position.startIndex..<(position.startIndex &+ position.length)
                    guard
                        let byte = UInt8(
                            decimalRepresentation: asciiSpan.extracting(unchecked: range)
                        )
                    else {
                        return nil
                    }

                    /// Unchecked because `idx` can't exceed `3` anyway
                    let shift = 8 &* (3 &- idx)
                    ipv4.address |= UInt32(byte) &<< shift

                    if idx == 3 {
                        if iterator.reachedEnd() {
                            /// We've had exactly enough labels, let's return
                            return ipv4
                        } else {
                            return nil
                        }
                    }

                    idx &+= 1
                }

                /// We had less than 4 labels, so this is an error
                return nil
            })
        else {
            return nil
        }

        self = result
    }
}
