/// Record data enum variants for DNSSEC-specific records.
public enum DNSSECRData: Sendable {
    /// ```text
    /// RFC 7344              Delegation Trust Maintenance        September 2014
    ///
    /// 3.2.  CDNSKEY Resource Record Format
    ///
    ///    The wire and presentation format of the CDNSKEY ("Child DNSKEY")
    ///    resource record is identical to the DNSKEY record.  IANA has
    ///    allocated RR code 60 for the CDNSKEY resource record via Expert
    ///    Review.  The CDNSKEY RR uses the same registries as DNSKEY for its
    ///    fields.
    ///
    ///    No special processing is performed by authoritative servers or by
    ///    resolvers, when serving or resolving.  For all practical purposes,
    ///    CDNSKEY is a regular RR type.
    /// ```
    case CDNSKEY(CDNSKEY)

    /// ```text
    /// RFC 7344              Delegation Trust Maintenance        September 2014
    ///
    /// 3.1.  CDS Resource Record Format
    ///    The wire and presentation format of the Child DS (CDS) resource
    ///    record is identical to the DS record [RFC4034].  IANA has allocated
    ///    RR code 59 for the CDS resource record via Expert Review
    ///    [DNS-TRANSPORT].  The CDS RR uses the same registries as DS for its
    ///    fields.
    ///
    ///    No special processing is performed by authoritative servers or by
    ///    resolvers, when serving or resolving.  For all practical purposes,
    ///    CDS is a regular RR type.
    /// ```
    case CDS(CDS)

    /// ```text
    /// RFC 4034                DNSSEC Resource Records               March 2005
    ///
    /// 2.1.  DNSKEY RDATA Wire Format
    ///
    ///    The RDATA for a DNSKEY RR consists of a 2 octet Flags Field, a 1
    ///    octet Protocol Field, a 1 octet Algorithm Field, and the Public Key
    ///    Field.
    ///
    ///                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |              Flags            |    Protocol   |   Algorithm   |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    /                                                               /
    ///    /                            Public Key                         /
    ///    /                                                               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///
    /// 2.1.1.  The Flags Field
    ///
    ///    Bit 7 of the Flags field is the Zone Key flag.  If bit 7 has value 1,
    ///    then the DNSKEY record holds a DNS zone key, and the DNSKEY RR's
    ///    owner name MUST be the name of a zone.  If bit 7 has value 0, then
    ///    the DNSKEY record holds some other type of DNS public key and MUST
    ///    NOT be used to verify RRSIGs that cover RRsets.
    ///
    ///    Bit 15 of the Flags field is the Secure Entry Point flag, described
    ///    in [RFC3757].  If bit 15 has value 1, then the DNSKEY record holds a
    ///    key intended for use as a secure entry point.  This flag is only
    ///    intended to be a hint to zone signing or debugging software as to the
    ///    intended use of this DNSKEY record; validators MUST NOT alter their
    ///    behavior during the signature validation process in any way based on
    ///    the setting of this bit.  This also means that a DNSKEY RR with the
    ///    SEP bit set would also need the Zone Key flag set in order to be able
    ///    to generate signatures legally.  A DNSKEY RR with the SEP set and the
    ///    Zone Key flag not set MUST NOT be used to verify RRSIGs that cover
    ///    RRsets.
    ///
    ///    Bits 0-6 and 8-14 are reserved: these bits MUST have value 0 upon
    ///    creation of the DNSKEY RR and MUST be ignored upon receipt.
    ///
    /// RFC 5011                  Trust Anchor Update             September 2007
    ///
    /// 7.  IANA Considerations
    ///
    ///   The IANA has assigned a bit in the DNSKEY flags field (see Section 7
    ///   of [RFC4034]) for the REVOKE bit (8).
    /// ```
    case DNSKEY(DNSKEY)

