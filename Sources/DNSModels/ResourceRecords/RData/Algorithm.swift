/// [RFC 4398, Storing Certificates in DNS, November 1987](https://tools.ietf.org/html/rfc4398#section-2.2)
///
/// ```text
///
/// [2.2](https://datatracker.ietf.org/doc/html/rfc4398#section-2.2).  Text Representation of CERT RRs
///
///    The RDATA portion of a CERT RR has the type field as an unsigned
///    decimal integer or as a mnemonic symbol as listed in [Section 2.1](https://datatracker.ietf.org/doc/html/rfc4398#section-2.1),
///    above.
///
///    The key tag field is represented as an unsigned decimal integer.
///
///    The algorithm field is represented as an unsigned decimal integer or
///    a mnemonic symbol as listed in [[12](https://datatracker.ietf.org/doc/html/rfc4398#ref-12)].
///
/// [12]  Arends, R., Austein, R., Larson, M., Massey, D., and S. Rose,
/// "Resource Records for the DNS Security Extensions", RFC 4034,
/// March 2005.
///
///
/// [RFC 4034, Resource Records for the DNS Security Extensions, March 2005][rfc4034]
/// https://tools.ietf.org/html/rfc4034#appendix-A.1
///
/// [A.1](https://datatracker.ietf.org/doc/html/rfc4034#appendix-A.1).  DNSSEC Algorithm Types
///
///    The DNSKEY, RRSIG, and DS RRs use an 8-bit number to identify the
///    security algorithm being used.  These values are stored in the
///    "Algorithm number" field in the resource record RDATA.
///
///    Some algorithms are usable only for zone signing (DNSSEC), some only
///    for transaction security mechanisms (SIG(0) and TSIG), and some for
///    both.  Those usable for zone signing may appear in DNSKEY, RRSIG, and
///    DS RRs.  Those usable for transaction security would be present in
///    SIG(0) and KEY RRs, as described in [RFC2931].
///
///                                 Zone
///    Value Algorithm [Mnemonic]  Signing  References   Status
///    ----- -------------------- --------- ----------  ---------
///      0   reserved
///      1   RSA/MD5 [RSAMD5]         n      [RFC2537]  NOT RECOMMENDED
///      2   Diffie-Hellman [DH]      n      [RFC2539]   -
///      3   DSA/SHA-1 [DSA]          y      [RFC2536]  OPTIONAL
///      4   Elliptic Curve [ECC]              TBA       -
///      5   RSA/SHA-1 [RSASHA1]      y      [RFC3110]  MANDATORY
///    252   Indirect [INDIRECT]      n                  -
///    253   Private [PRIVATEDNS]     y      see below  OPTIONAL
///    254   Private [PRIVATEOID]     y      see below  OPTIONAL
///    255   reserved
///
///    6 - 251  Available for assignment by IETF Standards Action.
///
/// (RFC Required) Domain Name System Security (DNSSEC) Algorithm Numbers
/// Created: 2003-11-03, Last Updated: 2024-04-16
/// https://www.iana.org/assignments/dns-sec-alg-numbers/dns-sec-alg-numbers.txt
///
///                                                              Zone
///     Value  Algorithm [Mnemonic]                            Signing    References
///     -----  --------------------                           ---------   ----------
///       6    DSA-NSEC3-SHA1 [DSA-NSEC3-SHA1]                    Y       [RFC5155][proposed standard]
///       7    RSASHA1-NSEC3-SHA1 [RSASHA1-NSEC3-SHA1]            Y       [RFC5155][proposed standard]
///       8    RSA/SHA-256 [RSASHA256]                            Y       [RFC5702][proposed standard]
///       9    reserved
///      10    RSA/SHA-512 [RSASHA512]                            Y       [RFC5702][proposed standard]
///      11    reserved
///      12    GOST R 34.10-2001 [ECC-GOST]                       Y       [RFC5933][proposed standard]
///      13    ECDSA Curve P-256 with SHA-256 [ECDSAP256SHA256]   Y       [RFC6605][proposed standard]
///      14    ECDSA Curve P-384 with SHA-384 [ECDSAP384SHA384]   Y       [RFC6605][proposed standard]
///      15    Ed25519 [ED25519]                                  Y       [RFC8080][proposed standard]
///      16    Ed448 [ED448]                                      Y       [RFC8080][proposed standard]
///      17    SM2 signing with SM3 hashing [SM2SM3]              Y       [RFC-cuiling-dnsop-sm2-alg-15][informational]
///   18-22    Unassigned
///      23    GOST R 34.10-2012 [ECC-GOST12]                     Y       [RFC9558][informational]
///  24-122    Unassigned
/// 123-251    reserved
/// ```
public enum Algorithm: Sendable {
    /// 0, 9, 11, 123-251, 255   reserved
    case reserved(UInt8)
    /// 1   RSA/MD5 ([RFC 2537](https://tools.ietf.org/html/rfc2537))
    case RSAMD5
    /// 2   Diffie-Hellman ([RFC 2539](https://tools.ietf.org/html/rfc2539))
    case DH
    /// 3   DSA/SHA-1 ([RFC 2536](https://tools.ietf.org/html/rfc2536))
    case DSA
    /// 4   Elliptic Curve
    case ECC
    /// 5   RSA/SHA-1 ([RFC 3110](https://tools.ietf.org/html/rfc3110))
    case RSASHA1
    /// 252   Indirect
    case INDIRECT
    /// 253   Private
    case PRIVATEDNS
    /// 254   Private
    case PRIVATEOID
    /// 6    DSA-NSEC3-SHA1 ([RFC 5155](https://tools.ietf.org/html/rfc5155))
    case DSANSEC3SHA1
    /// 7    RSASHA1-NSEC3-SHA1 (RFC5155)
    case RSASHA1NSEC3SHA1
    /// 8    RSA/SHA-256 ([RFC 5702](https://tools.ietf.org/html/rfc5702))
    case RSASHA256
    /// 10    RSA/SHA-512 ([RFC 5702](https://tools.ietf.org/html/rfc5702))
    case RSASHA512
    /// 12    GOST R 34.10-2001 ([RFC 5933](https://tools.ietf.org/html/rfc5933))
    case ECCGOST
    /// 13    ECDSA Curve P-256 with SHA-256 ([RFC 6605](https://tools.ietf.org/html/rfc6605))
    case ECDSAP256SHA256
    /// 14    ECDSA Curve P-384 with SHA-384 ([RFC 6605](https://tools.ietf.org/html/rfc6605))
    case ECDSAP384SHA384
    /// 15    Ed25519 ([RFC 8080](https://tools.ietf.org/html/rfc8080))
    case ED25519
    /// 16    Ed448 ([RFC 8080](https://tools.ietf.org/html/rfc8080))
    case ED448
    /// 17    SM2 signing with SM3 hashing (RFC-cuiling-dnsop-sm2-alg-15)
    case SM2SM3
    /// 23    GOST R 34.10-2012 ([RFC 9558](https://tools.ietf.org/html/rfc9558))
    case ECCGOST12
    ///   18-22, 24-122    Unassigned
    case unassigned(UInt8)
}

