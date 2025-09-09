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
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(_ description: String) {
        self.init(utf8Span: description.utf8Span)
    }

    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(_ description: Substring) {
        self.init(utf8Span: description.utf8Span)
    }

    /// Initialize an IPv4 address from a `UTF8Span` of its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// For example `"192.168.1.98"` will parse into `192.168.1.98`.
    @inlinable
    public init?(utf8Span: UTF8Span) {
        var utf8Span = utf8Span
        guard utf8Span.checkForASCII() else {
            return nil
        }

        self.init(_uncheckedASCIIspan: utf8Span.span)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPAddress {
    @inlinable
    public init?(_uncheckedASCIIspan span: Span<UInt8>) {
        /// Finds the first either "." or ":" and based on that decide what IP version this could be.
        for idx in span.indices {
            let utf8Byte = span[unchecked: idx]
            if utf8Byte == .asciiDot {
                guard let ipv4 = IPv4Address(_uncheckedASCIIspan: span) else {
                    return nil
                }
                self = .v4(ipv4)
                return
            } else if utf8Byte == .asciiColon {
                guard let ipv6 = IPv6Address(_uncheckedASCIIspan: span) else {
                    return nil
                }
                self = .v6(ipv6)
                return
            }
        }

        return nil
    }
}