    /// ```text
    /// 5.1.  DS RDATA Wire Format
    ///
    /// The RDATA for a DS RR consists of a 2 octet Key Tag field, a 1 octet
    ///           Algorithm field, a 1 octet Digest Type field, and a Digest field.
    ///
    ///                          1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///     |           Key Tag             |  Algorithm    |  Digest Type  |
    ///     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///     /                                                               /
    ///     /                            Digest                             /
    ///     /                                                               /
    ///     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///
    /// 5.1.1.  The Key Tag Field
    ///
    ///    The Key Tag field lists the key tag of the DNSKEY RR referred to by
    ///    the DS record, in network byte order.
    ///
    ///    The Key Tag used by the DS RR is identical to the Key Tag used by
    ///    RRSIG RRs.  Appendix B describes how to compute a Key Tag.
    ///
    /// 5.1.2.  The Algorithm Field
    ///
    ///    The Algorithm field lists the algorithm number of the DNSKEY RR
    ///    referred to by the DS record.
    ///
    ///    The algorithm number used by the DS RR is identical to the algorithm
    ///    number used by RRSIG and DNSKEY RRs.  Appendix A.1 lists the
    ///    algorithm number types.
    ///
    /// 5.1.3.  The Digest Type Field
    ///
    ///    The DS RR refers to a DNSKEY RR by including a digest of that DNSKEY
    ///    RR.  The Digest Type field identifies the algorithm used to construct
    ///    the digest.  Appendix A.2 lists the possible digest algorithm types.
    ///
    /// 5.1.4.  The Digest Field
    ///
    ///    The DS record refers to a DNSKEY RR by including a digest of that
    ///    DNSKEY RR.
    ///
    ///    The digest is calculated by concatenating the canonical form of the
    ///    fully qualified owner name of the DNSKEY RR with the DNSKEY RDATA,
    ///    and then applying the digest algorithm.
    ///
    ///      digest = digest_algorithm( DNSKEY owner name | DNSKEY RDATA);
    ///
    ///       "|" denotes concatenation
    ///
    ///      DNSKEY RDATA = Flags | Protocol | Algorithm | Public Key.
    ///
    ///    The size of the digest may vary depending on the digest algorithm and
    ///    DNSKEY RR size.  As of the time of this writing, the only defined
    ///    digest algorithm is SHA-1, which produces a 20 octet digest.
    /// ```
    case DS(DS)

    /// ```text
    /// RFC 2535                DNS Security Extensions               March 1999
    ///
    /// 3.1 KEY RDATA format
    ///
    ///  The RDATA for a KEY RR consists of flags, a protocol octet, the
    ///  algorithm number octet, and the public key itself.  The format is as
    ///  follows:
    ///
    ///                       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  |             flags             |    protocol   |   algorithm   |
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  |                                                               /
    ///  /                          public key                           /
    ///  /                                                               /
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
    ///
    ///  The KEY RR is not intended for storage of certificates and a separate
    ///  certificate RR has been developed for that purpose, defined in [RFC
    ///  2538].
    ///
    ///  The meaning of the KEY RR owner name, flags, and protocol octet are
    ///  described in Sections 3.1.1 through 3.1.5 below.  The flags and
    ///  algorithm must be examined before any data following the algorithm
    ///  octet as they control the existence and format of any following data.
    ///  The algorithm and public key fields are described in Section 3.2.
    ///  The format of the public key is algorithm dependent.
    ///
    ///  KEY RRs do not specify their validity period but their authenticating
    ///  SIG RR(s) do as described in Section 4 below.
    /// ```
    case KEY(KEY)

    /// ```text
    /// RFC 4034                DNSSEC Resource Records               March 2005
    ///
    /// 4.1.  NSEC RDATA Wire Format
    ///
    ///  The RDATA of the NSEC RR is as shown below:
    ///
    ///                       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  /                      Next Domain DomainName                         /
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  /                       Type Bit Maps                           /
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// ```
    case NSEC(NSEC)

