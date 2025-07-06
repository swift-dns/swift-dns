/// [RFC 2535](https://tools.ietf.org/html/rfc2535#section-3), Domain Name System Security Extensions, March 1999
///
/// text
/// 3. The KEY Resource Record
///
///    The KEY resource record (RR) is used to store a public key that is
///    associated with a Domain Name System (DNS) name.  This can be the
///    public key of a zone, a user, or a host or other end entity. Security
///    aware DNS implementations MUST be designed to handle at least two
///    simultaneously valid keys of the same type associated with the same
///    name.
///
///    The type number for the KEY RR is 25.
///
///    A KEY RR is, like any other RR, authenticated by a SIG RR.  KEY RRs
///    must be signed by a zone level key.
///
/// 3.1 KEY RDATA format
///
///    The RDATA for a KEY RR consists of flags, a Proto octet, the
///    algorithm number octet, and the public key itself.  The format is as
///    follows:
///
///                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    |             flags             |    Proto   |   algorithm   |
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    |                                                               /
///    /                          public key                           /
///    /                                                               /
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
///
///    The KEY RR is not intended for storage of certificates and a separate
///    certificate RR has been developed for that purpose, defined in [RFC
///    2538].
///
///    The meaning of the KEY RR owner name, flags, and Proto octet are
///    described in Sections 3.1.1 through 3.1.5 below.  The flags and
///    algorithm must be examined before any data following the algorithm
///    octet as they control the existence and format of any following data.
///    The algorithm and public key fields are described in Section 3.2.
///    The format of the public key is algorithm dependent.
///
///    KEY RRs do not specify their validity period but their authenticating
///    SIG RR(s) do as described in Section 4 below.
///
/// 3.1.1 Object Types, DNS Names, and Keys
///
///    The public key in a KEY RR is for the object named in the owner name.
///
///    A DNS name may refer to three different categories of things.  For
///    example, foo.host.example could be (1) a zone, (2) a host or other
///    end entity , or (3) the mapping into a DNS name of the user or
///    account foo@host.example.  Thus, there are flag bits, as described
///    below, in the KEY RR to indicate with which of these roles the owner
///    name and public key are associated.  Note that an appropriate zone
///    KEY RR MUST occur at the apex node of a secure zone and zone KEY RRs
///    occur only at delegation points.
///
/// 3.1.2 The KEY RR Flag Field
///
///    In the "flags" field:
///
///      0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5
///    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
///    |  A/C  | Z | XT| Z | Z | NAMTYP| Z | Z | Z | Z |      SIG      |
///    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
///
///    Bit 0 and 1 are the key "type" bits whose values have the following
///    meanings:
///
///            10: Use of the key is prohibited for authentication.
///            01: Use of the key is prohibited for confidentiality.
///            00: Use of the key for authentication and/or confidentiality
///                is permitted. Note that DNS security makes use of keys
///                for authentication only. Confidentiality use flagging is
///                provided for use of keys in other Protos.
///                Implementations not intended to support key distribution
///                for confidentiality MAY require that the confidentiality
///                use prohibited bit be on for keys they serve.
///            11: If both bits are one, the "no key" value, there is no key
///                information and the RR stops after the algorithm octet.
///                By the use of this "no key" value, a signed KEY RR can
///                authentically assert that, for example, a zone is not
///                secured.  See section 3.4 below.
///
///    Bits 2 is reserved and must be zero.
///
///    Bits 3 is reserved as a flag extension bit.  If it is a one, a second
///           16 bit flag field is added after the algorithm octet and
///           before the key data.  This bit MUST NOT be set unless one or
///           more such additional bits have been defined and are non-zero.
///
///    Bits 4-5 are reserved and must be zero.
///
///    Bits 6 and 7 form a field that encodes the name type. Field values
///    have the following meanings:
///
///            00: indicates that this is a key associated with a "user" or
///                "account" at an end entity, usually a host.  The coding
///                of the owner name is that used for the responsible
///                individual mailbox in the SOA and RP RRs: The owner name
///                is the user name as the name of a node under the entity
///                name.  For example, "j_random_user" on
///                host.subdomain.example could have a public key associated
///                through a KEY RR with name
///                j_random_user.host.subdomain.example.  It could be used
///                in a security Proto where authentication of a user was
///                desired.  This key might be useful in IP or other
///                security for a user level service such a telnet, ftp,
///                rlogin, etc.
///            01: indicates that this is a zone key for the zone whose name
///                is the KEY RR owner name.  This is the public key used
///                for the primary DNS security feature of data origin
///                authentication.  Zone KEY RRs occur only at delegation
///                points.
///            10: indicates that this is a key associated with the non-zone
///                "entity" whose name is the RR owner name.  This will
///                commonly be a host but could, in some parts of the DNS
///                tree, be some other type of entity such as a telephone
///                number [RFC 1530] or numeric IP address.  This is the
///                public key used in connection with DNS request and
///                transaction authentication services.  It could also be
///                used in an IP-security Proto where authentication at
///                the host, rather than user, level was desired, such as
///                routing, NTP, etc.
///            11: reserved.
///
///    Bits 8-11 are reserved and must be zero.
///
///    Bits 12-15 are the "signatory" field.  If non-zero, they indicate
///               that the key can validly sign things as specified in DNS
///               dynamic update [RFC 2137].  Note that zone keys (see bits
///               6 and 7 above) always have authority to sign any RRs in
///               the zone regardless of the value of the signatory field.
///
public struct KEY: Sendable {
    /// Specifies in what contexts this key may be trusted for use
    public enum KeyTrust: Sendable {
        /// Use of the key is prohibited for authentication
        case notAuth
        /// Use of the key is prohibited for confidentiality
        case notPrivate
        /// Use of the key for authentication and/or confidentiality is permitted
        case authOrPrivate
        /// If both bits are one, the "no key" value, (revocation?)
        case doNotTrust
    }

