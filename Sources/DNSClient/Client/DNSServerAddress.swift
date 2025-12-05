public import enum DNSModels.AnyIPAddress
public import struct DNSModels.DomainName
public import enum NIOCore.SocketAddress

/// FIXME: shouldn't expose SocketAddress as public
@available(swiftDNSApplePlatforms 10.15, *)
public enum DNSServerAddress: Hashable, Sendable {
    // We keep the IP address serialization precisely as it is in the URL.
    // Some platforms have quirks in their implementations of 'ntop', for example
    // writing IPv6 addresses as having embedded IPv4 sections (e.g. [::192.168.0.1] vs [::c0a8:1]).
    // This serialization includes square brackets, so it is safe to write next to a port number.
    // Note: `address` must have an explicit port.
    case ipAddress(serialization: AnyIPAddress, address: SocketAddress)
    case domain(domainName: DomainName, port: UInt16)
    case unixSocket(path: String)
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DNSServerAddress {
    /// The host name which will be send as an HTTP `Host` header.
    /// Only returns nil if the `self` is a `unixSocket`.
    var host: String? {
        switch self {
        case .ipAddress(let serialization, _): return serialization.description
        case .domain(let domainName, _): return domainName.description(format: .ascii)
        case .unixSocket: return nil
        }
    }

    /// The host name which will be send as an HTTP host header.
    /// Only returns nil if the `self` is a `unixSocket`.
    var port: Int? {
        switch self {
        case .ipAddress(_, let address): return address.port!
        case .domain(_, let port): return Int(port)
        case .unixSocket: return nil
        }
    }

    package func asSocketAddress() throws -> SocketAddress {
        switch self {
        case .ipAddress(_, let address):
            return address
        case .domain(let host, let port):
            return try SocketAddress(
                ipAddress: host.description(format: .ascii),
                port: Int(port)
            )
        case .unixSocket(let path):
            return try SocketAddress(unixDomainSocketPath: path)
        }
    }
}
