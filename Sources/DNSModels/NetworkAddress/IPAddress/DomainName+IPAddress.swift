public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 26, *)
extension IPAddress {
    /// Initialize an `IPAddress` from a `DomainName`.
    /// The domain name must correspond to a valid IP address.
    /// For example a domain name like `"127.0.0.1"` will parse into the IP address `.v4(127.0.0.1)`.
    /// Or a domain name like `"::1"` will parse into the IP address `.v6(::1)`,
    /// or a domain name like `"2001:db8:1111::"` will parse into the IP address `.v6(2001:DB8:1111:0:0:0:0:0)`.
    @inlinable
    public init?(domainName: DomainName) {
        var iterator = domainName.makeIterator()

        guard let position = iterator.nextLabelPositionInNameData() else {
            return nil
        }
        let range = position.startIndex..<(position.startIndex &+ position.length)

        guard
            let result = domainName.data.withUnsafeReadableBytes({ ptr -> IPAddress? in
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

                return nil
            })
        else {
            return nil
        }

        self = result
    }
}
