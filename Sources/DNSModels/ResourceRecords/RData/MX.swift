/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// 3.3.9. MX RDATA format
///
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                  PREFERENCE                   |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                   EXCHANGE                    /
///     /                                               /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// MX records cause type A additional section processing for the host
/// specified by EXCHANGE.  The use of MX RRs is explained in detail in
/// [RFC-974].
///
/// ```
public struct MX: Sendable {
    public var preference: UInt16
    public var exchange: DomainName

    public init(preference: UInt16, exchange: DomainName) {
        self.preference = preference
        self.exchange = exchange
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension MX {
    package init(from buffer: inout DNSBuffer) throws {
        self.preference = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("MX.preference", buffer)
        )
        self.exchange = try DomainName(from: &buffer)
    }
}

extension MX {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.preference)
        try self.exchange.encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension MX: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .MX(let mx):
            self = mx
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .MX(self)
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension MX: Queryable {
    @inlinable
    public static var recordType: RecordType { .MX }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
