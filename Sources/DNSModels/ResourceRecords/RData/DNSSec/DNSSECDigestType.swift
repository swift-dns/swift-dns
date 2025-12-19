/// DNSSEC Delegation Signer (DS) Resource Record (RR) Type Digest Algorithms
///
/// [IANA Registry](https://www.iana.org/assignments/ds-rr-types/ds-rr-types.xhtml)
/// ```text
/// Value    Description           Status       Reference
///  0        Reserved              -            [RFC3658]
///  1        SHA-1                 MANDATORY    [RFC3658]
///  2        SHA-256               MANDATORY    [RFC4509]
///  3        GOST R 34.11-94       DEPRECATED   [RFC5933][Change the status of GOST Signature Algorithms in DNSSEC in the IETF stream to Historic]
///  4        SHA-384               OPTIONAL     [RFC6605]
///  5        GOST R 34.11-2012     OPTIONAL     [RFC9558]
///  6        SM3                   OPTIONAL     [RFC9563]
/// ```
///
/// <https://www.iana.org/assignments/ds-rr-types/ds-rr-types.xhtml>
@nonexhaustive
public enum DNSSECDigestType: Sendable {
    /// [RFC 3658](https://tools.ietf.org/html/rfc3658)
    case SHA1
    /// [RFC 4509](https://tools.ietf.org/html/rfc4509)
    case SHA256
    /// [RFC 6605](https://tools.ietf.org/html/rfc6605)
    case SHA384
    /// An unknown digest type
    case unknown(UInt8)
}

extension DNSSECDigestType: RawRepresentable {
    public init(_ rawValue: UInt8) {
        switch rawValue {
        case 1:
            self = .SHA1
        case 2:
            self = .SHA256
        case 4:
            self = .SHA384
        default:
            self = .unknown(rawValue)
        }
    }

    public init?(rawValue: UInt8) {
        self.init(rawValue)
    }

    public var rawValue: UInt8 {
        switch self {
        case .SHA1:
            return 1
        case .SHA256:
            return 2
        case .SHA384:
            return 4
        case .unknown(let value):
            return value
        }
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DNSSECDigestType {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("DNSSECDigestType", buffer)
        )
        self.init(rawValue)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension DNSSECDigestType {
    func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}
