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

@available(swiftDNSApplePlatforms 10.15, *)
extension HINFO {
    package init(from buffer: inout DNSBuffer) throws {
        self.cpu = try buffer.readLengthPrefixedStringAsString(name: "HINFO.cpu")
        self.os = try buffer.readLengthPrefixedStringAsString(name: "HINFO.os")
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension HINFO {
    package func encode(into buffer: inout DNSBuffer) throws {
        try buffer.writeLengthPrefixedString(
            name: "HINFO.cpu",
            bytes: cpu.utf8,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
        try buffer.writeLengthPrefixedString(
            name: "HINFO.os",
            bytes: os.utf8,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension HINFO: RDataConvertible {
    @inlinable
    public static var recordType: RecordType { .HINFO }

    @inlinable
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .HINFO(let hinfo):
            self = hinfo
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .HINFO(self)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension HINFO: Queryable {
    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
