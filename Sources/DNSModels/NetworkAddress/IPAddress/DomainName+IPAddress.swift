public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 26, *)
extension IPAddress {
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result = domainName.data.withUnsafeReadableBytes({ ptr -> IPAddress? in
                var iterator = domainName.makeIterator()

                guard let position = iterator.nextLabelPositionInNameData() else {
                    return nil
                }
                let range = position.startIndex..<(position.startIndex &+ position.length)

                let span = ptr.bindMemory(to: UInt8.self).span
                /// If it was only one label, then it must be an IPv6. Otherwise, it must be an IPv4.
                if iterator.reachedEnd() {
                    return IPv6Address(
                        /// `DomainName.data` always only contains ASCII bytes
                        _uncheckedASCIIspan: span.extracting(unchecked: range)
                    ).map { .v6($0) }
                } else {
                    var ipv4 = IPv4Address(0)

                    guard
                        IPv4Address._readASCIIBytes(
                            into: &ipv4.address,
                            /// `DomainName.data` always only contains ASCII bytes
                            utf8Group: span.extracting(unchecked: range),
                            byteIdx: 0
                        )
                    else {
                        return nil
                    }

                    var idx = 1
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
                                return .v4(ipv4)
                            } else {
                                return nil
                            }
                        }

                        idx &+= 1
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
