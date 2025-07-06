/// [RFC 4034](https://tools.ietf.org/html/rfc4034#section-4), DNSSEC Resource Records, March 2005
///
/// ```text
/// 4.1.  NSEC RDATA Wire Format
///
///    The RDATA of the NSEC RR is as shown below:
///
///                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    /                      Next Domain Name                         /
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    /                       Type Bit Maps                           /
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
/// 4.1.3.  Inclusion of Wildcard Names in NSEC RDATA
///
///    If a wildcard owner name appears in a zone, the wildcard label ("*")
///    is treated as a literal symbol and is treated the same as any other
///    owner name for the purposes of generating NSEC RRs.  Wildcard owner
///    names appear in the Next Domain Name field without any wildcard
///    expansion.  [RFC4035] describes the impact of wildcards on
///    authenticated denial of existence.
/// ```
public struct NSEC: Sendable {
    public var nextDomainName: Name
    public var typeBitMaps: RecordTypeSet

    public init(nextDomainName: Name, typeBitMaps: RecordTypeSet) {
        self.nextDomainName = nextDomainName
        self.typeBitMaps = typeBitMaps
    }
}

extension NSEC {
    package init(from buffer: inout DNSBuffer) throws {
        self.nextDomainName = try Name(from: &buffer)
        self.typeBitMaps = try RecordTypeSet(from: &buffer)
    }
}

extension NSEC {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.nextDomainName.encode(into: &buffer)
        self.typeBitMaps.encode(into: &buffer)
    }
}

extension NSEC: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.NSEC(let nsec)):
            self = nsec
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .DNSSEC(.NSEC(self))
    }
}
