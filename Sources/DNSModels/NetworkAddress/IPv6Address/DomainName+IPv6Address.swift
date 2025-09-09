public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 26, *)
extension IPv6Address {
    @inlinable
    public init?(domainName: DomainName) {
        guard
            let result = domainName.data.withUnsafeReadableBytes({ ptr -> IPv6Address? in
                var iterator = domainName.makeIterator()
                guard let position = iterator.nextLabelPositionInNameData() else {
                    return nil
                }
                let range = position.startIndex..<(position.startIndex &+ position.length)
                /// The domain name must contain exactly one label
                if iterator.reachedEnd() {
                    return IPv6Address.init(
                        /// `DomainName.data` always only contains ASCII bytes
                        _uncheckedASCIIspan: ptr.bindMemory(to: UInt8.self).span.extracting(
                            unchecked: range
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
