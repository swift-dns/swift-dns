public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 26, *)
extension IPv4Address {
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result: IPv4Address = domainName.data.withUnsafeReadableBytes({ ptr in
                var ipv4 = IPv4Address(0)
                let span = ptr.bindMemory(to: UInt8.self).span

                var iterator = domainName.makeIterator()
                if let position = iterator.nextLabelPositionInNameData() {
                    guard
                        IPv4Address._readASCIIBytes(
                            into: &ipv4.address,
                            /// `DomainName.data` always only contains ASCII bytes
                            utf8Group: span.extracting(
                                unchecked: position
                                    .startIndex..<(position.startIndex &+ position.length)
                            ),
                            byteIdx: 0
                        )
                    else {
                        return nil
                    }
                }

                if let position = iterator.nextLabelPositionInNameData() {
                    guard
                        IPv4Address._readASCIIBytes(
                            into: &ipv4.address,
                            /// `DomainName.data` always only contains ASCII bytes
                            utf8Group: span.extracting(
                                unchecked: position
                                    .startIndex..<(position.startIndex &+ position.length)
                            ),
                            byteIdx: 1
                        )
                    else {
                        return nil
                    }
                }

                if let position = iterator.nextLabelPositionInNameData() {
                    guard
                        IPv4Address._readASCIIBytes(
                            into: &ipv4.address,
                            /// `DomainName.data` always only contains ASCII bytes
                            utf8Group: span.extracting(
                                unchecked: position
                                    .startIndex..<(position.startIndex &+ position.length)
                            ),
                            byteIdx: 2
                        )
                    else {
                        return nil
                    }
                }

                if let position = iterator.nextLabelPositionInNameData() {
                    guard
                        IPv4Address._readASCIIBytes(
                            into: &ipv4.address,
                            /// `DomainName.data` always only contains ASCII bytes
                            utf8Group: span.extracting(
                                unchecked: position
                                    .startIndex..<(position.startIndex &+ position.length)
                            ),
                            byteIdx: 3
                        )
                    else {
                        return nil
                    }

                    if iterator.reachedEnd() {
                        /// We've had exactly enough labels, let's return
                        return ipv4
                    } else {
                        return nil
                    }
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
