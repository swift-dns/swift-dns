package import struct NIOCore.ByteBuffer

/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987][rfc1035]
///
/// ```text
/// 3.3.2. HINFO RDATA format
///
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                      CPU                      /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                       OS                      /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// where:
///
/// CPU             A <character-string> which specifies the CPU type.
///
/// OS              A <character-string> which specifies the operating
///                 system type.
///
/// Standard values for CPU and OS can be found in [RFC-1010].
///
/// HINFO records are used to acquire general information about a host.  The
/// main use is for protocols such as FTP that can use special procedures
/// when talking between machines or operating systems of the same type.
/// ```
///
/// [rfc1035]: https://tools.ietf.org/html/rfc1035
public struct HINFO: Sendable {
    public var cpu: String
    public var os: String
}

extension HINFO {
    package init(from buffer: inout ByteBuffer) throws {
        self.cpu = try buffer.readCharacterStringAsString(name: "HINFO.cpu")
        self.os = try buffer.readCharacterStringAsString(name: "HINFO.os")
    }
}

extension HINFO {
    package func encode(into buffer: inout ByteBuffer) throws {
        try buffer.writeCharacterString(
            name: "HINFO.cpu",
            bytes: cpu.utf8,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
        try buffer.writeCharacterString(
            name: "HINFO.os",
            bytes: os.utf8,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
    }
}
