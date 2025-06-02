package import struct NIOCore.ByteBuffer

/// The DNS A record type, an IPv4 address
///
/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://datatracker.ietf.org/doc/html/rfc1035#section-3.4.1)
///
/// ```text
/// 3.4.1. A RDATA format
///
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    ADDRESS                    |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// where:
///
///     ADDRESS         A 32 bit Internet address.
///
///     Hosts that have multiple Internet addresses will have multiple A
///     records.
///
///     A records cause no additional section processing.  The RDATA section of
///     an A line in a master file is an Internet address expressed as four
///     decimal numbers separated by dots without any imbedded spaces (e.g.,
///     "10.2.0.52" or "192.0.5.6").
/// ```
public struct A: Sendable {
    public var value: IPv4Address

    public init(value: IPv4Address) {
        self.value = value
    }
}

extension A {
    package init(from buffer: inout ByteBuffer) throws {
        self.value = try IPv4Address(from: &buffer)
    }
}

extension A {
    package func encode(into buffer: inout ByteBuffer) {
        self.value.encode(into: &buffer)
    }
}
