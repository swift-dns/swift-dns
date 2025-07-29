/// [RFC 5155](https://tools.ietf.org/html/rfc5155#section-4), NSEC3, March 2008
///
/// ```text
/// 4.  The NSEC3PARAM Resource Record
///
///    The NSEC3PARAM RR contains the NSEC3 parameters (hash algorithm,
///    flags, iterations, and salt) needed by authoritative servers to
///    calculate hashed owner names.  The presence of an NSEC3PARAM RR at a
///    zone apex indicates that the specified parameters may be used by
///    authoritative servers to choose an appropriate set of NSEC3 RRs for
///    negative responses.  The NSEC3PARAM RR is not used by validators or
///    resolvers.
///
///    If an NSEC3PARAM RR is present at the apex of a zone with a Flags
///    field value of zero, then there MUST be an NSEC3 RR using the same
///    hash algorithm, iterations, and salt parameters present at every
///    hashed owner name in the zone.  That is, the zone MUST contain a
///    complete set of NSEC3 RRs with the same hash algorithm, iterations,
///    and salt parameters.
///
///    The owner name for the NSEC3PARAM RR is the name of the zone apex.
///
///    The type value for the NSEC3PARAM RR is 51.
///
///    The NSEC3PARAM RR RDATA format is class independent and is described
///    below.
///
///    The class MUST be the same as the NSEC3 RRs to which this RR refers.
///
/// 4.2.  NSEC3PARAM RDATA Wire Format
///
///  The RDATA of the NSEC3PARAM RR is as shown below:
///
///                       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///  |   Hash Alg.   |     Flags     |          Iterations           |
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///  |  Salt Length  |                     Salt                      /
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
///  Hash Algorithm is a single octet.
///
///  Flags field is a single octet.
///
///  Iterations is represented as a 16-bit unsigned integer, with the most
///  significant bit first.
///
///  Salt Length is represented as an unsigned octet.  Salt Length
///  represents the length of the following Salt field in octets.  If the
///  value is zero, the Salt field is omitted.
///
///  Salt, if present, is encoded as a sequence of binary octets.  The
///  length of this field is determined by the preceding Salt Length
///  field.
/// ```
public struct NSEC3PARAM: Sendable {
    public var hashAlgorithm: NSEC3.HashAlgorithm
    public var optOut: Bool
    public var iterations: UInt16
    public var salt: [UInt8]

    var flags: UInt8 {
        var flags: UInt8 = 0
        if self.optOut {
            flags |= 0b0000_0001
        }
        return flags
    }

    public init(
        hashAlgorithm: NSEC3.HashAlgorithm,
        optOut: Bool,
        iterations: UInt16,
        salt: [UInt8]
    ) {
        self.hashAlgorithm = hashAlgorithm
        self.optOut = optOut
        self.iterations = iterations
        self.salt = salt
    }
}

extension NSEC3PARAM {
    package init(from buffer: inout DNSBuffer) throws {
        self.hashAlgorithm = try NSEC3.HashAlgorithm(from: &buffer)
        let flags = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("NSEC3PARAM.flags", buffer)
        )
        guard flags & 0b1111_1110 == 0 else {
            throw ProtocolError.failedToValidate("NSEC3PARAM.flags", buffer)
        }
        //FIXME: use flags like in Header.bytes16to31
        self.optOut = (flags & 0b0000_0001) == 0b0000_0001
        self.iterations = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("NSEC3PARAM.iterations", buffer)
        )
        self.salt = try buffer.readLengthPrefixedString(name: "NSEC3PARAM.salt")
    }
}

extension NSEC3PARAM {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.hashAlgorithm.encode(into: &buffer)
        buffer.writeInteger(self.flags)
        buffer.writeInteger(self.iterations)
        try buffer.writeLengthPrefixedString(
            name: "NSEC3PARAM.salt",
            bytes: self.salt,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension NSEC3PARAM: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.NSEC3PARAM(let nsec3param)):
            self = nsec3param
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .DNSSEC(.NSEC3PARAM(self))
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension NSEC3PARAM: Queryable {
    @inlinable
    public static var recordType: RecordType { .NSEC3PARAM }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