    /// ```text
    /// RFC 5155                         NSEC3                        March 2008
    ///
    /// 3.2.  NSEC3 RDATA Wire Format
    ///
    ///  The RDATA of the NSEC3 RR is as shown below:
    ///
    ///                       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  |   Hash Alg.   |     Flags     |          Iterations           |
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  |  Salt Length  |                     Salt                      /
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  |  Hash Length  |             Next Hashed Owner DomainName            /
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  /                         Type Bit Maps                         /
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///
    ///  Hash Algorithm is a single octet.
    ///
    ///  Flags field is a single octet, the Opt-Out flag is the least
    ///  significant bit, as shown below:
    ///
    ///   0 1 2 3 4 5 6 7
    ///  +-+-+-+-+-+-+-+-+
    ///  |             |O|
    ///  +-+-+-+-+-+-+-+-+
    ///
    ///  Iterations is represented as a 16-bit unsigned integer, with the most
    ///  significant bit first.
    ///
    ///  Salt Length is represented as an unsigned octet.  Salt Length
    ///  represents the length of the Salt field in octets.  If the value is
    ///  zero, the following Salt field is omitted.
    ///
    ///  Salt, if present, is encoded as a sequence of binary octets.  The
    ///  length of this field is determined by the preceding Salt Length
    ///  field.
    ///
    ///  Hash Length is represented as an unsigned octet.  Hash Length
    ///  represents the length of the Next Hashed Owner DomainName field in octets.
    ///
    ///  The next hashed owner name is not base32 encoded, unlike the owner
    ///  name of the NSEC3 RR.  It is the unmodified binary hash value.  It
    ///  does not include the name of the containing zone.  The length of this
    ///  field is determined by the preceding Hash Length field.
    ///
    /// 3.2.1.  Type Bit Maps Encoding
    ///
    ///  The encoding of the Type Bit Maps field is the same as that used by
    ///  the NSEC RR, described in [RFC4034].  It is explained and clarified
    ///  here for clarity.
    ///
    ///  The RR type space is split into 256 window blocks, each representing
    ///  the low-order 8 bits of the 16-bit RR type space.  Each block that
    ///  has at least one active RR type is encoded using a single octet
    ///  window number (from 0 to 255), a single octet bitmap length (from 1
    ///  to 32) indicating the number of octets used for the bitmap of the
    ///  window block, and up to 32 octets (256 bits) of bitmap.
    ///
    ///  Blocks are present in the NSEC3 RR RDATA in increasing numerical
    ///  order.
    ///
    ///     Type Bit Maps Field = ( Window Block # | Bitmap Length | Bitmap )+
    ///
    ///     where "|" denotes concatenation.
    ///
    ///  Each bitmap encodes the low-order 8 bits of RR types within the
    ///  window block, in network bit order.  The first bit is bit 0.  For
    ///  window block 0, bit 1 corresponds to RR type 1 (A), bit 2 corresponds
    ///  to RR type 2 (NS), and so forth.  For window block 1, bit 1
    ///  corresponds to RR type 257, bit 2 to RR type 258.  If a bit is set to
    ///  1, it indicates that an RRSet of that type is present for the
    ///  original owner name of the NSEC3 RR.  If a bit is set to 0, it
    ///  indicates that no RRSet of that type is present for the original
    ///  owner name of the NSEC3 RR.
    ///
    ///  Since bit 0 in window block 0 refers to the non-existing RR type 0,
    ///  it MUST be set to 0.  After verification, the validator MUST ignore
    ///  the value of bit 0 in window block 0.
    ///
    ///  Bits representing Meta-TYPEs or QTYPEs as specified in Section 3.1 of
    ///  [RFC2929] or within the range reserved for assignment only to QTYPEs
    ///  and Meta-TYPEs MUST be set to 0, since they do not appear in zone
    ///  data.  If encountered, they must be ignored upon reading.
    ///
    ///  Blocks with no types present MUST NOT be included.  Trailing zero
    ///  octets in the bitmap MUST be omitted.  The length of the bitmap of
    ///  each block is determined by the type code with the largest numerical
    ///  value, within that block, among the set of RR types present at the
    ///  original owner name of the NSEC3 RR.  Trailing octets not specified
    ///  MUST be interpreted as zero octets.
    /// ```
    case NSEC3(NSEC3)

    /// ```text
    /// RFC 5155                         NSEC3                        March 2008
    ///
    /// 4.2.  NSEC3PARAM RDATA Wire Format
    ///
    ///  The RDATA of the NSEC3PARAM RR is as shown below:
    ///
    ///                       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  |   Hash Alg.   |     Flags     |          Iterations           |
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///  |  Salt Length  |                     Salt                      /
    ///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///
    ///  Hash Algorithm is a single octet.
    ///
    ///  Flags field is a single octet.
    ///
    ///  Iterations is represented as a 16-bit unsigned integer, with the most
    ///  significant bit first.
    ///
    ///  Salt Length is represented as an unsigned octet.  Salt Length
    ///  represents the length of the following Salt field in octets.  If the
    ///  value is zero, the Salt field is omitted.
    ///
    ///  Salt, if present, is encoded as a sequence of binary octets.  The
    ///  length of this field is determined by the preceding Salt Length
    ///  field.
    /// ```
    case NSEC3PARAM(NSEC3PARAM)

