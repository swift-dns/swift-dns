public enum RecordType: Hashable {
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) IPv4 Address record
    case A
    /// [RFC 3596](https://tools.ietf.org/html/rfc3596) IPv6 address record
    case AAAA
    /// [ANAME draft-ietf-dnsop-aname](https://tools.ietf.org/html/draft-ietf-dnsop-aname-04)
    case ANAME
    //  AFSDB,      //	18	RFC 1183	AFS database record
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) All cached records, aka ANY
    case ANY
    //  APL,        //	42	RFC 3123	Address Prefix List
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) Authoritative Zone Transfer
    case AXFR
    /// [RFC 6844](https://tools.ietf.org/html/rfc6844) Certification Authority Authorization
    case CAA
    /// [RFC 7344](https://tools.ietf.org/html/rfc7344) Child DS
    case CDS
    /// [RFC 7344](https://tools.ietf.org/html/rfc7344) Child DNSKEY
    case CDNSKEY
    /// [RFC 4398](https://tools.ietf.org/html/rfc4398) Storing Certificates in the Domain Name System (DNS)
    case CERT
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) Canonical name record
    case CNAME
    //  DHCID,      // 49 RFC 4701 DHCP identifier
    //  DLV,        //	32769	RFC 4431	DNSSEC Lookaside Validation record
    //  DNAME,      // 39 RFC 2672 Delegation Name
    /// [RFC 7477](https://tools.ietf.org/html/rfc4034) Child-to-parent synchronization record
    case CSYNC
    /// [RFC 4034](https://tools.ietf.org/html/rfc4034) DNS Key record: RSASHA256 and RSASHA512, RFC5702
    case DNSKEY
    /// [RFC 4034](https://tools.ietf.org/html/rfc4034) Delegation signer: RSASHA256 and RSASHA512, RFC5702
    case DS
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) host information
    case HINFO
    //  HIP,        // 55 RFC 5205 Host Identity Protocol
    /// [RFC 9460](https://tools.ietf.org/html/rfc9460) DNS SVCB and HTTPS RRs
    case HTTPS
    //  IPSECKEY,   // 45 RFC 4025 IPsec Key
    /// [RFC 1996](https://tools.ietf.org/html/rfc1996) Incremental Zone Transfer
    case IXFR
    //  KX,         // 36 RFC 2230 Key eXchanger record
    /// [RFC 2535](https://tools.ietf.org/html/rfc2535) and [RFC 2930](https://tools.ietf.org/html/rfc2930) Key record
    case KEY
    //  LOC,        // 29 RFC 1876 Location record
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) Mail exchange record
    case MX
    /// [RFC 3403](https://tools.ietf.org/html/rfc3403) Naming Authority Pointer
    case NAPTR
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) Name server record
    case NS
    /// [RFC 4034](https://tools.ietf.org/html/rfc4034) Next-Secure record
    case NSEC
    /// [RFC 5155](https://tools.ietf.org/html/rfc5155) NSEC record version 3
    case NSEC3
    /// [RFC 5155](https://tools.ietf.org/html/rfc5155) NSEC3 parameters
    case NSEC3PARAM
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) Null server record, for testing
    case NULL
    /// [RFC 7929](https://tools.ietf.org/html/rfc7929) OpenPGP public key
    case OPENPGPKEY
    /// [RFC 6891](https://tools.ietf.org/html/rfc6891) Option
    case OPT
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) Pointer record
    case PTR
    //  RP,         // 17 RFC 1183 Responsible person
    /// [RFC 4034](https://tools.ietf.org/html/rfc4034) DNSSEC signature: RSASHA256 and RSASHA512, RFC5702
    case RRSIG
    /// [RFC 2535](https://tools.ietf.org/html/rfc2535) (and [RFC 2931](https://tools.ietf.org/html/rfc2931)) Signature, to support [RFC 2137](https://tools.ietf.org/html/rfc2137) Update.
    case SIG
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) and [RFC 2308](https://tools.ietf.org/html/rfc2308) Start of [a zone of] authority record
    case SOA
    /// [RFC 2782](https://tools.ietf.org/html/rfc2782) Service locator
    case SRV
    /// [RFC 4255](https://tools.ietf.org/html/rfc4255) SSH Public Key Fingerprint
    case SSHFP
    /// [RFC 9460](https://tools.ietf.org/html/rfc9460) DNS SVCB and HTTPS RRs
    case SVCB
    //  TA,         // 32768 N/A DNSSEC Trust Authorities
    //  TKEY,       // 249 RFC 2930 Secret key record
    /// [RFC 6698](https://tools.ietf.org/html/rfc6698) TLSA certificate association
    case TLSA
    /// [RFC 8945](https://tools.ietf.org/html/rfc8945) Transaction Signature
    case TSIG
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) Text record
    case TXT
    /// Unknown Record type, or unsupported
    case Unknown(UInt16)
    /// This corresponds to a record type of 0, unspecified
    case ZERO
}
