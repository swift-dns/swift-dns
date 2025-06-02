/// [RFC 4034](https://tools.ietf.org/html/rfc4034#section-2), DNSSEC Resource Records, March 2005
///
/// ```text
/// 2.  The DNSKEY Resource Record
///
///    DNSSEC uses public key cryptography to sign and authenticate DNS
///    resource record sets (RRsets).  The public keys are stored in DNSKEY
///    resource records and are used in the DNSSEC authentication process
///    described in [RFC4035]: A zone signs its authoritative RRsets by
///    using a private key and stores the corresponding public key in a
///    DNSKEY RR.  A resolver can then use the public key to validate
///    signatures covering the RRsets in the zone, and thus to authenticate
///    them.
///
///    The DNSKEY RR is not intended as a record for storing arbitrary
///    public keys and MUST NOT be used to store certificates or public keys
///    that do not directly relate to the DNS infrastructure.
///
///    The Type value for the DNSKEY RR type is 48.
///
///    The DNSKEY RR is class independent.
///
///    The DNSKEY RR has no special TTL requirements.
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
/// 2.1.5.  Notes on DNSKEY RDATA Design
///
///    Although the Protocol Field always has value 3, it is retained for
///    backward compatibility with early versions of the KEY record.
///
/// ```
public struct DNSKEY: Sendable {
    /// An owned variant of PublicKey
    public struct PublicKey: Sendable {
        public let keyBuf: [UInt8]
        public let algorithm: DNSSECAlgorithm
    }

    public let flags: UInt16
    public let publicKey: PublicKey
}
