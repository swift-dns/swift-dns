/// [RFC 4398, Storing Certificates in DNS, November 1987](https://tools.ietf.org/html/rfc4398)
///
/// ```text
///
/// [2](https://datatracker.ietf.org/doc/html/rfc4398#section-2).  The CERT Resource Record
///
///    The CERT resource record (RR) has the structure given below.  Its RR
///    type code is 37.
///
///       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    |             type              |             key tag           |
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    |   algorithm   |                                               /
///    +---------------+            certificate or CRL                 /
///    /                                                               /
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-|
/// ```
public struct CERT: Sendable {
    /// [RFC 4398, Storing Certificates in DNS, November 1987](https://tools.ietf.org/html/rfc4398#section-2.1)
    ///
    /// ```text
    /// [2.1](https://datatracker.ietf.org/doc/html/rfc4398#section-2.1).  Certificate Type Values
    ///
    ///    The following values are defined or reserved:
    ///
    ///          Value  Mnemonic  Certificate Type
    ///          -----  --------  ----------------
    ///              0            Reserved
    ///              1  PKIX      X.509 as per PKIX
    ///              2  SPKI      SPKI certificate
    ///              3  PGP       OpenPGP packet
    ///              4  IPKIX     The URL of an X.509 data object
    ///              5  ISPKI     The URL of an SPKI certificate
    ///              6  IPGP      The fingerprint and URL of an OpenPGP packet
    ///              7  ACPKIX    Attribute Certificate
    ///              8  IACPKIX   The URL of an Attribute Certificate
    ///          9-252            Available for IANA assignment
    ///            253  URI       URI private
    ///            254  OID       OID private
    ///            255            Reserved
    ///      256-65279            Available for IANA assignment
    ///    65280-65534            Experimental
    ///          65535            Reserved
    /// ```
    public enum CertType: Sendable {
        /// 0, 255, 65535            Reserved
        case reserved
        /// 1  PKIX      X.509 as per PKIX
        case PKIX
        /// 2  SPKI      SPKI certificate
        case SPKI
        /// 3  PGP       OpenPGP packet
        case PGP
        /// 4  IPKIX     The URL of an X.509 data object
        case IPKIX
        /// 5  ISPKI     The URL of an SPKI certificate
        case ISPKI
        /// 6  IPGP      The fingerprint and URL of an OpenPGP packet
        case IPGP
        /// 7  ACPKIX    Attribute Certificate
        case ACPKIX
        /// 8  IACPKIX   The URL of an Attribute Certificate
        case IACPKIX
        /// 253  URI       URI private
        case URI
        /// 254  OID       OID private
        case OID
        /// 9-252, 256-65279            Available for IANA assignment
        case unassigned(UInt16)
        /// 65280-65534            Experimental
        case experimental(UInt16)
    }

    public var certType: CertType
    public var keyTag: UInt16
    public var algorithm: Algorithm
    public var certData: [UInt8]

    public init(certType: CertType, keyTag: UInt16, algorithm: Algorithm, certData: [UInt8]) {
        self.certType = certType
        self.keyTag = keyTag
        self.algorithm = algorithm
        self.certData = certData
    }
}

extension CERT {
    package init(from buffer: inout DNSBuffer) throws {
        self.certType = try CertType(from: &buffer)
        self.keyTag = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("CERT.keyTag", buffer)
        )
        self.algorithm = try Algorithm(from: &buffer)
        self.certData = buffer.readToEnd()
    }
}

extension CERT {
    package func encode(into buffer: inout DNSBuffer) throws {
        certType.encode(into: &buffer)
        buffer.writeInteger(keyTag)
        algorithm.encode(into: &buffer)
        try buffer.writeLengthPrefixedString(
            name: "CERT.certData",
            bytes: certData,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
    }
}

extension CERT.CertType: RawRepresentable {
    public init(_ rawValue: UInt16) {
        switch rawValue {
        case 0, 255, 65535:
            self = .reserved
        case 1:
            self = .PKIX
        case 2:
            self = .SPKI
        case 3:
            self = .PGP
        case 4:
            self = .IPKIX
        case 5:
            self = .ISPKI
        case 6:
            self = .IPGP
        case 7:
            self = .ACPKIX
        case 8:
            self = .IACPKIX
        case 253:
            self = .URI
        case 254:
            self = .OID
        case 65280...65534:
            self = .experimental(rawValue)
        default:
            self = .unassigned(rawValue)
        }
    }

    public init?(rawValue: UInt16) {
        self.init(rawValue)
    }

    public var rawValue: UInt16 {
        switch self {
        case .reserved:
            return 0
        case .PKIX:
            return 1
        case .SPKI:
            return 2
        case .PGP:
            return 3
        case .IPKIX:
            return 4
        case .ISPKI:
            return 5
        case .IPGP:
            return 6
        case .ACPKIX:
            return 7
        case .IACPKIX:
            return 8
        case .URI:
            return 253
        case .OID:
            return 254
        case .unassigned(let value):
            return value
        case .experimental(let value):
            return value
        }
    }
}

extension CERT.CertType {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("CERT.CertType", buffer)
        )
        self.init(rawValue)
    }
}

extension CERT.CertType {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

extension CERT: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .CERT(let cert):
            self = cert
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .CERT(self)
    }
}

extension CERT: Queryable {
    public static var recordType: RecordType { .CERT }
    public static var dnsClass: DNSClass { .IN }
}