extension Algorithm: RawRepresentable {
    public init(_ rawValue: UInt8) {
        switch rawValue {
        case 0, 9, 11, 123...251, 255:
            self = .reserved(rawValue)
        case 1:
            self = .RSAMD5
        case 2:
            self = .DH
        case 3:
            self = .DSA
        case 4:
            self = .ECC
        case 5:
            self = .RSASHA1
        case 252:
            self = .INDIRECT
        case 253:
            self = .PRIVATEDNS
        case 254:
            self = .PRIVATEOID
        case 6:
            self = .DSANSEC3SHA1
        case 7:
            self = .RSASHA1NSEC3SHA1
        case 8:
            self = .RSASHA256
        case 10:
            self = .RSASHA512
        case 12:
            self = .ECCGOST
        case 13:
            self = .ECDSAP256SHA256
        case 14:
            self = .ECDSAP384SHA384
        case 15:
            self = .ED25519
        case 16:
            self = .ED448
        case 17:
            self = .SM2SM3
        case 23:
            self = .ECCGOST12
        default:
            self = .unassigned(rawValue)
        }
    }

    public init?(rawValue: UInt8) {
        self.init(rawValue)
    }

    public var rawValue: UInt8 {
        switch self {
        case .reserved(let value):
            return value
        case .RSAMD5:
            return 1
        case .DH:
            return 2
        case .DSA:
            return 3
        case .ECC:
            return 4
        case .RSASHA1:
            return 5
        case .INDIRECT:
            return 252
        case .PRIVATEDNS:
            return 253
        case .PRIVATEOID:
            return 254
        case .DSANSEC3SHA1:
            return 6
        case .RSASHA1NSEC3SHA1:
            return 7
        case .RSASHA256:
            return 8
        case .RSASHA512:
            return 10
        case .ECCGOST:
            return 12
        case .ECDSAP256SHA256:
            return 13
        case .ECDSAP384SHA384:
            return 14
        case .ED25519:
            return 15
        case .ED448:
            return 16
        case .SM2SM3:
            return 17
        case .ECCGOST12:
            return 23
        case .unassigned(let value):
            return value
        }
    }
}

extension Algorithm {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("Algorithm", buffer)
        )
        self.init(rawValue)
    }
}

extension Algorithm {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}
