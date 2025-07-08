/// The code of the EDNS data option
public enum EDNSCode: Sendable, Hashable {
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
    /// [RFC 8914, Extended DNS Errors](https://tools.ietf.org/html/rfc8914)
    case ednsError
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
        case 15: self = .ednsError
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
        case .dau: return 5
        case .dhu: return 6
        case .n3u: return 7
        case .subnet: return 8
        case .expire: return 9
        case .cookie: return 10
        case .keepalive: return 11
        case .padding: return 12
        case .chain: return 13
        case .ednsError: return 15
        case .unknown(let value): return value
        }
    }
}

extension EDNSCode {
    package init(from buffer: inout DNSBuffer) throws {
        let code = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("EDNSCode", buffer)
        )
        self.init(code)
    }
}

extension EDNSCode {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

/// options used to pass information about capabilities between client and server
///
/// `note: Not all EdnsOptions are supported at this time.`
///
/// <https://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml#dns-parameters-13>
public enum EDNSOption: Sendable, Hashable {
    /// Used to specify the set of SupportedAlgorithms between a client and server
    public struct SupportedAlgorithms: Sendable, Hashable {
        /// right now the number of Algorithms supported are fewer than 8.
        /// This cannot be exposed to the public as the int size might need to grow.
        var rawValue: UInt8

        public init(rawValue: UInt8 = 0) {
            self.rawValue = rawValue
        }
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
    public struct ClientSubnet: Sendable, Hashable {
        public var address: IPAddress
        public var sourcePrefix: UInt8
        public var scopePrefix: UInt8

        public init(address: IPAddress, sourcePrefix: UInt8, scopePrefix: UInt8) {
            self.address = address
            self.sourcePrefix = sourcePrefix
            self.scopePrefix = scopePrefix
        }
    }

    /// [RFC 6975, DNSSEC Algorithm Understood](https://tools.ietf.org/html/rfc6975)
    case dau(SupportedAlgorithms)
    /// [RFC 7871, Client Subnet, Optional](https://tools.ietf.org/html/rfc7871)
    case subnet(ClientSubnet)
    /// Unknown, used to deal with unknown or unsupported codes
    case unknown(UInt16, [UInt8])
}

extension EDNSOption {
    package init(from buffer: inout DNSBuffer, code: EDNSCode) throws {
        switch code {
        case .dau:
            self = .dau(SupportedAlgorithms(from: &buffer))
        case .subnet:
            self = .subnet(try ClientSubnet(from: &buffer))
        default:
            self = .unknown(code.rawValue, buffer.readToEnd())
        }
    }
}

extension EDNSOption {
    package func encode(into buffer: inout DNSBuffer) throws {
        switch self {
        case .dau(let algorithms):
            var valueBuffer = DNSBuffer()
            let count = algorithms.encode(into: &valueBuffer)
            buffer.writeInteger(count)
            buffer.writeBuffer(&valueBuffer)
        case .subnet(let subnet):
            buffer.writeInteger(subnet.lengthForWireProtocol)
            try subnet.encode(into: &buffer)
        case .unknown(_, let data):
            /// FIXME: we don't know this fits, should throw if it doesnt?
            buffer.writeInteger(UInt16(data.count))
            buffer.writeBytes(data)
        }
    }
}

extension EDNSOption.ClientSubnet {
    var lengthForWireProtocol: UInt16 {
        // FAMILY: 2 bytes
        // SOURCE PREFIX-LENGTH: 1 byte
        // SCOPE PREFIX-LENGTH: 1 byte
        // ADDRESS: truncated to the number of bits indicated by the SOURCE PREFIX-LENGTH field
        2 + 1 + 1 + Self.addressLength(of: numericCast(self.sourcePrefix))
    }

    static func addressLength(of sourcePrefix: UInt16) -> UInt16 {
        (sourcePrefix / 8) + (((sourcePrefix % 8) > 0) ? 1 : 0)
    }
}

extension EDNSOption.SupportedAlgorithms {
    mutating func insert(_ algorithm: DNSSECAlgorithmEDNSSubset) {
        /// No unchecked math (&<<) here because we might need to grow the size of algorithm.
        self.rawValue |= 1 << algorithm.rawValue
    }

    func contains(_ algorithm: DNSSECAlgorithmEDNSSubset) -> Bool {
        self.rawValue & (1 << algorithm.rawValue) != 0
    }
}

extension EDNSOption.SupportedAlgorithms {
    package init(from buffer: inout DNSBuffer) {
        self.init()
        while let byte = buffer.readInteger(as: UInt8.self) {
            switch DNSSECAlgorithmEDNSSubset(rawValue: byte) {
            case .some(let algorithm):
                self.insert(algorithm)
            case .none:
                /// FIXME: do something about warnings logs
                print("unknown DNSSECAlgorithm algorithm: \(byte)")
            }
        }
    }
}

extension EDNSOption.SupportedAlgorithms {
    public consuming func makeSequence() -> Sequence {
        Self.Sequence(base: self)
    }

    public struct Sequence: Swift.Sequence {
        var base: EDNSOption.SupportedAlgorithms

        init(base: EDNSOption.SupportedAlgorithms) {
            self.base = base
        }

        public func makeIterator() -> Iterator {
            Iterator(base: self.base)
        }

        public struct Iterator: IteratorProtocol {
            public typealias Element = DNSSECAlgorithmEDNSSubset

