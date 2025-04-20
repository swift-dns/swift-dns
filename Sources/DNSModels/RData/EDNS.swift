/// The code of the EDNS data option
public enum EDNSCode {
    /// [RFC 6891, Reserved](https://tools.ietf.org/html/rfc6891)
    case zero
    /// [RFC 8764, Apple's Long-Lived Queries, Optional](https://tools.ietf.org/html/rfc8764)
    case llq
    /// [UL On-hold](https://files.dns-sd.org/draft-sekar-dns-ul.txt)
    case ul
    /// [RFC 5001, NSID](https://tools.ietf.org/html/rfc5001)
    case nsid
    // 4 Reserved [draft-cheshire-edns0-owner-option] -EXPIRED-
    /// [RFC 6975, DNSSEC Algorithm Understood](https://tools.ietf.org/html/rfc6975)
    case dau
    /// [RFC 6975, DS Hash Understood](https://tools.ietf.org/html/rfc6975)
    case dhu
    /// [RFC 6975, NSEC3 Hash Understood](https://tools.ietf.org/html/rfc6975)
    case n3u
    /// [RFC 7871, Client Subnet, Optional](https://tools.ietf.org/html/rfc7871)
    case subnet
    /// [RFC 7314, EDNS EXPIRE, Optional](https://tools.ietf.org/html/rfc7314)
    case expire
    /// [RFC 7873, DNS Cookies](https://tools.ietf.org/html/rfc7873)
    case cookie
    /// [RFC 7828, edns-tcp-keepalive](https://tools.ietf.org/html/rfc7828)
    case keepalive
    /// [RFC 7830, The EDNS(0) Padding](https://tools.ietf.org/html/rfc7830)
    case padding
    /// [RFC 7901, CHAIN Query Requests in DNS, Optional](https://tools.ietf.org/html/rfc7901)
    case chain
    /// Unknown, used to deal with unknown or unsupported codes
    case unknown(UInt16)
}

extension EDNSCode: RawRepresentable {
    public init(_ raw: UInt16) {
        switch raw {
        case 0: self = .zero
        case 1: self = .llq
        case 2: self = .ul
        case 3: self = .nsid
        case 5: self = .dau
        case 6: self = .dhu
        case 7: self = .n3u
        case 8: self = .subnet
        case 9: self = .expire
        case 10: self = .cookie
        case 11: self = .keepalive
        case 12: self = .padding
        case 13: self = .chain
        case let value: self = .unknown(value)
        }
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        switch self {
        case .zero: return 0
        case .llq: return 1
        case .ul: return 2
        case .nsid: return 3
        case .dau: return 4
        case .dhu: return 5
        case .n3u: return 6
        case .subnet: return 7
        case .expire: return 8
        case .cookie: return 9
        case .keepalive: return 10
        case .padding: return 11
        case .chain: return 12
        case .unknown(let value): return value
        }
    }
}

/// options used to pass information about capabilities between client and server
///
/// `note: Not all EdnsOptions are supported at this time.`
///
/// <https://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml#dns-parameters-13>
@available(macOS 9999, *)
public enum EDNSOption {
    /// Used to specify the set of SupportedAlgorithms between a client and server
    public struct SupportedAlgorithms {
        // right now the number of Algorithms supported are fewer than 8.
        let bitMap: UInt8
    }

    /// [RFC 7871, Client Subnet, Optional](https://tools.ietf.org/html/rfc7871)
    ///
    /// ```text
    /// +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    /// 0: |                            FAMILY                             |
    ///    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    /// 2: |     SOURCE PREFIX-LENGTH      |     SCOPE PREFIX-LENGTH       |
    ///    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    /// 4: |                           ADDRESS...                          /
    ///    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    ///
    /// o  FAMILY, 2 octets, indicates the family of the address contained in
    ///    the option, using address family codes as assigned by IANA in
    ///    Address Family Numbers [Address_Family_Numbers].
    /// o  SOURCE PREFIX-LENGTH, an unsigned octet representing the leftmost
    ///    number of significant bits of ADDRESS to be used for the lookup.
    ///    In responses, it mirrors the same value as in the queries.
    /// o  SCOPE PREFIX-LENGTH, an unsigned octet representing the leftmost
    ///    number of significant bits of ADDRESS that the response covers.
    ///    In queries, it MUST be set to 0.
    /// o  ADDRESS, variable number of octets, contains either an IPv4 or
    ///    IPv6 address, depending on FAMILY, which MUST be truncated to the
    ///    number of bits indicated by the SOURCE PREFIX-LENGTH field,
    ///    padding with 0 bits to pad to the end of the last octet needed.
    /// o  A server receiving an ECS option that uses either too few or too
    ///    many ADDRESS octets, or that has non-zero ADDRESS bits set beyond
    ///    SOURCE PREFIX-LENGTH, SHOULD return FORMERR to reject the packet,
    ///    as a signal to the software developer making the request to fix
    ///    their implementation.
    /// ```
    @available(macOS 9999, *)
    public struct ClientSubnet {
        public let address: IPAddress
        public let sourcePrefix: UInt8
        public let scopePrefix: UInt8
    }

    /// [RFC 6975, DNSSEC Algorithm Understood](https://tools.ietf.org/html/rfc6975)
    case dau(SupportedAlgorithms)
    /// [RFC 7871, Client Subnet, Optional](https://tools.ietf.org/html/rfc7871)
    case subnet(ClientSubnet)
    /// Unknown, used to deal with unknown or unsupported codes
    case unknown(UInt16, [UInt8])
}
