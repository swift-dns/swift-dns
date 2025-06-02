package import struct NIOCore.ByteBuffer

/// The DNS CNAME record type
///
/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// 3.3.1. CNAME RDATA format
///
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                     CNAME                     /
///     /                                               /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// where:
///
/// CNAME           A <domain-name> which specifies the canonical or primary
///                 name for the owner.  The owner name is an alias.
/// ```
public struct CNAME: Sendable {
    public var name: Name

    public init(name: Name) {
        self.name = name
    }
}

extension CNAME {
    package init(from buffer: inout ByteBuffer) throws {
        self.name = try Name(from: &buffer)
    }
}

extension CNAME {
    package func encode(into buffer: inout ByteBuffer) throws {
        try self.name.encode(into: &buffer)
    }
}
