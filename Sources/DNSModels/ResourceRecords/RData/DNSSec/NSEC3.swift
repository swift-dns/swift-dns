/// [RFC 5155](https://tools.ietf.org/html/rfc5155#section-3), NSEC3, March 2008
///
/// ```text
/// 3.  The NSEC3 Resource Record
///
///    The NSEC3 Resource Record (RR) provides authenticated denial of
///    existence for DNS Resource Record Sets.
///
///    The NSEC3 RR lists RR types present at the original owner name of the
///    NSEC3 RR.  It includes the next hashed owner name in the hash order
///    of the zone.  The complete set of NSEC3 RRs in a zone indicates which
///    RRSets exist for the original owner name of the RR and form a chain
///    of hashed owner names in the zone.  This information is used to
///    provide authenticated denial of existence for DNS data.  To provide
///    protection against zone enumeration, the owner names used in the
///    NSEC3 RR are cryptographic hashes of the original owner name
///    prepended as a single label to the name of the zone.  The NSEC3 RR
///    indicates which hash function is used to construct the hash, which
///    salt is used, and how many iterations of the hash function are
///    performed over the original owner name.  The hashing technique is
///    described fully in Section 5.
///
///    Hashed owner names of unsigned delegations may be excluded from the
///    chain.  An NSEC3 RR whose span covers the hash of an owner name or
///    "next closer" name of an unsigned delegation is referred to as an
///    Opt-Out NSEC3 RR and is indicated by the presence of a flag.
///
///    The owner name for the NSEC3 RR is the base32 encoding of the hashed
///    owner name prepended as a single label to the name of the zone.
///
///    The type value for the NSEC3 RR is 50.
///
///    The NSEC3 RR RDATA format is class independent and is described
///    below.
///
///    The class MUST be the same as the class of the original owner name.
///
///    The NSEC3 RR SHOULD have the same TTL value as the SOA minimum TTL
///    field.  This is in the spirit of negative caching [RFC2308].
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
///  |  Hash Length  |             Next Hashed Owner Name            /
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
///  represents the length of the Next Hashed Owner Name field in octets.
///
///  The next hashed owner name is not base32 encoded, unlike the owner
///  name of the NSEC3 RR.  It is the unmodified binary hash value.  It
///  does not include the name of the containing zone.  The length of this
///  field is determined by the preceding Hash Length field.
/// ```
public struct NSEC3: Sendable {
    /// ```text
    /// RFC 5155                         NSEC3                        March 2008
    ///
    /// 11.  IANA Considerations
    ///
    ///    Although the NSEC3 and NSEC3PARAM RR formats include a hash algorithm
    ///    parameter, this document does not define a particular mechanism for
    ///    safely transitioning from one NSEC3 hash algorithm to another.  When
    ///    specifying a new hash algorithm for use with NSEC3, a transition
    ///    mechanism MUST also be defined.
    ///
    ///    This document updates the IANA registry "DOMAIN NAME SYSTEM
    ///    PARAMETERS" (https://www.iana.org/assignments/dns-parameters) in sub-
    ///    registry "TYPES", by defining two new types.  Section 3 defines the
    ///    NSEC3 RR type 50.  Section 4 defines the NSEC3PARAM RR type 51.
    ///
    ///    This document updates the IANA registry "DNS SECURITY ALGORITHM
    ///    NUMBERS -- per [RFC4035]"
    ///    (https://www.iana.org/assignments/dns-sec-alg-numbers).  Section 2
    ///    defines the aliases DSA-NSEC3-SHA1 (6) and RSASHA1-NSEC3-SHA1 (7) for
    ///    respectively existing registrations DSA and RSASHA1 in combination
    ///    with NSEC3 hash algorithm SHA1.
    ///
    ///    Since these algorithm numbers are aliases for existing DNSKEY
    ///    algorithm numbers, the flags that exist for the original algorithm
    ///    are valid for the alias algorithm.
    ///
    ///    This document creates a new IANA registry for NSEC3 flags.  This
    ///    registry is named "DNSSEC NSEC3 Flags".  The initial contents of this
    ///    registry are:
    ///
    ///      0   1   2   3   4   5   6   7
    ///    +---+---+---+---+---+---+---+---+
    ///    |   |   |   |   |   |   |   |Opt|
    ///    |   |   |   |   |   |   |   |Out|
    ///    +---+---+---+---+---+---+---+---+
    ///
    ///       bit 7 is the Opt-Out flag.
    ///
    ///       bits 0 - 6 are available for assignment.
    ///
    ///    Assignment of additional NSEC3 Flags in this registry requires IETF
    ///    Standards Action [RFC2434].
    ///
    ///    This document creates a new IANA registry for NSEC3PARAM flags.  This
    ///    registry is named "DNSSEC NSEC3PARAM Flags".  The initial contents of
    ///    this registry are:
    ///
    ///      0   1   2   3   4   5   6   7
    ///    +---+---+---+---+---+---+---+---+
    ///    |   |   |   |   |   |   |   | 0 |
    ///    +---+---+---+---+---+---+---+---+
    ///
    ///       bit 7 is reserved and must be 0.
    ///
    ///       bits 0 - 6 are available for assignment.
    ///
    ///    Assignment of additional NSEC3PARAM Flags in this registry requires
    ///    IETF Standards Action [RFC2434].
    ///
    ///    Finally, this document creates a new IANA registry for NSEC3 hash
    ///    algorithms.  This registry is named "DNSSEC NSEC3 Hash Algorithms".
    ///    The initial contents of this registry are:
    ///
    ///       0 is Reserved.
    ///
    ///       1 is SHA-1.
    ///
    ///       2-255 Available for assignment.
    ///
    ///    Assignment of additional NSEC3 hash algorithms in this registry
    ///    requires IETF Standards Action [RFC2434].
    /// ```
    public enum HashAlgorithm: Sendable {
        /// Hash for the Nsec3 records
        case SHA1
    }