    /// Declares what this key is for
    public enum KeyUsage: Sendable {
        /// key associated with a "user" or "account" at an end entity, usually a host
        case host
        /// zone key for the zone whose name is the KEY RR owner name
        case zone
        /// associated with the non-zone "entity" whose name is the RR owner name
        case entity
        /// Reserved
        case reserved
    }

    /// [RFC 2137](https://tools.ietf.org/html/rfc2137#section-3.1), Secure Domain Name System Dynamic Update, April 1997
    ///
    /// text
    /// 3.1.1 Update Key Name Scope
    ///
    ///    The owner name of any update authorizing KEY RR must (1) be the same
    ///    as the owner name of any RRs being added or deleted or (2) a wildcard
    ///    name including within its extended scope (see section 3.3) the name
    ///    of any RRs being added or deleted and those RRs must be in the same
    ///    zone.
    ///
    /// 3.1.2 Update Key Class Scope
    ///
    ///    The class of any update authorizing KEY RR must be the same as the
    ///    class of any RR's being added or deleted.
    ///
    /// 3.1.3 Update Key Signatory Field
    ///
    ///    The four bit "signatory field" (see RFC 2065) of any update
    ///    authorizing KEY RR must be non-zero.  The bits have the meanings
    ///    described below for non-zone keys (see section 3.2 for zone type
    ///    keys).
    ///
    ///            UPDATE KEY RR SIGNATORY FIELD BITS
    ///
    ///          0           1           2           3
    ///    +-----------+-----------+-----------+-----------+
    ///    |   zone    |  strong   |  unique   |  general  |
    ///    +-----------+-----------+-----------+-----------+
    ///
    ///    Bit 0, zone control - If nonzero, this key is authorized to attach,
    ///         detach, and move zones by creating and deleting NS, glue A, and
    ///         zone KEY RR(s).  If zero, the key can not authorize any update
    ///         that would effect such RRs.  This bit is meaningful for both
    ///         type A and type B dynamic secure zones.
    ///
    ///         NOTE:  do not confuse the "zone" signatory field bit with the
    ///         "zone" key type bit.
    ///
    ///    Bit 1, strong update - If nonzero, this key is authorized to add and
    ///         delete RRs even if there are other RRs with the same owner name
    ///         and class that are authenticated by a SIG signed with a
    ///         different dynamic update KEY. If zero, the key can only
    ///         authorize updates where any existing RRs of the same owner and
    ///         class are authenticated by a SIG using the same key.  This bit
    ///         is meaningful only for type A dynamic zones and is ignored in
    ///         type B dynamic zones.
    ///
    ///         Keeping this bit zero on multiple KEY RRs with the same or
    ///         nested wild card owner names permits multiple entities to exist
    ///         that can create and delete names but can not effect RRs with
    ///         different owner names from any they created.  In effect, this
    ///         creates two levels of dynamic update key, strong and weak, where
    ///         weak keys are limited in interfering with each other but a
    ///         strong key can interfere with any weak keys or other strong
    ///         keys.
    ///
    ///    Bit 2, unique name update - If nonzero, this key is authorized to add
    ///         and update RRs for only a single owner name.  If there already
    ///         exist RRs with one or more names signed by this key, they may be
    ///         updated but no new name created until the number of existing
    ///         names is reduced to zero.  This bit is meaningful only for mode
    ///         A dynamic zones and is ignored in mode B dynamic zones. This bit
    ///         is meaningful only if the owner name is a wildcard.  (Any
    ///         dynamic update KEY with a non-wildcard name is, in effect, a
    ///         unique name update key.)
    ///
    ///         This bit can be used to restrict a KEY from flooding a zone with
    ///         new names.  In conjunction with a local administratively imposed
    ///         limit on the number of dynamic RRs with a particular name, it
    ///         can completely restrict a KEY from flooding a zone with RRs.
    ///
    ///    Bit 3, general update - The general update signatory field bit has no
    ///         special meaning.  If the other three bits are all zero, it must
    ///         be one so that the field is non-zero to designate that the key
    ///         is an update key.  The meaning of all values of the signatory
    ///         field with the general bit and one or more other signatory field
    ///         bits on is reserved.
    ///
    ///    All the signatory bit update authorizations described above only
    ///    apply if the update is within the name and class scope as per
    ///    sections 3.1.1 and 3.1.2.
    ///
    ///
    /// [RFC 3007](https://tools.ietf.org/html/rfc3007#section-1.5), Secure Dynamic Update, November 2000
    ///
    /// text
    ///    [RFC2535, section 3.1.2] defines the signatory field of a key as the
    ///    final 4 bits of the flags field, but does not define its value.  This
    ///    proposal leaves this field undefined.  Updating [RFC2535], this field
    ///    SHOULD be set to 0 in KEY records, and MUST be ignored.
    ///
    ///
    public struct UpdateScope: Sendable {
        /// this key is authorized to attach,
        ///   detach, and move zones by creating and deleting NS, glue A, and
        ///   zone KEY RR(s)
        public var zone: Bool
        /// this key is authorized to add and
        ///   delete RRs even if there are other RRs with the same owner name
        ///   and class that are authenticated by a SIG signed with a
        ///   different dynamic update KEY
        public var strong: Bool
        /// this key is authorized to add and update RRs for only a single owner name
        public var unique: Bool
        /// The general update signatory field bit has no special meaning, (true if the others are false)
        public var general: Bool

