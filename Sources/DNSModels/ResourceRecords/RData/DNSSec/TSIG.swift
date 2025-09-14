import DNSCore

public import struct NIOCore.ByteBuffer

/// [RFC 8945, Secret Key Transaction Authentication for DNS](https://tools.ietf.org/html/rfc8945#section-4.2)
///
/// ```text
///   4.2.  TSIG Record Format
///
///   The fields of the TSIG RR are described below.  All multi-octet
///   integers in the record are sent in network byte order (see
///   Section 2.3.2 of [RFC1035]).
///
///   NAME:  The name of the key used, in domain name syntax.  The name
///      should reflect the names of the hosts and uniquely identify the
///      key among a set of keys these two hosts may share at any given
///      time.  For example, if hosts A.site.example and B.example.net
///      share a key, possibilities for the key name include
///      <id>.A.site.example, <id>.B.example.net, and
///      <id>.A.site.example.B.example.net.  It should be possible for more
///      than one key to be in simultaneous use among a set of interacting
///      hosts.  This allows for periodic key rotation as per best
///      operational practices, as well as algorithm agility as indicated
///      by [RFC7696].
///
///      The name may be used as a local index to the key involved, but it
///      is recommended that it be globally unique.  Where a key is just
///      shared between two hosts, its name actually need only be
///      meaningful to them, but it is recommended that the key name be
///      mnemonic and incorporate the names of participating agents or
///      resources as suggested above.
///
///   TYPE:  This MUST be TSIG (250: Transaction SIGnature).
///
///   CLASS:  This MUST be ANY.
///
///   TTL:  This MUST be 0.
///
///   RDLENGTH:  (variable)
///
///   RDATA:  The RDATA for a TSIG RR consists of a number of fields,
///      described below:
///
///                            1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       /                         Algorithm DomainName                        /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |                                                               |
///       |          Time Signed          +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |                               |            Fudge              |
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |          MAC Size             |                               /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+             MAC               /
///       /                                                               /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |          Original ID          |            Error              |
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///       |          Other Len            |                               /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+           Other Data          /
///       /                                                               /
///       +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
///   The contents of the RDATA fields are:
///
///   Algorithm DomainName:
///      an octet sequence identifying the TSIG algorithm in the domain
///      name syntax.  (Allowed names are listed in Table 3.)  The name is
///      stored in the DNS name wire format as described in [RFC1034].  As
///      per [RFC3597], this name MUST NOT be compressed.
///
///   Time Signed:
///      an unsigned 48-bit integer containing the time the message was
///      signed as seconds since 00:00 on 1970-01-01 UTC, ignoring leap
///      seconds.
///
///   Fudge:
///      an unsigned 16-bit integer specifying the allowed time difference
///      in seconds permitted in the Time Signed field.
///
///   MAC Size:
///      an unsigned 16-bit integer giving the length of the MAC field in
///      octets.  Truncation is indicated by a MAC Size less than the size
///      of the keyed hash produced by the algorithm specified by the
///      Algorithm DomainName.
///
///   MAC:
///      a sequence of octets whose contents are defined by the TSIG
///      algorithm used, possibly truncated as specified by the MAC Size.
///      The length of this field is given by the MAC Size.  Calculation of
///      the MAC is detailed in Section 4.3.
///
///   Original ID:
///      an unsigned 16-bit integer holding the message ID of the original
///      request message.  For a TSIG RR on a request, it is set equal to
///      the DNS message ID.  In a TSIG attached to a response -- or in
///      cases such as the forwarding of a dynamic update request -- the
///      field contains the ID of the original DNS request.
///
///   Error:
///      in responses, an unsigned 16-bit integer containing the extended
///      RCODE covering TSIG processing.  In requests, this MUST be zero.
///
///   Other Len:
///      an unsigned 16-bit integer specifying the length of the Other Data
///      field in octets.
///
///   Other Data:
///      additional data relevant to the TSIG record.  In responses, this
///      will be empty (i.e., Other Len will be zero) unless the content of
///      the Error field is BADTIME, in which case it will be a 48-bit
///      unsigned integer containing the server's current time as the
///      number of seconds since 00:00 on 1970-01-01 UTC, ignoring leap
///      seconds (see Section 5.2.3).  This document assigns no meaning to
///      its contents in requests.
/// ```
public struct TSIG: Sendable {
    /// Algorithm used to authenticate communication
    ///
    /// [RFC8945 Secret Key Transaction Authentication for DNS](https://tools.ietf.org/html/rfc8945#section-6)
    /// ```text
    ///      +==========================+================+=================+
    ///      | Algorithm DomainName           | Implementation | Use             |
    ///      +==========================+================+=================+
    ///      | HMAC-MD5.SIG-ALG.REG.INT | MAY            | MUST NOT        |
    ///      +--------------------------+----------------+-----------------+
    ///      | gss-tsig                 | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha1                | MUST           | NOT RECOMMENDED |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha224              | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha256              | MUST           | RECOMMENDED     |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha256-128          | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha384              | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha384-192          | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha512              | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    ///      | hmac-sha512-256          | MAY            | MAY             |
    ///      +--------------------------+----------------+-----------------+
    /// ```
    public enum Algorithm: Sendable {
        /// HMAC-MD5.SIG-ALG.REG.INT (not supported for cryptographic operations)
        case HMAC_MD5
        /// gss-tsig (not supported for cryptographic operations)
        case GSS
        /// hmac-sha1 (not supported for cryptographic operations)
        case HMAC_SHA1
        /// hmac-sha224 (not supported for cryptographic operations)
        case HMAC_SHA224
        /// hmac-sha256
        case HMAC_SHA256
        /// hmac-sha256-128 (not supported for cryptographic operations)
        case HMAC_SHA256_128
        /// hmac-sha384
        case HMAC_SHA384
        /// hmac-sha384-192 (not supported for cryptographic operations)
        case HMAC_SHA384_192
        /// hmac-sha512
        case HMAC_SHA512
        /// hmac-sha512-256 (not supported for cryptographic operations)
        case HMAC_SHA512_256
        /// Unknown algorithm
        case unknown(DomainName)
    }

