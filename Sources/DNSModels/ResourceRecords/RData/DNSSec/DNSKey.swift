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
        public var algorithm: DNSSECAlgorithm
        public var key: [UInt8]

        public init(algorithm: DNSSECAlgorithm, key: [UInt8]) {
            self.algorithm = algorithm
            self.key = key
        }
    }

    public var flags: UInt16
    public var publicKey: PublicKey

    public init(flags: UInt16, publicKey: PublicKey) {
        self.flags = flags
        self.publicKey = publicKey
    }
}

extension DNSKEY {
    package init(from buffer: inout DNSBuffer) throws {
        self.flags = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("DNSKEY.flags", buffer)
        )
        let proto = buffer.readInteger(as: UInt8.self)
        guard proto == 3 else {
            throw ProtocolError.failedToValidate("DNSKEY.protocol", buffer)
        }
        self.publicKey = try PublicKey(from: &buffer)
    }
}

extension DNSKEY {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.flags)
        buffer.writeInteger(3 as UInt8)
        self.publicKey.encode(into: &buffer)
    }
}

extension DNSKEY.PublicKey {
    package init(from buffer: inout DNSBuffer) throws {
        self.algorithm = try DNSSECAlgorithm(from: &buffer)
        self.key = buffer.readToEnd()
    }
}

extension DNSKEY.PublicKey {
    package func encode(into buffer: inout DNSBuffer) {
        self.algorithm.encode(into: &buffer)
        buffer.writeBytes(self.key)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension DNSKEY: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.DNSKEY(let dnskey)):
            self = dnskey
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .DNSSEC(.DNSKEY(self))
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension DNSKEY: Queryable {
    @inlinable
    public static var recordType: RecordType { .DNSKEY }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