    /// Labels are always stored as ASCII, unicode characters must be encoded with punycode
    public struct Label: Sendable {
        public var value: InlineArray<24, UInt8>

        public init(value: InlineArray<24, UInt8>) {
            self.value = value
        }
    }

    public var hashAlgorithm: HashAlgorithm
    public var optOut: Bool
    public var iterations: UInt16
    public var salt: [UInt8]
    public var nextHashedOwnerName: [UInt8]
    /// Don't need this yet
    /// public var nextHashedOwnerNameBase32: Label?
    public var typeBitMaps: RecordTypeSet

    var flags: UInt8 {
        var flags: UInt8 = 0
        if self.optOut {
            flags |= 0b0000_0001
        }
        return flags
    }

    public init(
        hashAlgorithm: HashAlgorithm,
        optOut: Bool,
        iterations: UInt16,
        salt: [UInt8],
        nextHashedOwnerName: [UInt8],
        typeBitMaps: RecordTypeSet
    ) {
        self.hashAlgorithm = hashAlgorithm
        self.optOut = optOut
        self.iterations = iterations
        self.salt = salt
        self.nextHashedOwnerName = nextHashedOwnerName
        self.typeBitMaps = typeBitMaps
    }
}

extension NSEC3 {
    package init(from buffer: inout DNSBuffer) throws {
        self.hashAlgorithm = try HashAlgorithm(from: &buffer)
        let flags = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("NSEC3.flags", buffer)
        )
        guard flags & 0b1111_1110 == 0 else {
            throw ProtocolError.failedToValidate("NSEC3.flags", buffer)
        }
        //FIXME: use flags like in Header.bytes16to31
        self.optOut = (flags & 0b0000_0001) == 0b0000_0001
        self.iterations = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("NSEC3.iterations", buffer)
        )
        self.salt = try buffer.readLengthPrefixedString(name: "NSEC3.salt")
        self.nextHashedOwnerName = try buffer.readLengthPrefixedString(
            name: "NSEC3.nextHashedOwnerName"
        )
        self.typeBitMaps = try RecordTypeSet(from: &buffer)
    }
}

extension NSEC3 {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.hashAlgorithm.encode(into: &buffer)
        buffer.writeInteger(self.flags)
        buffer.writeInteger(self.iterations)
        try buffer.writeLengthPrefixedString(
            name: "NSEC3.salt",
            bytes: self.salt,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
        try buffer.writeLengthPrefixedString(
            name: "NSEC3.nextHashedOwnerName",
            bytes: self.nextHashedOwnerName,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
        self.typeBitMaps.encode(into: &buffer)
    }
}

extension NSEC3.HashAlgorithm: RawRepresentable {
    public init?(rawValue: UInt8) {
        switch rawValue {
        case 1: self = .SHA1
        default: return nil
        }
    }

    public var rawValue: UInt8 {
        switch self {
        case .SHA1: return 1
        }
    }
}

extension NSEC3.HashAlgorithm {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("NSEC3.HashAlgorithm", buffer)
        )
        self = try NSEC3.HashAlgorithm(rawValue: rawValue).unwrap(
            or: .failedToValidate("NSEC3.HashAlgorithm", buffer)
        )
    }
}

extension NSEC3.HashAlgorithm {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.rawValue)
    }
}

extension NSEC3: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.NSEC3(let nsec3)):
            self = nsec3
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .DNSSEC(.NSEC3(self))
    }
}

extension NSEC3: Queryable {
    @inlinable
    public static var recordType: RecordType { .NSEC3 }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
