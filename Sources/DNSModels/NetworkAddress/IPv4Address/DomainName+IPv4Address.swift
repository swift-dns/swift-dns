public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 26, *)
extension IPv4Address {
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result = domainName.data.withUnsafeReadableBytes({ ptr -> IPv4Address? in
                var ipv4 = IPv4Address(0)
                var iterator = domainName.makeIterator()
                let span = ptr.bindMemory(to: UInt8.self).span

                var idx = 0
                while let position = iterator.nextLabelPositionInNameData() {
                    let range = position.startIndex..<(position.startIndex &+ position.length)
                    guard
                        IPv4Address._readASCIIBytes(
                            into: &ipv4.address,
                            /// `DomainName.data` always only contains ASCII bytes
                            utf8Group: span.extracting(unchecked: range),
                            byteIdx: idx
                        )
                    else {
                        return nil
                    }

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
