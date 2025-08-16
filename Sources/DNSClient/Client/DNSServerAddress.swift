public import enum NIOCore.SocketAddress
public import enum DNSModels.IPAddress
public import struct DNSModels.Name

/// FIXME: shouldn't expose SocketAddress as public
@available(swiftDNSApplePlatforms 26, *)
public enum DNSServerAddress: Hashable, Sendable {
    // We keep the IP address serialization precisely as it is in the URL.
    // Some platforms have quirks in their implementations of 'ntop', for example
    // writing IPv6 addresses as having embedded IPv4 sections (e.g. [::192.168.0.1] vs [::c0a8:1]).
    // This serialization includes square brackets, so it is safe to write next to a port number.
    // Note: `address` must have an explicit port.
    case ipAddress(serialization: IPAddress, address: SocketAddress)
    case domain(name: Name, port: UInt16)
    case unixSocket(path: String)

    // init(remoteHost: String, port: Int) {
    //     if let addr = try? SocketAddress(ipAddress: remoteHost, port: port) {
    //         switch addr {
    //         case .v6:
    //             self = .ipAddress(serialization: "[\(remoteHost.description)]", address: addr)
    //         case .v4:
    //             self = .ipAddress(serialization: remoteHost.description, address: addr)
    //         case .unixDomainSocket:
    //             fatalError("Expected a remote host")
    //         }
    //     } else {
    //         precondition(
    //             !remoteHost.isEmpty,
    //             "Empty remote hostname \(remoteHost)"
    //         )
    //         self = .domain(name: remoteHost, port: port)
    //     }
    // }
}

@available(swiftDNSApplePlatforms 26, *)
extension DNSServerAddress {
    /// The host name which will be send as an HTTP `Host` header.
    /// Only returns nil if the `self` is a `unixSocket`.
    var host: String? {
        switch self {
        case .ipAddress(let serialization, _): return serialization.description
        case .domain(let name, _): return name.description(format: .ascii)
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

    func asSocketAddress() throws -> SocketAddress {
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