            var base: EDNSOption.SupportedAlgorithms
            var current: UInt8

            init(base: EDNSOption.SupportedAlgorithms) {
                self.base = base
                self.current = 0
            }

            public mutating func next() -> DNSSECAlgorithmEDNSSubset? {
                /// FIXME: add a test to make sure DNSSECAlgorithmEDNSSubset contains all
                /// values in range of 0 up to a value, and doesn't skip a value as that'll make
                /// this logic fail. Or a test to basically assert the same thing.
                guard let algorithm = DNSSECAlgorithmEDNSSubset(rawValue: self.current) else {
                    return nil
                }
                self.current += 1
                return algorithm
            }
        }
    }
}

extension EDNSOption.SupportedAlgorithms {
    package func encode(into buffer: inout DNSBuffer) -> UInt16 {
        var count: UInt16 = 0
        for algorithm in self.makeSequence() {
            count += 1
            buffer.writeInteger(algorithm.rawValue)
        }
        return count
    }
}

extension EDNSOption.ClientSubnet {
    package init(from buffer: inout DNSBuffer) throws {
        let family = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("EDNSOption.ClientSubnet.family", buffer)
        )
        guard family == 1 || family == 2 else {
            throw ProtocolError.failedToValidate("EDNSOption.ClientSubnet.family", buffer)
        }
        self.sourcePrefix = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("EDNSOption.ClientSubnet.sourcePrefix", buffer)
        )
        self.scopePrefix = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("EDNSOption.ClientSubnet.scopePrefix", buffer)
        )
        let addressLength = Self.addressLength(of: numericCast(self.sourcePrefix))
        switch family {
        case 1:
            guard addressLength > IPv4Address.size else {
                throw ProtocolError.failedToValidate(
                    "EDNSOption.ClientSubnet.addressLength",
                    buffer
                )
            }
            self.address = .v4(
                try IPv4Address(
                    from: &buffer,
                    addressLength: numericCast(addressLength)
                )
            )
        case 2:
            guard addressLength > IPv6Address.size else {
                throw ProtocolError.failedToValidate(
                    "EDNSOption.ClientSubnet.addressLength",
                    buffer
                )
            }
            self.address = .v6(
                try IPv6Address(
                    from: &buffer,
                    addressLength: numericCast(addressLength)
                )
            )
        default:
            preconditionFailure("Should have verified family is 1 or 2, but still got '\(family)'")
        }
    }
}

extension EDNSOption.ClientSubnet {
    package func encode(into buffer: inout DNSBuffer) throws {
        let addressLength = Self.addressLength(of: numericCast(self.sourcePrefix))

        switch self.address {
        case .v4(let address):
            guard addressLength <= IPv4Address.size else {
                throw ProtocolError.failedToValidate(
                    "EDNSOption.ClientSubnet.v4.addressLength",
                    buffer
                )
            }
            buffer.writeInteger(1 as UInt8)  // family
            buffer.writeInteger(self.sourcePrefix)
            buffer.writeInteger(self.scopePrefix)
            address.encode(
                into: &buffer,
                addressLength: numericCast(addressLength)
            )
        case .v6(let address):
            guard addressLength <= IPv6Address.size else {
                throw ProtocolError.failedToValidate(
                    "EDNSOption.ClientSubnet.v6.addressLength",
                    buffer
                )
            }
            buffer.writeInteger(2 as UInt8)  // family
            buffer.writeInteger(self.sourcePrefix)
            buffer.writeInteger(self.scopePrefix)
            address.encode(
                into: &buffer,
                addressLength: numericCast(addressLength)
            )
        }
    }
}

/// FIXME: what if we need to grow the size of this enum?
public enum DNSSECAlgorithmEDNSSubset: UInt8 {

    /// I know the explicit numbers are not needed and Swift already does this.
    /// Just being explicit for the sake of clarity.

    case RSASHA1 = 0
    case RSASHA256 = 1
    case RSASHA1NSEC3SHA1 = 2
    case RSASHA512 = 3
    case ECDSAP256SHA256 = 4
    case ECDSAP384SHA384 = 5
    case ED25519 = 6

    static var maxValue: UInt8 {
        6
    }

    public init?(from algorithm: DNSSECAlgorithm) {
        switch algorithm {
        case .RSASHA1: self = .RSASHA1
        case .RSASHA256: self = .RSASHA256
        case .RSASHA1NSEC3SHA1: self = .RSASHA1NSEC3SHA1
        case .RSASHA512: self = .RSASHA512
        case .ECDSAP256SHA256: self = .ECDSAP256SHA256
        case .ECDSAP384SHA384: self = .ECDSAP384SHA384
        case .ED25519: self = .ED25519
        case .RSAMD5: return nil
        case .DSA: return nil
        case .unassigned: return nil
        }
    }

    public func toDNSSECAlgorithm() -> DNSSECAlgorithm {
        switch self {
        case .RSASHA1: return .RSASHA1
        case .RSASHA256: return .RSASHA256
        case .RSASHA1NSEC3SHA1: return .RSASHA1NSEC3SHA1
        case .RSASHA512: return .RSASHA512
        case .ECDSAP256SHA256: return .ECDSAP256SHA256
        case .ECDSAP384SHA384: return .ECDSAP384SHA384
        case .ED25519: return .ED25519
        }
    }
}
