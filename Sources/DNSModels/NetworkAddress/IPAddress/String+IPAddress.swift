public import func DNSCore.debugOnly

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
    /// Initialize an IP address from its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    public init?(_ description: String) {
        self.init(utf8Span: description.utf8Span)
    }

    /// Initialize an IP address from its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    public init?(_ description: Substring) {
        self.init(utf8Span: description.utf8Span)
    }

    /// Initialize an IP address from a `UTF8Span` of its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
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
    /// Initialize an IP address from a `Span<UInt8>` of its textual representation.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    public init?(span: Span<UInt8>) {
        for idx in span.indices {
            if !span[unchecked: idx].isASCII {
                return nil
            }
        }

        self.init(_uncheckedASCIIspan: span)
    }

    /// Initialize an IP address from a `Span<UInt8>` of its textual representation.
    /// The provided **span is required to be ASCII**.
    /// For example `"192.168.1.98"` will parse into `.v4(192.168.1.98)`.
    /// and `"[2001:db8:1111::]"` will parse into `.v6(2001:DB8:1111:0:0:0:0:0)`,
    /// or in other words `.v6(0x2001_0DB8_1111_0000_0000_0000_0000_0000)`.
    @inlinable
    init?(_uncheckedASCIIspan span: Span<UInt8>) {
        debugOnly {
            for idx in span.indices {
                if !span[unchecked: idx].isASCII {
                    fatalError(
                        "IPAddress initializer should not be used with non-ASCII character: \(span[unchecked: idx])"
                    )
                }
            }
        }

        /// Finds the first either "." or ":" and based on that decide what IP version this could be.
        for idx in span.indices {
            let utf8Byte = span[unchecked: idx]
            switch utf8Byte {
            case .asciiDot:
                guard let ipv4 = IPv4Address(_uncheckedASCIIspan: span) else {
                    return nil
                }
                self = .v4(ipv4)
                return
            case .asciiColon:
                guard let ipv6 = IPv6Address(_uncheckedASCIIspan: span) else {
                    return nil
                }
                self = .v6(ipv6)
                return
            default:
                continue
            }
        }

        return nil
    }
}
