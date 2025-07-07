/// [RFC 4034, DNSSEC Resource Records, March 2005](https://tools.ietf.org/html/rfc4034#section-5)
///
/// ```text
/// 5.1.  DS RDATA Wire Format
///
///    The RDATA for a DS RR consists of a 2 octet Key Tag field, a 1 octet
///    Algorithm field, a 1 octet Digest Type field, and a Digest field.
///
///                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    |           Key Tag             |  Algorithm    |  Digest Type  |
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    /                                                               /
///    /                            Digest                             /
///    /                                                               /
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
/// 5.2.  Processing of DS RRs When Validating Responses
///
///    The DS RR links the authentication chain across zone boundaries, so
///    the DS RR requires extra care in processing.  The DNSKEY RR referred
///    to in the DS RR MUST be a DNSSEC zone key.  The DNSKEY RR Flags MUST
///    have Flags bit 7 set.  If the DNSKEY flags do not indicate a DNSSEC
///    zone key, the DS RR (and the DNSKEY RR it references) MUST NOT be
///    used in the validation process.
///
/// 5.3.  The DS RR Presentation Format
///
///    The presentation format of the RDATA portion is as follows:
///
///    The Key Tag field MUST be represented as an unsigned decimal integer.
///
///    The Algorithm field MUST be represented either as an unsigned decimal
///    integer or as an algorithm mnemonic specified in Appendix A.1.
///
///    The Digest Type field MUST be represented as an unsigned decimal
///    integer.
///
///    The Digest MUST be represented as a sequence of case-insensitive
///    hexadecimal digits.  Whitespace is allowed within the hexadecimal
///    text.
/// ```
public struct DS: Sendable {
    public var keyTag: UInt16
    public var algorithm: DNSSECAlgorithm
    public var digestType: DNSSECDigestType
    public var digest: [UInt8]

    public init(
        keyTag: UInt16,
        algorithm: DNSSECAlgorithm,
        digestType: DNSSECDigestType,
        digest: [UInt8]
    ) {
        self.keyTag = keyTag
        self.algorithm = algorithm
        self.digestType = digestType
        self.digest = digest
    }
}

extension DS {
    package init(from buffer: inout DNSBuffer) throws {
        self.keyTag = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("DS.keyTag", buffer)
        )
        self.algorithm = try DNSSECAlgorithm(from: &buffer)
        self.digestType = try DNSSECDigestType(from: &buffer)
        self.digest = buffer.readToEnd()
    }
}

extension DS {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.keyTag)
        self.algorithm.encode(into: &buffer)
        self.digestType.encode(into: &buffer)
        buffer.writeBytes(self.digest)
    }
}

extension DS: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.DS(let ds)):
            self = ds
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .DNSSEC(.DS(self))
    }
}

extension DS: Queryable {
    @inlinable
    public static var recordType: RecordType { .DS }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
