/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// 3.3.13. SOA RDATA format
///
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                     MNAME                     /
///     /                                               /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                     RNAME                     /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    SERIAL                     |
///     |                                               |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    REFRESH                    |
///     |                                               |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                     RETRY                     |
///     |                                               |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    EXPIRE                     |
///     |                                               |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                    MINIMUM                    |
///     |                                               |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// where:
///
/// SOA records cause no additional section processing.
///
/// All times are in units of seconds.
///
/// Most of these fields are pertinent only for name server maintenance
/// operations.  However, MINIMUM is used in all query operations that
/// retrieve RRs from a zone.  Whenever a RR is sent in a response to a
/// query, the TTL field is set to the maximum of the TTL field from the RR
/// and the MINIMUM field in the appropriate SOA.  Thus MINIMUM is a lower
/// bound on the TTL field for all RRs in a zone.  Note that this use of
/// MINIMUM should occur when the RRs are copied into the response and not
/// when the zone is loaded from a Zone File or via a zone transfer.  The
/// reason for this provision is to allow future dynamic update facilities to
/// change the SOA RR with known semantics.
/// ```
public struct SOA: Sendable {
    public var mName: DomainName
    public var rName: DomainName
    public var serial: UInt32
    public var refresh: Int32
    public var retry: Int32
    public var expire: Int32
    public var minimum: UInt32

    public init(
        mName: DomainName,
        rName: DomainName,
        serial: UInt32,
        refresh: Int32,
        retry: Int32,
        expire: Int32,
        minimum: UInt32
    ) {
        self.mName = mName
        self.rName = rName
        self.serial = serial
        self.refresh = refresh
        self.retry = retry
        self.expire = expire
        self.minimum = minimum
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension SOA {
    package init(from buffer: inout DNSBuffer) throws {
        self.mName = try DomainName(from: &buffer)
        self.rName = try DomainName(from: &buffer)
        self.serial = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("SOA.serial", buffer)
        )
        self.refresh = try buffer.readInteger(as: Int32.self).unwrap(
            or: .failedToRead("SOA.refresh", buffer)
        )
        self.retry = try buffer.readInteger(as: Int32.self).unwrap(
            or: .failedToRead("SOA.retry", buffer)
        )
        self.expire = try buffer.readInteger(as: Int32.self).unwrap(
            or: .failedToRead("SOA.expire", buffer)
        )
        self.minimum = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("SOA.minimum", buffer)
        )
    }
}

extension SOA {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.mName.encode(into: &buffer)
        try self.rName.encode(into: &buffer)
        buffer.writeInteger(self.serial)
        buffer.writeInteger(self.refresh)
        buffer.writeInteger(self.retry)
        buffer.writeInteger(self.expire)
        buffer.writeInteger(self.minimum)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension SOA: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .SOA(let soa):
            self = soa
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .SOA(self)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension SOA: Queryable {
    @inlinable
    public static var recordType: RecordType { .SOA }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