    /// ```text
    /// RFC 2535 & 2931   DNS Security Extensions               March 1999
    /// RFC 4034          DNSSEC Resource Records               March 2005
    ///
    /// 3.1.  RRSIG RDATA Wire Format
    ///
    ///    The RDATA for an RRSIG RR consists of a 2 octet Type Covered field, a
    ///    1 octet Algorithm field, a 1 octet Labels field, a 4 octet Original
    ///    TTL field, a 4 octet Signature Expiration field, a 4 octet Signature
    ///    Inception field, a 2 octet Key tag, the Signer's DomainName field, and the
    ///    Signature field.
    ///
    ///                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |        Type Covered           |  Algorithm    |     Labels    |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |                         Original TTL                          |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |                      Signature Expiration                     |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |                      Signature Inception                      |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |            Key Tag            |                               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+         Signer's DomainName         /
    ///    /                                                               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    /                                                               /
    ///    /                            Signature                          /
    ///    /                                                               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// ```
    case RRSIG(RRSIG)

    /// ```text
    /// RFC 2535 & 2931   DNS Security Extensions               March 1999
    /// RFC 4034          DNSSEC Resource Records               March 2005
    ///
    /// 3.1.  RRSIG RDATA Wire Format
    ///
    ///    The RDATA for an RRSIG RR consists of a 2 octet Type Covered field, a
    ///    1 octet Algorithm field, a 1 octet Labels field, a 4 octet Original
    ///    TTL field, a 4 octet Signature Expiration field, a 4 octet Signature
    ///    Inception field, a 2 octet Key tag, the Signer's DomainName field, and the
    ///    Signature field.
    ///
    ///                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |        Type Covered           |  Algorithm    |     Labels    |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |                         Original TTL                          |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |                      Signature Expiration                     |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |                      Signature Inception                      |
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    |            Key Tag            |                               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+         Signer's DomainName         /
    ///    /                                                               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///    /                                                               /
    ///    /                            Signature                          /
    ///    /                                                               /
    ///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /// ```
    case SIG(SIG)