    public var algorithm: Algorithm
    public var time: UInt64
    public var fudge: UInt16
    public var mac: ByteBuffer
    public var oid: UInt16
    public var error: UInt16
    public var other: ByteBuffer

    public init(
        algorithm: Algorithm,
        time: UInt64,
        fudge: UInt16,
        mac: ByteBuffer,
        oid: UInt16,
        error: UInt16,
        other: ByteBuffer
    ) {
        self.algorithm = algorithm
        self.time = time
        self.fudge = fudge
        self.mac = mac
        self.oid = oid
        self.error = error
        self.other = other
    }
}

extension TSIG {
    package init(from buffer: inout DNSBuffer) throws {
        self.algorithm = try TSIG.Algorithm(from: &buffer)
        let timeHigh = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("TSIG.timeHigh", buffer)
        )
        let timeLow = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("TSIG.timeLow", buffer)
        )
        /// `timeHigh` and `timeLow` are `UInt16` and `UInt32` respectively, so it's safe to convert to `UInt64`
        self.time =
            (UInt64(truncatingIfNeeded: timeHigh) &<<< 32) | UInt64(truncatingIfNeeded: timeLow)
        self.fudge = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("TSIG.fudge", buffer)
        )
        self.mac = try buffer.readLengthPrefixedStringByteBuffer(
            name: "TSIG.mac",
            decodeLengthAs: UInt16.self
        )
        self.oid = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("TSIG.oid", buffer)
        )
        self.error = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("TSIG.error", buffer)
        )
        self.other = try buffer.readLengthPrefixedStringByteBuffer(
            name: "TSIG.other",
            decodeLengthAs: UInt16.self
        )
    }
}

extension TSIG {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.algorithm.encode(into: &buffer)
        /// FIXME: Is this check needed, with `init(exactly:)`?
        let shiftedTime = try UInt16(exactly: self.time >> 32).unwrap(
            or: .failedToValidate("TSIG.time", DNSBuffer(integer: self.time))
        )
        buffer.writeInteger(shiftedTime)
        /// Truncation is desired here, even if it cuts some bits off.
        buffer.writeInteger(UInt32(truncatingIfNeeded: self.time))
        buffer.writeInteger(self.fudge)
        try buffer.writeLengthPrefixedString(
            name: "TSIG.mac",
            bytes: self.mac,
            maxLength: .max,
            fitLengthInto: UInt16.self
        )
        buffer.writeInteger(self.oid)
        buffer.writeInteger(self.error)
        try buffer.writeLengthPrefixedString(
            name: "TSIG.other",
            bytes: self.other,
            maxLength: .max,
            fitLengthInto: UInt16.self
        )
    }
}

