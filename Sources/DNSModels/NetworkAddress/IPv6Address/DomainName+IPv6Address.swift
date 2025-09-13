public import DNSCore

public import struct NIOCore.ByteBuffer

@available(swiftDNSApplePlatforms 26, *)
extension IPv6Address {
    /// Initialize an `IPv6Address` from a `DomainName`.
    /// The domain name must correspond to a valid IPv6 address.
    /// For example a domain name like `"::1"` will parse into the IPv6 address `::1`,
    /// or a domain name like `"2001:db8:1111::"` will parse into the IPv6 address `2001:DB8:1111:0:0:0:0:0`.
    @inlinable
    public init?(domainName: DomainName) {
        var iterator = domainName.makeIterator()
        guard
            let position = iterator.nextLabelPositionInNameData(),
            /// The domain name must contain exactly one label
            iterator.reachedEnd()
        else {
            return nil
        }
        let range = position.startIndex..<(position.startIndex &++ position.length)
        if let ipv6Address = domainName.data.withUnsafeReadableBytes({ ptr -> IPv6Address? in
            let span = ptr.bindMemory(to: UInt8.self).span
            return IPv6Address.init(
                /// `DomainName.data` always only contains ASCII bytes
                __uncheckedASCIIspan: span.extracting(unchecked: range)
            )
        }) {
            self = ipv6Address
            return
        }

        return nil
    }
}