        public init(zone: Bool, strong: Bool, unique: Bool, general: Bool) {
            self.zone = zone
            self.strong = strong
            self.unique = unique
            self.general = general
        }
    }

    /// [RFC 2535](https://tools.ietf.org/html/rfc2535#section-3.1.3), Domain Name System Security Extensions, March 1999
    ///
    /// text
    /// 3.1.3 The Proto Octet
    ///
    ///    It is anticipated that keys stored in DNS will be used in conjunction
    ///    with a variety of Internet Protos.  It is intended that the
    ///    Proto octet and possibly some of the currently unused (must be
    ///    zero) bits in the KEY RR flags as specified in the future will be
    ///    used to indicate a key's validity for different Protos.
    ///
    ///    The following values of the Proto Octet are reserved as indicated:
    ///
    ///         VALUE   Proto
    ///
    ///           0      -reserved
    ///           1     TLS
    ///           2     email
    ///           3     dnssec
    ///           4     IPSEC
    ///          5-254   - available for assignment by IANA
    ///          255     All
    ///
    ///    In more detail:
    ///         1 is reserved for use in connection with TLS.
    ///         2 is reserved for use in connection with email.
    ///         3 is used for DNS security.  The Proto field SHOULD be set to
    ///           this value for zone keys and other keys used in DNS security.
    ///           Implementations that can determine that a key is a DNS
    ///           security key by the fact that flags label it a zone key or the
    ///           signatory flag field is non-zero are NOT REQUIRED to check the
    ///           Proto field.
    ///         4 is reserved to refer to the Oakley/IPSEC [RFC 2401] Proto
    ///           and indicates that this key is valid for use in conjunction
    ///           with that security standard.  This key could be used in
    ///           connection with secured communication on behalf of an end
    ///           entity or user whose name is the owner name of the KEY RR if
    ///           the entity or user flag bits are set.  The presence of a KEY
    ///           resource with this Proto value is an assertion that the
    ///           host speaks Oakley/IPSEC.
    ///         255 indicates that the key can be used in connection with any
    ///           Proto for which KEY RR Proto octet values have been
    ///           defined.  The use of this value is discouraged and the use of
    ///           different keys for different Protos is encouraged.
    ///
    ///
    /// [RFC3445](https://tools.ietf.org/html/rfc3445#section-4), Limiting the KEY Resource Record (RR), December 2002
    ///
    /// text
    /// All Proto Octet values except DNSSEC (3) are eliminated
    ///
    public enum Proto: Sendable {
        /// Not in use
        // Deprecated by RFC3445
        case reserved
        /// Reserved for use with TLS
        // Deprecated by RFC3445
        case tls
        /// Reserved for use with email
        // Deprecated by RFC3445
        case email
        /// Reserved for use with DNSSEC
        case dnssec
        /// Reserved to refer to the Oakley/IPSEC
        // Deprecated by RFC3445
        case ipsec
        /// Undefined
        // Deprecated by RFC3445
        case other(UInt8)
        /// the key can be used in connection with any Proto
        // Deprecated by RFC3445
        case all
    }