extension TSIG.Algorithm: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "hmac-md5.sig-alg.reg.int": self = .HMAC_MD5
        case "gss-tsig": self = .GSS
        case "hmac-sha1": self = .HMAC_SHA1
        case "hmac-sha224": self = .HMAC_SHA224
        case "hmac-sha256": self = .HMAC_SHA256
        case "hmac-sha256-128": self = .HMAC_SHA256_128
        case "hmac-sha384": self = .HMAC_SHA384
        case "hmac-sha384-192": self = .HMAC_SHA384_192
        case "hmac-sha512": self = .HMAC_SHA512
        case "hmac-sha512-256": self = .HMAC_SHA512_256
        default:
            if let name = try? DomainName(string: rawValue) {
                self = .unknown(name)
            } else {
                return nil
            }
        }
    }

    public var rawValue: String {
        switch self {
        case .HMAC_MD5: return "hmac-md5.sig-alg.reg.int"
        case .GSS: return "gss-tsig"
        case .HMAC_SHA1: return "hmac-sha1"
        case .HMAC_SHA224: return "hmac-sha224"
        case .HMAC_SHA256: return "hmac-sha256"
        case .HMAC_SHA256_128: return "hmac-sha256-128"
        case .HMAC_SHA384: return "hmac-sha384"
        case .HMAC_SHA384_192: return "hmac-sha384-192"
        case .HMAC_SHA512: return "hmac-sha512"
        case .HMAC_SHA512_256: return "hmac-sha512-256"
        case .unknown(let name): return name.description
        }
    }

    package init(name: DomainName) {
        self =
            switch name.description {
            case "hmac-md5.sig-alg.reg.int": .HMAC_MD5
            case "gss-tsig": .GSS
            case "hmac-sha1": .HMAC_SHA1
            case "hmac-sha224": .HMAC_SHA224
            case "hmac-sha256": .HMAC_SHA256
            case "hmac-sha256-128": .HMAC_SHA256_128
            case "hmac-sha384": .HMAC_SHA384
            case "hmac-sha384-192": .HMAC_SHA384_192
            case "hmac-sha512": .HMAC_SHA512
            case "hmac-sha512-256": .HMAC_SHA512_256
            default: .unknown(name)
            }
    }

    package func toName() throws -> DomainName {
        switch self {
        case .HMAC_MD5: return try DomainName(guaranteedASCIIBytes: "hmac-md5.sig-alg.reg.int".utf8)
        case .GSS: return try DomainName(guaranteedASCIIBytes: "gss-tsig".utf8)
        case .HMAC_SHA1: return try DomainName(guaranteedASCIIBytes: "hmac-sha1".utf8)
        case .HMAC_SHA224: return try DomainName(guaranteedASCIIBytes: "hmac-sha224".utf8)
        case .HMAC_SHA256: return try DomainName(guaranteedASCIIBytes: "hmac-sha256".utf8)
        case .HMAC_SHA256_128: return try DomainName(guaranteedASCIIBytes: "hmac-sha256-128".utf8)
        case .HMAC_SHA384: return try DomainName(guaranteedASCIIBytes: "hmac-sha384".utf8)
        case .HMAC_SHA384_192: return try DomainName(guaranteedASCIIBytes: "hmac-sha384-192".utf8)
        case .HMAC_SHA512: return try DomainName(guaranteedASCIIBytes: "hmac-sha512".utf8)
        case .HMAC_SHA512_256: return try DomainName(guaranteedASCIIBytes: "hmac-sha512-256".utf8)
        case .unknown(let name): return name
        }
    }
}

extension TSIG.Algorithm: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}

extension TSIG.Algorithm: CaseIterable {
    public static var allCases: [TSIG.Algorithm] {
        [
            .HMAC_MD5,
            .GSS,
            .HMAC_SHA1,
            .HMAC_SHA224,
            .HMAC_SHA256,
            .HMAC_SHA256_128,
            .HMAC_SHA384,
            .HMAC_SHA384_192,
            .HMAC_SHA512,
            .HMAC_SHA512_256,
        ]
    }
}

extension TSIG.Algorithm {
    package init(from buffer: inout DNSBuffer) throws {
        self.init(name: try DomainName(from: &buffer))
    }
}

extension TSIG.Algorithm {
    func encode(into buffer: inout DNSBuffer) throws {
        try self.toName().encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension TSIG: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.TSIG(let tsig)):
            self = tsig
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .DNSSEC(.TSIG(self))
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension TSIG: Queryable {
    @inlinable
    public static var recordType: RecordType { .TSIG }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
