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
    package init(from buffer: inout DNSBuffer) throws {
        self.anything = try buffer.readLengthPrefixedString(
            name: "NULL.anything",
            decodeLengthAs: UInt16.self
        )
    }
}

extension NULL {
    package func encode(into buffer: inout DNSBuffer) throws {
        try buffer.writeLengthPrefixedString(
            name: "NULL.anything",
            bytes: self.anything,
            maxLength: 65535,
            fitLengthInto: UInt16.self
        )
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension NULL: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .NULL(let null):
            self = null
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .NULL(self)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension NULL: Queryable {
    @inlinable
    public static var recordType: RecordType { .NULL }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
