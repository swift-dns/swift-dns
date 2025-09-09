@available(swiftDNSApplePlatforms 15, *)
extension IPAddress: CustomStringConvertible {
    public var description: String {
        switch self {
        case .v4(let ipv4):
            return "v4(\(ipv4))"
        case .v6(let ipv6):
            return "v6(\(ipv6))"
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension IPAddress: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        /// Finds the first either "." or ":" and based on that decide what IP version this could be.
        let span = description.utf8Span.span
        for idx in span.indices {
            let utf8Byte = span[unchecked: idx]
            if utf8Byte == .asciiDot {
                guard let ipv4 = IPv4Address(description) else {
                    return nil
                }
                self = .v4(ipv4)
                return
            } else if utf8Byte == .asciiColon {
                guard let ipv6 = IPv6Address(description) else {
                    return nil
                }
                self = .v6(ipv6)
                return
            }
        }

        return nil
    }
}
