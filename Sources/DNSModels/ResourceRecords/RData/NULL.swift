package import struct NIOCore.ByteBuffer

/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// 3.3.10. NULL RDATA format (EXPERIMENTAL)
///
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                  <anything>                   /
///     /                                               /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// Anything at all may be in the RDATA field so long as it is 65535 octets
/// or less.
///
/// NULL records cause no additional section processing.  NULL RRs are not
/// allowed in Zone Files.  NULLs are used as placeholders in some
/// experimental extensions of the DNS.
/// ```
public struct NULL: Sendable {
    public var anything: [UInt8]

    public init(anything: [UInt8]) {
        self.anything = anything
    }
}

extension NULL {
    package init(from buffer: inout ByteBuffer) throws {
        self.anything = try buffer.readCharacterString(
            name: "NULL.anything",
            decodeCharacterLengthAs: UInt16.self
        )
    }
}

extension NULL {
    package func encode(into buffer: inout ByteBuffer) throws {
        try buffer.writeCharacterString(
            name: "NULL.anything",
            bytes: self.anything,
            maxLength: 65535,
            fitLengthInto: UInt16.self
        )
    }
}