    public var keyTrust: KeyTrust
    public var keyUsage: KeyUsage
    public var signatory: UpdateScope
    public var Proto: Proto
    public var algorithm: DNSSECAlgorithm
    public var publicKey: [UInt8]

    var flags: UInt16 {
        var flags: UInt16 = 0

        flags |= self.keyTrust.rawValue
        flags |= self.keyUsage.rawValue
        flags |= self.signatory.rawValue

        return flags
    }

    public init(
        keyTrust: KeyTrust,
        keyUsage: KeyUsage,
        signatory: UpdateScope,
        Proto: Proto,
        algorithm: DNSSECAlgorithm,
        publicKey: [UInt8]
    ) {
        self.keyTrust = keyTrust
        self.keyUsage = keyUsage
        self.signatory = signatory
        self.Proto = Proto
        self.algorithm = algorithm
        self.publicKey = publicKey
    }
}

extension KEY.KeyTrust: RawRepresentable {
    init(_ rawValue: UInt16) {
        // we only care about the first two bits, zero out the rest
        switch rawValue & 0b1100_0000_0000_0000 {
        // 10: Use of the key is prohibited for authentication.
        case 0b1000_0000_0000_0000:
            self = .notAuth
        // 01: Use of the key is prohibited for confidentiality.
        case 0b0100_0000_0000_0000:
            self = .notPrivate
        // 00: Use of the key for authentication and/or confidentiality
        case 0b0000_0000_0000_0000:
            self = .authOrPrivate
        // 11: If both bits are one, the "no key" value, there is no key
        case 0b1100_0000_0000_0000:
            self = .doNotTrust
        default:
            // FIXME: cover in tests that this is unreachable
            fatalError("All other bit fields should have been cleared")
        }
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        switch self {
        // 10: Use of the key is prohibited for authentication.
        case .notAuth:
            return 0b1000_0000_0000_0000
        // 01: Use of the key is prohibited for confidentiality.
        case .notPrivate:
            return 0b0100_0000_0000_0000
        // 00: Use of the key for authentication and/or confidentiality
        case .authOrPrivate:
            return 0b0000_0000_0000_0000
        // 11: If both bits are one, the "no key" value, there is no key
        case .doNotTrust:
            return 0b1100_0000_0000_0000
        }
    }
}

extension KEY {
    package init(from buffer: inout DNSBuffer) throws {
        let flags = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("KEY.flags", buffer)
        )
        /// Bits 2 is reserved and must be zero.
        /// Bits 4-5 are reserved and must be zero.
        /// Bits 8-11 are reserved and must be zero.
        guard flags & 0b0010_1100_1111_0000 == 0 else {
            throw ProtocolError.failedToValidate("KEY.flags", DNSBuffer(integer: flags))
        }
        guard (flags & 0b0001_0000_0000_0000) == 0 else {
            /// extended flags unsupported for now
            throw ProtocolError.failedToValidate("KEY.flags", DNSBuffer(integer: flags))
        }
        self.keyTrust = KEY.KeyTrust(flags)
        self.keyUsage = KEY.KeyUsage(flags)
        self.signatory = KEY.UpdateScope(flags)