    /// [RFC 8945, Secret Key Transaction Authentication for DNS](https://tools.ietf.org/html/rfc8945#section-4.2)
    ///
    /// ```text
    /// 4.2.  TSIG Record Format
    ///
    ///   The fields of the TSIG RR are described below.  All multi-octet
    ///   integers in the record are sent in network byte order (see
    ///   Section 2.3.2 of [RFC1035]).
    ///
    ///   NAME:  The name of the key used, in domain name syntax.  The name
    ///      should reflect the names of the hosts and uniquely identify the
    ///      key among a set of keys these two hosts may share at any given
    ///      time.  For example, if hosts A.site.example and B.example.net
    ///      share a key, possibilities for the key name include
    ///      <id>.A.site.example, <id>.B.example.net, and
    ///      <id>.A.site.example.B.example.net.  It should be possible for more
    ///      than one key to be in simultaneous use among a set of interacting
    ///      hosts.  This allows for periodic key rotation as per best
    ///      operational practices, as well as algorithm agility as indicated
    ///      by [RFC7696].
    ///
    ///      The name may be used as a local index to the key involved, but it
    ///      is recommended that it be globally unique.  Where a key is just
    ///      shared between two hosts, its name actually need only be
    ///      meaningful to them, but it is recommended that the key name be
    ///      mnemonic and incorporate the names of participating agents or
    ///      resources as suggested above.
    ///
    ///   TYPE:  This MUST be TSIG (250: Transaction SIGnature).
    ///
    ///   CLASS:  This MUST be ANY.
    ///
    ///   TTL:  This MUST be 0.
    ///
    ///   RDLENGTH:  (variable)
    ///
    ///   RDATA:  The RDATA for a TSIG RR consists of a number of fields,
    ///      described below:
    ///
    ///                            1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    ///        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    ///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///       /                         Algorithm DomainName                        /
    ///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///       |                                                               |
    ///       |          Time Signed          +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///       |                               |            Fudge              |
    ///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///       |          MAC Size             |                               /
    ///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+             MAC               /
    ///       /                                                               /
    ///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///       |          Original ID          |            Error              |
    ///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///       |          Other Len            |                               /
    ///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+           Other Data          /
    ///       /                                                               /
    ///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    ///
    ///   The contents of the RDATA fields are:
    ///
    ///   Algorithm DomainName:
    ///      an octet sequence identifying the TSIG algorithm in the domain
    ///      name syntax.  (Allowed names are listed in Table 3.)  The name is
    ///      stored in the DNS name wire format as described in [RFC1034].  As
    ///      per [RFC3597], this name MUST NOT be compressed.
    ///
    ///   Time Signed:
    ///      an unsigned 48-bit integer containing the time the message was
    ///      signed as seconds since 00:00 on 1970-01-01 UTC, ignoring leap
    ///      seconds.
    ///
    ///   Fudge:
    ///      an unsigned 16-bit integer specifying the allowed time difference
    ///      in seconds permitted in the Time Signed field.
    ///
    ///   MAC Size:
    ///      an unsigned 16-bit integer giving the length of the MAC field in
    ///      octets.  Truncation is indicated by a MAC Size less than the size
    ///      of the keyed hash produced by the algorithm specified by the
    ///      Algorithm DomainName.
    ///
    ///   MAC:
    ///      a sequence of octets whose contents are defined by the TSIG
    ///      algorithm used, possibly truncated as specified by the MAC Size.
    ///      The length of this field is given by the MAC Size.  Calculation of
    ///      the MAC is detailed in Section 4.3.
    ///
    ///   Original ID:
    ///      an unsigned 16-bit integer holding the message ID of the original
    ///      request message.  For a TSIG RR on a request, it is set equal to
    ///      the DNS message ID.  In a TSIG attached to a response -- or in
    ///      cases such as the forwarding of a dynamic update request -- the
    ///      field contains the ID of the original DNS request.
    ///
    ///   Error:
    ///      in responses, an unsigned 16-bit integer containing the extended
    ///      RCODE covering TSIG processing.  In requests, this MUST be zero.
    ///
    ///   Other Len:
    ///      an unsigned 16-bit integer specifying the length of the Other Data
    ///      field in octets.
    ///
    ///   Other Data:
    ///      additional data relevant to the TSIG record.  In responses, this
    ///      will be empty (i.e., Other Len will be zero) unless the content of
    ///      the Error field is BADTIME, in which case it will be a 48-bit
    ///      unsigned integer containing the server's current time as the
    ///      number of seconds since 00:00 on 1970-01-01 UTC, ignoring leap
    ///      seconds (see Section 5.2.3).  This document assigns no meaning to
    ///      its contents in requests.
    /// ```
    case TSIG(TSIG)

    /// Unknown or unsupported DNSSEC record data
    case unknown(
        /// RecordType code
        code: UInt16,
        /// RData associated to the record
        rdata: NULL
    )
}

extension DNSSECRData {
    var recordType: RecordType {
        switch self {
        case .CDNSKEY: return .CDNSKEY
        case .CDS: return .CDS
        case .DS: return .DS
        case .KEY: return .KEY
        case .DNSKEY: return .DNSKEY
        case .NSEC: return .NSEC
        case .NSEC3: return .NSEC3
        case .NSEC3PARAM: return .NSEC3PARAM
        case .SIG: return .SIG
        case .RRSIG: return .RRSIG
        case .TSIG: return .TSIG
        case .unknown(let code, _): return RecordType.unknown(code)
        }
    }
}

/// No init(from:). Read using `RData`

extension DNSSECRData {
    package func encode(into buffer: inout DNSBuffer) throws {
        switch self {
        case .CDNSKEY(let cdnskey):
            cdnskey.encode(into: &buffer)
        case .CDS(let cds):
            cds.encode(into: &buffer)
        case .DS(let ds):
            ds.encode(into: &buffer)
        case .KEY(let key):
            try key.encode(into: &buffer)
        case .DNSKEY(let dnskey):
            dnskey.encode(into: &buffer)
        case .NSEC(let nsec):
            try nsec.encode(into: &buffer)
        case .NSEC3(let nsec3):
            try nsec3.encode(into: &buffer)
        case .NSEC3PARAM(let nsec3param):
            try nsec3param.encode(into: &buffer)
        case .SIG(let sig):
            try sig.encode(into: &buffer)
        case .RRSIG(let rrsig):
            try rrsig.encode(into: &buffer)
        case .TSIG(let tsig):
            try tsig.encode(into: &buffer)
        case .unknown(_, let null):
            try null.encode(into: &buffer)
        }
    }
}
