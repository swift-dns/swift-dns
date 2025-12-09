public import struct NIOCore.ByteBuffer

/// [RFC 2535](https://tools.ietf.org/html/rfc2535#section-4), Domain DomainName System Security Extensions, March 1999
///
/// NOTE: RFC 2535 was obsoleted with 4034+, with the exception of the
///  usage for UPDATE, which is what this implementation is for.
///
/// ```text
/// 4.1 SIG RDATA Format
///
///  The RDATA portion of a SIG RR is as shown below.  The integrity of
///  the RDATA information is protected by the signature field.
///
///  1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |        type covered           |  algorithm    |     labels    |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |                         original TTL                          |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |                      signature expiration                     |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |                      signature inception                      |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |            key  tag           |                               |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+         signer's name         +
/// |                                                               /
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-/
/// /                                                               /
/// /                            signature                          /
/// /                                                               /
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
/// ```
/// [RFC 2931](https://tools.ietf.org/html/rfc2931), DNS Request and Transaction Signatures, September 2000
///
/// NOTE: 2931 updates SIG0 to clarify certain particulars...
///
/// ```text
/// RFC 2931                       DNS SIG(0)                 September 2000
///
/// 3. The SIG(0) Resource Record
///
///    The structure of and type number of SIG resource records (RRs) is
///    given in [RFC 2535] Section 4.1.  However all of Section 4.1.8.1 and
///    the parts of Sections 4.2 and 4.3 related to SIG(0) should be
///    considered replaced by the material below.  Any conflict between [RFC
///    2535] and this document concerning SIG(0) RRs should be resolved in
///    favor of this document.
///
///    For all transaction SIG(0)s, the signer field MUST be a name of the
///    originating host and there MUST be a KEY RR at that name with the
///    public key corresponding to the private key used to calculate the
///    signature.  (The host domain name used may be the inverse IP address
///    mapping name for an IP address of the host if the relevant KEY is
///    stored there.)
///
///    For all SIG(0) RRs, the owner name, class, TTL, and original TTL, are
///    meaningless.  The TTL fields SHOULD be zero and the CLASS field
///    SHOULD be ANY.  To conserve space, the owner name SHOULD be root (a
///    single zero octet).  When SIG(0) authentication on a response is
///    desired, that SIG RR MUST be considered the highest priority of any
///    additional information for inclusion in the response. If the SIG(0)
///    RR cannot be added without causing the message to be truncated, the
///    server MUST alter the response so that a SIG(0) can be included.
///    This response consists of only the question and a SIG(0) record, and
///    has the TC bit set and RCODE 0 (NOERROR).  The client should at this
///    point retry the request using TCP.
///
/// 3.1 Calculating Request and Transaction SIGs
///
///    A DNS request may be optionally signed by including one SIG(0)s at
///    the end of the query additional information section.  Such a SIG is
///    identified by having a "type covered" field of zero. It signs the
///    preceding DNS request message including DNS header but not including
///    the UDP/IP header and before the request RR counts have been adjusted
///    for the inclusions of the request SIG(0).
///
///    It is calculated by using a "data" (see [RFC 2535], Section 4.1.8) of
///    (1) the SIG's RDATA section entirely omitting (not just zeroing) the
///    signature subfield itself, (2) the DNS query messages, including DNS
///    header, but not the UDP/IP header and before the reply RR counts have
///    been adjusted for the inclusion of the SIG(0).  That is
///
///       data = RDATA | request - SIG(0)
///
///    where "|" is concatenation and RDATA is the RDATA of the SIG(0) being
///    calculated less the signature itself.
///
///    Similarly, a SIG(0) can be used to secure a response and the request
///    that produced it.  Such transaction signatures are calculated by
///    using a "data" of (1) the SIG's RDATA section omitting the signature
///    itself, (2) the entire DNS query message that produced this response,
///    including the query's DNS header but not its UDP/IP header, and (3)
///    the entire DNS response message, including DNS header but not the
///    UDP/IP header and before the response RR counts have been adjusted
///    for the inclusion of the SIG(0).
///
///    That is
///
///       data = RDATA | full query | response - SIG(0)
///
///    where "|" is concatenation and RDATA is the RDATA of the SIG(0) being
///    calculated less the signature itself.
///
///    Verification of a response SIG(0) (which is signed by the server host
///    key, not the zone key) by the requesting resolver shows that the
///    query and response were not tampered with in transit, that the
///    response corresponds to the intended query, and that the response
///    comes from the queried server.
///
///    In the case of a DNS message via TCP, a SIG(0) on the first data
///    packet is calculated with "data" as above and for each subsequent
///    packet, it is calculated as follows:
///
///       data = RDATA | DNS payload - SIG(0) | previous packet
///
///    where "|" is concatenations, RDATA is as above, and previous packet
///    is the previous DNS payload including DNS header and the SIG(0) but
///    not the TCP/IP header.  Support of SIG(0) for TCP is OPTIONAL.  As an
///    alternative, TSIG may be used after, if necessary, setting up a key
///    with TKEY [RFC 2930].
///
///    Except where needed to authenticate an update, TKEY, or similar
///    privileged request, servers are not required to check a request
///    SIG(0).
///
///    Note: requests and responses can either have a single TSIG or one
///    SIG(0) but not both a TSIG and a SIG(0).
///
/// 3.2 Processing Responses and SIG(0) RRs
///
///    If a SIG RR is at the end of the additional information section of a
///    response and has a type covered of zero, it is a transaction
///    signature covering the response and the query that produced the
///    response.  For TKEY responses, it MUST be checked and the message
///    rejected if the checks fail unless otherwise specified for the TKEY
///    mode in use.  For all other responses, it MAY be checked and the
///    message rejected if the checks fail.
///
///    If a response's SIG(0) check succeed, such a transaction
///    authentication SIG does NOT directly authenticate the validity any
///    data-RRs in the message.  However, it authenticates that they were
///    sent by the queried server and have not been diddled.  (Only a proper
///    SIG(0) RR signed by the zone or a key tracing its authority to the
///    zone or to static resolver configuration can directly authenticate
///
///    data-RRs, depending on resolver policy.) If a resolver or server does
///    not implement transaction and/or request SIGs, it MUST ignore them
///    without error where they are optional and treat them as failing where
///    they are required.
///
/// 3.3 SIG(0) Lifetime and Expiration
///
///    The inception and expiration times in SIG(0)s are for the purpose of
///    resisting replay attacks.  They should be set to form a time bracket
///    such that messages outside that bracket can be ignored.  In IP
///    networks, this time bracket should not normally extend further than 5
///    minutes into the past and 5 minutes into the future.
/// ```
public struct SIG: Sendable {
    public var typeCovered: RecordType
    public var algorithm: DNSSECAlgorithm
    public var numLabels: UInt8
    public var originalTTL: UInt32
    public var sigExpiration: UInt32
    public var sigInception: UInt32
    public var keyTag: UInt16
    public var signerName: DomainName
    public var sig: ByteBuffer

