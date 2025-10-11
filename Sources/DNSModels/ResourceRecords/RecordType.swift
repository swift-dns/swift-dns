public enum RecordType: Sendable, Hashable {
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) IPv4 Address record
    case A
    /// [RFC 3596](https://tools.ietf.org/html/rfc3596) IPv6 address record
    case AAAA
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
    /// [RFC 4398](https://tools.ietf.org/html/rfc4398) Storing Certificates in the Domain DomainName System (DNS)
    case CERT
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) Canonical name record
    case CNAME
    //  DHCID,      // 49 RFC 4701 DHCP identifier
    //  DLV,        //	32769	RFC 4431	DNSSEC Lookaside Validation record
    //  DNAME,      // 39 RFC 2672 Delegation DomainName
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
    /// [RFC 1035](https://tools.ietf.org/html/rfc1035) DomainName server record
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
    case unknown(UInt16)
}

extension RecordType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .A: "A"
        case .AAAA: "AAAA"
        case .ANY: "ANY"
        case .AXFR: "AXFR"
        case .CAA: "CAA"
        case .CDNSKEY: "CDNSKEY"
        case .CERT: "CERT"
        case .CDS: "CDS"
        case .CNAME: "CNAME"
        case .CSYNC: "CSYNC"
        case .DNSKEY: "DNSKEY"
        case .DS: "DS"
        case .HINFO: "HINFO"
        case .HTTPS: "HTTPS"
        case .KEY: "KEY"
        case .IXFR: "IXFR"
        case .MX: "MX"
        case .NAPTR: "NAPTR"
        case .NS: "NS"
        case .NSEC: "NSEC"
        case .NSEC3: "NSEC3"
        case .NSEC3PARAM: "NSEC3PARAM"
        case .NULL: "NULL"
        case .OPENPGPKEY: "OPENPGPKEY"
        case .OPT: "OPT"
        case .PTR: "PTR"
        case .RRSIG: "RRSIG"
        case .SIG: "SIG"
        case .SOA: "SOA"
        case .SRV: "SRV"
        case .SSHFP: "SSHFP"
        case .SVCB: "SVCB"
        case .TLSA: "TLSA"
        case .TSIG: "TSIG"
        case .TXT: "TXT"
        case .unknown(let code): "unknown(\(code))"
        }
    }
}

extension RecordType: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[\(self.rawValue)]\(self.description)"
    }
}

extension RecordType: RawRepresentable {
    public init(_ rawValue: UInt16) {
        switch rawValue {
        case 1: self = .A
        case 28: self = .AAAA
        case 255: self = .ANY
        case 251: self = .IXFR
        case 252: self = .AXFR
        case 257: self = .CAA
        case 59: self = .CDS
        case 60: self = .CDNSKEY
        case 37: self = .CERT
        case 5: self = .CNAME
        case 62: self = .CSYNC
        case 48: self = .DNSKEY
        case 43: self = .DS
        case 13: self = .HINFO
        case 65: self = .HTTPS
        case 25: self = .KEY
        case 15: self = .MX
        case 35: self = .NAPTR
        case 2: self = .NS
        case 47: self = .NSEC
        case 50: self = .NSEC3
        case 51: self = .NSEC3PARAM
        case 10: self = .NULL
        case 61: self = .OPENPGPKEY
        case 41: self = .OPT
        case 12: self = .PTR
        case 46: self = .RRSIG
        case 24: self = .SIG
        case 6: self = .SOA
        case 33: self = .SRV
        case 44: self = .SSHFP
        case 64: self = .SVCB
        case 52: self = .TLSA
        case 250: self = .TSIG
        case 16: self = .TXT
        default: self = .unknown(rawValue)
        }
    }

    public init(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        switch self {
        case .A: return 1
        case .AAAA: return 28
        case .ANY: return 255
        case .AXFR: return 252
        case .CAA: return 257
        case .CDNSKEY: return 60
        case .CERT: return 37
        case .CDS: return 59
        case .CNAME: return 5
        case .CSYNC: return 62
        case .DNSKEY: return 48
        case .DS: return 43
        case .HINFO: return 13
        case .HTTPS: return 65
        case .KEY: return 25
        case .IXFR: return 251
        case .MX: return 15
        case .NAPTR: return 35
        case .NS: return 2
        case .NSEC: return 47
        case .NSEC3: return 50
        case .NSEC3PARAM: return 51
        case .NULL: return 10
        case .OPENPGPKEY: return 61
        case .OPT: return 41
        case .PTR: return 12
        case .RRSIG: return 46
        case .SIG: return 24
        case .SOA: return 6
        case .SRV: return 33
        case .SSHFP: return 44
        case .SVCB: return 64
        case .TLSA: return 52
        case .TSIG: return 250
        case .TXT: return 16
        case .unknown(let code): return code
        }
    }
}

extension RecordType {
    package init(from buffer: inout DNSBuffer) throws {
        let recordType = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("RecordType", buffer)
        )
        self = RecordType(recordType)
    }
}

extension RecordType {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}