        self.Proto = try KEY.Proto(from: &buffer)
        self.algorithm = try DNSSECAlgorithm(from: &buffer)
        self.publicKey = try buffer.readLengthPrefixedString(
            name: "KEY.publicKey",
            decodeLengthAs: UInt16.self
        )
    }
}

extension KEY {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.flags)
        self.Proto.encode(into: &buffer)
        self.algorithm.encode(into: &buffer)
        try buffer.writeLengthPrefixedString(
            name: "KEY.publicKey",
            bytes: self.publicKey,
            maxLength: .max,
            fitLengthInto: UInt16.self
        )
    }
}

extension KEY.KeyTrust {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("KEY.keyTrust", buffer)
        )
        self.init(rawValue)
    }
}

extension KEY.KeyTrust {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

extension KEY.KeyUsage: RawRepresentable {
    init(_ rawValue: UInt16) {
        // we only care about the 6&7 two bits, zero out the rest
        switch rawValue & 0b0000_0011_0000_0000 {
        // 00: indicates that this is a key associated with a "user" or
        case 0b0000_0000_0000_0000:
            self = .host
        // 01: indicates that this is a zone key for the zone whose name
        case 0b0000_0001_0000_0000:
            self = .zone
        // 10: indicates that this is a key associated with the non-zone
        case 0b0000_0010_0000_0000:
            self = .entity
        // 11: reserved.
        case 0b0000_0011_0000_0000:
            self = .reserved
        default:
            // FIXME: cover in tests that this is unreachable
            fatalError("All other bit fields should have been cleared")
        }
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        switch self {
        // 00: indicates that this is a key associated with a "user" or
        case .host:
            return 0b0000_0000_0000_0000
        // 01: indicates that this is a zone key for the zone whose name
        case .zone:
            return 0b0000_0001_0000_0000
        // 10: indicates that this is a key associated with the non-zone
        case .entity:
            return 0b0000_0010_0000_0000
        // 11: reserved.
        case .reserved:
            return 0b0000_0011_0000_0000
        }
    }
}

extension KEY.KeyUsage {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("KEY.keyUsage", buffer)
        )
        self.init(rawValue)
    }
}

extension KEY.KeyUsage {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

extension KEY.UpdateScope: RawRepresentable {
    public init(_ rawValue: UInt16) {
        self.init(
            zone: rawValue & 0b0000_0000_0000_1000 != 0,
            strong: rawValue & 0b0000_0000_0000_0100 != 0,
            unique: rawValue & 0b0000_0000_0000_0010 != 0,
            general: rawValue & 0b0000_0000_0000_0001 != 0
        )
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        var flags: UInt16 = 0

        if self.zone {
            flags |= 0b0000_0000_0000_1000
        }

        if self.strong {
            flags |= 0b0000_0000_0000_0100
        }

        if self.unique {
            flags |= 0b0000_0000_0000_0010
        }

        if self.general {
            flags |= 0b0000_0000_0000_0001
        }

        return flags
    }
}

extension KEY.UpdateScope {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("KEY.updateScope", buffer)
        )
        self.init(rawValue)
    }
}

extension KEY.UpdateScope {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

extension KEY.Proto: RawRepresentable {
    init(_ rawValue: UInt8) {
        switch rawValue {
        case 0:
            self = .reserved
        case 1:
            self = .tls
        case 2:
            self = .email
        case 3:
            self = .dnssec
        case 4:
            self = .ipsec
        case 255:
            self = .all
        default:
            self = .other(rawValue)
        }
    }

    public init?(rawValue: UInt8) {
        self.init(rawValue)
    }

    public var rawValue: UInt8 {
        switch self {
        case .reserved:
            return 0
        case .tls:
            return 1
        case .email:
            return 2
        case .dnssec:
            return 3
        case .ipsec:
            return 4
        case .all:
            return 255
        case .other(let field):
            return field
        }
    }
}

extension KEY.Proto {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("KEY.Proto", buffer)
        )
        self.init(rawValue)
    }
}

extension KEY.Proto {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

extension KEY: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.KEY(let key)):
            self = key
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .DNSSEC(.KEY(self))
    }
}

extension KEY: Queryable {
    public static var recordType: RecordType { .KEY }
    public static var dnsClass: DNSClass { .IN }
}