    public init(
        typeCovered: RecordType,
        algorithm: DNSSECAlgorithm,
        numLabels: UInt8,
        originalTTL: UInt32,
        sigExpiration: UInt32,
        sigInception: UInt32,
        keyTag: UInt16,
        signerName: DomainName,
        sig: ByteBuffer
    ) {
        self.typeCovered = typeCovered
        self.algorithm = algorithm
        self.numLabels = numLabels
        self.originalTTL = originalTTL
        self.sigExpiration = sigExpiration
        self.sigInception = sigInception
        self.keyTag = keyTag
        self.signerName = signerName
        self.sig = sig
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension SIG {
    package init(from buffer: inout DNSBuffer) throws {
        self.typeCovered = try RecordType(from: &buffer)
        self.algorithm = try DNSSECAlgorithm(from: &buffer)
        self.numLabels = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("SIG.numLabels", buffer)
        )
        self.originalTTL = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("SIG.originalTTL", buffer)
        )
        self.sigExpiration = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("SIG.sigExpiration", buffer)
        )
        self.sigInception = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("SIG.sigInception", buffer)
        )
        self.keyTag = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("SIG.keyTag", buffer)
        )
        self.signerName = try DomainName(from: &buffer)
        self.sig = buffer.readToEnd()
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension SIG {
    func encode(into buffer: inout DNSBuffer) throws {
        typeCovered.encode(into: &buffer)
        algorithm.encode(into: &buffer)
        buffer.writeInteger(numLabels)
        buffer.writeInteger(originalTTL)
        buffer.writeInteger(sigExpiration)
        buffer.writeInteger(sigInception)
        buffer.writeInteger(keyTag)
        // a `DomainName` is always ASCII lowercased anyway so no need to worry about that.
        try signerName.encode(into: &buffer)
        buffer.writeBuffer(sig)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension SIG: RDataConvertible {
    @inlinable
    public static var recordType: RecordType { .SIG }

    @inlinable
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.SIG(let sig)):
            self = sig
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .DNSSEC(.SIG(self))
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension SIG: Queryable {
    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
