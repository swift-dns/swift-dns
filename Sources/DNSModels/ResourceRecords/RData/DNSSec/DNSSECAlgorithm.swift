/// [RFC 4034, Resource Records for the DNS Security Extensions](https://datatracker.ietf.org/doc/html/rfc4034#appendix-A.1)
/// ```text
/// The DNSKEY, RRSIG, and DS RRs use an 8-bit number to identify the
/// security algorithm being used.  These values are stored in the
///  "Algorithm number" field in the resource record RDATA.
///
/// Some algorithms are usable only for zone signing (DNSSEC), some only
/// for transaction security mechanisms (SIG(0) and TSIG), and some for
/// both.  Those usable for zone signing may appear in DNSKEY, RRSIG, and
/// DS RRs.  Those usable for transaction security would be present in
/// SIG(0) and KEY RRs, as described in [RFC2931].
/// ```
public enum DNSSECAlgorithm: Sendable {
    /// 1   RSA/MD5 ([RFC 2537](https://tools.ietf.org/html/rfc2537))
    case RSAMD5
    /// 3   DSA/SHA-1 ([RFC 2536](https://tools.ietf.org/html/rfc2536))
    case DSA
    /// 5   RSA/SHA-1 ([RFC 3110](https://tools.ietf.org/html/rfc3110))
    case RSASHA1
    /// 7    RSASHA1-NSEC3-SHA1 (RFC5155)
    case RSASHA1NSEC3SHA1
    /// 8    RSA/SHA-256 ([RFC 5702](https://tools.ietf.org/html/rfc5702))
    case RSASHA256
    /// 10    RSA/SHA-512 ([RFC 5702](https://tools.ietf.org/html/rfc5702))
    case RSASHA512
    /// 13    ECDSA Curve P-256 with SHA-256 ([RFC 6605](https://tools.ietf.org/html/rfc6605))
    case ECDSAP256SHA256
    /// 14    ECDSA Curve P-384 with SHA-384 ([RFC 6605](https://tools.ietf.org/html/rfc6605))
    case ECDSAP384SHA384
    /// 15    Ed25519 ([RFC 8080](https://tools.ietf.org/html/rfc8080))
    case ED25519
    /// Unassigned
    case unassigned(UInt8)
}

extension DNSSECAlgorithm: RawRepresentable {
    public init(_ rawValue: UInt8) {
        switch rawValue {
        case 1:
            self = .RSAMD5
        case 3:
            self = .DSA
        case 5:
            self = .RSASHA1
        case 7:
            self = .RSASHA1NSEC3SHA1
        case 8:
            self = .RSASHA256
        case 10:
            self = .RSASHA512
        case 13:
            self = .ECDSAP256SHA256
        case 14:
            self = .ECDSAP384SHA384
        case 15:
            self = .ED25519
        default:
            self = .unassigned(rawValue)
        }
    }

    public init?(rawValue: UInt8) {
        self.init(rawValue)
    }

    public var rawValue: UInt8 {
        switch self {
        case .RSAMD5:
            return 1
        case .DSA:
            return 3
        case .RSASHA1:
            return 5
        case .RSASHA1NSEC3SHA1:
            return 7
        case .RSASHA256:
            return 8
        case .RSASHA512:
            return 10
        case .ECDSAP256SHA256:
            return 13
        case .ECDSAP384SHA384:
            return 14
        case .ED25519:
            return 15
        case .unassigned(let value):
            return value
        }
    }
}

extension DNSSECAlgorithm {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("DNSSECAlgorithm", buffer)
        )
        self.init(rawValue)
    }
}

extension DNSSECAlgorithm {
    func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}
