public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 26, *)
extension IPv6Address {
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result: IPv6Address = domainName.data.withUnsafeReadableBytes({ ptr in
                var iterator = domainName.makeIterator()
                guard let range = iterator.nextLabelPositionInNameData() else {
                    return nil
                }
                /// The domain name must contain exactly one label
                if iterator.reachedEnd() {
                    return IPv6Address.init(
                        /// `DomainName.data` always only contains ASCII bytes
                        _uncheckedASCIIspan: ptr.bindMemory(to: UInt8.self).span.extracting(
                            unchecked: range.startIndex..<(range.startIndex &+ range.length)
                        )
                    )
                } else {
                    return nil
                }
            })
        else {
            return nil
        }
        self = result
    }
}
