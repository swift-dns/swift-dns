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

    /// Whether or not this instance corresponds to the `v4` case.
    @inlinable
    public var isIPv4: Bool {
        switch self {
        case .v4:
            return true
        case .v6:
            return false
        }
    }

    /// Whether or not this instance corresponds to the `v6` case.
    @inlinable
    public var isIPv6: Bool {
        switch self {
        case .v6:
            return true
        case .v4:
            return false
        }
    }

    /// Whether this address is a Loopback address, known as localhost, or not.
    /// Equivalent to `127.0.0.0/8` in IPv4 CIDR notation or only the `::1` IP in IPv6 description format.
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
