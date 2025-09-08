/// An IP address, either IPv4 or IPv6.
///
/// This enum can contain either an `IPv4Address` or an `IPv6Address`, see their
/// respective documentation for more details.
@available(swiftDNSApplePlatforms 15, *)
public enum IPAddress: Sendable, Hashable {
    /// An IPv4 address.
    case v4(IPv4Address)
    /// An IPv6 address.
    case v6(IPv6Address)

    /// Whether this address is the Loopback address, known as localhost, or not.
    /// Equivalent to 127.0.0.0/8` in IPv4 CIDR notation or only the `::1` IP in IPv6 description format.
    /// See the dedicated `IPv4Address` and `IPv6Address` `isLoopback` comments for more info.
    @inlinable
    public var isLoopback: Bool {
        switch self {
        case .v4(let ipv4):
            return ipv4.isLoopback
        case .v6(let ipv6):
            return ipv6.isLoopback
        }
    }

    /// Whether this address is a Multicast address, or not.
    /// Equivalent to `224.0.0.0/4` in IPv4 CIDR notation or `FF00::/120` in IPv6 CIDR notation.
    /// See the dedicated `IPv4Address` and `IPv6Address` `isMulticast` comments for more info.
    @inlinable
    public var isMulticast: Bool {
        switch self {
        case .v4(let ipv4):
            return ipv4.isMulticast
        case .v6(let ipv6):
            return ipv6.isMulticast
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension IPAddress: CustomStringConvertible {
    public var description: String {
        switch self {
        case .v4(let ipv4):
            return ipv4.description
        case .v6(let ipv6):
            return ipv6.description
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension IPAddress: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        /// Finds the first either "." or ":" and based on that decide what IP version this must be.
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
