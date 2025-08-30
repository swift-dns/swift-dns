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

    @inlinable
    public var isLoopback: Bool {
        switch self {
        case .v4(let ipv4):
            return ipv4.isLoopback
        case .v6(let ipv6):
            return ipv6.isLoopback
        }
    }

    @inlinable
    public var isMulticast: Bool {
        switch self {
        case .v4(let ipv4):
            return ipv4.isMulticast
        case .v6(let ipv6):
            return ipv6.isMulticast
        }
    }

    @inlinable
    public var isLinkLocalUnicast: Bool {
        switch self {
        case .v4(let ipv4):
            return ipv4.isLinkLocalUnicast
        case .v6(let ipv6):
            return ipv6.isLinkLocalUnicast
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

@available(swiftDNSApplePlatforms 15, *)
extension IPAddress: LosslessStringConvertible {
    public init?(_ description: String) {
        if let ipv4 = IPv4Address(description) {
            self = .v4(ipv4)
        } else if let ipv6 = IPv6Address(description) {
            self = .v6(ipv6)
        } else {
            return nil
        }
    }
}
