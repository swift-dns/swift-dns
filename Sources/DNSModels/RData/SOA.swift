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
@available(macOS 9999, *)
public struct SOA {
    public let mName: Name
    public let rName: Name
    public let serial: UInt32
    public let refresh: Int32
    public let retry: Int32
    public let expire: Int32
    public let minimum: UInt32
}
