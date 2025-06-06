package import struct NIOCore.ByteBuffer

/// [RFC 6698, DNS-Based Authentication for TLS](https://tools.ietf.org/html/rfc6698#section-2.1)
///
/// ```text
/// 2.1.  TLSA RDATA Wire Format
///
///    The RDATA for a TLSA RR consists of a one-octet certificate usage
///    field, a one-octet selector field, a one-octet matching type field,
///    and the certificate association data field.
///
///                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///    |  Cert. Usage  |   Selector    | Matching Type |               /
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+               /
///    /                                                               /
///    /                 Certificate Association Data                  /
///    /                                                               /
///    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// ```
public struct TLSA: Sendable {
    /// [RFC 6698, DNS-Based Authentication for TLS](https://tools.ietf.org/html/rfc6698#section-2.1.1)
    ///
    /// ```text
    /// 2.1.1.  The Certificate Usage Field
    ///
    ///    A one-octet value, called "certificate usage", specifies the provided
    ///    association that will be used to match the certificate presented in
    ///    the TLS handshake.  This value is defined in a new IANA registry (see
    ///    Section 7.2) in order to make it easier to add additional certificate
    ///    usages in the future.  The certificate usages defined in this
    ///    document are:
    ///
    ///       0 -- CA
    ///
    ///       1 -- Service
    ///
    ///       2 -- TrustAnchor
    ///
    ///       3 -- DomainIssued
    ///
    ///    The certificate usages defined in this document explicitly only apply
    ///    to PKIX-formatted certificates in DER encoding [X.690].  If TLS
    ///    allows other formats later, or if extensions to this RRtype are made
    ///    that accept other formats for certificates, those certificates will
    ///    need their own certificate usage values.
    /// ```
    ///
    /// [RFC 7218, Adding Acronyms to DANE Registries](https://datatracker.ietf.org/doc/html/rfc7218#section-2.1)
    ///
    /// ```text
    /// 2.1.  TLSA Certificate Usages Registry
    ///
    ///   The reference for this registry has been updated to include both
    ///   [RFC6698] and this document.
    ///
    ///    +-------+----------+--------------------------------+-------------+
    ///    | Value | Acronym  | Short Description              | Reference   |
    ///    +-------+----------+--------------------------------+-------------+
    ///    |   0   | PKIX-TA  | CA constraint                  | [RFC6698]   |
    ///    |   1   | PKIX-EE  | Service certificate constraint | [RFC6698]   |
    ///    |   2   | DANE-TA  | Trust anchor assertion         | [RFC6698]   |
    ///    |   3   | DANE-EE  | Domain-issued certificate      | [RFC6698]   |
    ///    | 4-254 |          | Unassigned                     |             |
    ///    |  255  | PrivCert | Reserved for Private Use       | [RFC6698]   |
    ///    +-------+----------+--------------------------------+-------------+
    /// ```
    public enum CertUsage: Sendable {
        /// ```text
        ///       0 -- Certificate usage 0 is used to specify a CA certificate, or
        ///       the public key of such a certificate, that MUST be found in any of
        ///       the PKIX certification paths for the end entity certificate given
        ///       by the server in TLS.  This certificate usage is sometimes
        ///       referred to as "CA constraint" because it limits which CA can be
        ///       used to issue certificates for a given service on a host.  The
        ///       presented certificate MUST pass PKIX certification path
        ///       validation, and a CA certificate that matches the TLSA record MUST
        ///       be included as part of a valid certification path.  Because this
        ///       certificate usage allows both trust anchors and CA certificates,
        ///       the certificate might or might not have the basicConstraints
        ///       extension present.
        /// ```
        case pkixTa
        /// ```text
        ///       1 -- Certificate usage 1 is used to specify an end entity
        ///       certificate, or the public key of such a certificate, that MUST be
        ///       matched with the end entity certificate given by the server in
        ///       TLS.  This certificate usage is sometimes referred to as "service
        ///       certificate constraint" because it limits which end entity
        ///       certificate can be used by a given service on a host.  The target
        ///       certificate MUST pass PKIX certification path validation and MUST
        ///       match the TLSA record.
        /// ```
        case pkixEe
        /// ```text
        ///       2 -- Certificate usage 2 is used to specify a certificate, or the
        ///       public key of such a certificate, that MUST be used as the trust
        ///       anchor when validating the end entity certificate given by the
        ///       server in TLS.  This certificate usage is sometimes referred to as
        ///       "trust anchor assertion" and allows a domain name administrator to
        ///       specify a new trust anchor -- for example, if the domain issues
        ///       its own certificates under its own CA that is not expected to be
        ///       in the end users' collection of trust anchors.  The target
        ///       certificate MUST pass PKIX certification path validation, with any
        ///       certificate matching the TLSA record considered to be a trust
        ///       anchor for this certification path validation.
        /// ```
        case daneTa
        /// ```text
        ///       3 -- Certificate usage 3 is used to specify a certificate, or the
        ///       public key of such a certificate, that MUST match the end entity
        ///       certificate given by the server in TLS.  This certificate usage is
        ///       sometimes referred to as "domain-issued certificate" because it
        ///       allows for a domain name administrator to issue certificates for a
        ///       domain without involving a third-party CA.  The target certificate
        ///       MUST match the TLSA record.  The difference between certificate
        ///       usage 1 and certificate usage 3 is that certificate usage 1
        ///       requires that the certificate pass PKIX validation, but PKIX
        ///       validation is not tested for certificate usage 3.
        /// ```
        case daneEe
        /// Unassigned at the time of this implementation
        case unassigned(UInt8)
        /// Private usage
        case `private`
    }

    /// [RFC 6698, DNS-Based Authentication for TLS](https://tools.ietf.org/html/rfc6698#section-2.1.1)
    ///
    /// ```text
    /// 2.1.2.  The Selector Field
    ///
    ///    A one-octet value, called "selector", specifies which part of the TLS
    ///    certificate presented by the server will be matched against the
    ///    association data.  This value is defined in a new IANA registry (see
    ///    Section 7.3).  The selectors defined in this document are:
    ///
    ///       0 -- Full
    ///
    ///       1 -- Spki
    ///
    ///    (Note that the use of "selector" in this document is completely
    ///    unrelated to the use of "selector" in DomainKeys Identified Mail
    ///    (DKIM) [RFC6376].)
    /// ```
    public enum Selector: Sendable {
        /// Full certificate: the Certificate binary structure as defined in [RFC5280](https://tools.ietf.org/html/rfc5280)
        case full
        /// SubjectPublicKeyInfo: DER-encoded binary structure as defined in [RFC5280](https://tools.ietf.org/html/rfc5280)
        case spki
        /// Unassigned at the time of this writing
        case unassigned(UInt8)
        /// Private usage
        case `private`
    }

    /// [RFC 6698, DNS-Based Authentication for TLS](https://tools.ietf.org/html/rfc6698#section-2.1.3)
    ///
    /// ```text
    /// 2.1.3.  The Matching Type Field
    ///
    ///    A one-octet value, called "matching type", specifies how the
    ///    certificate association is presented.  This value is defined in a new
    ///    IANA registry (see Section 7.4).  The types defined in this document
    ///    are:
    ///
    ///       0 -- Raw
    ///
    ///       1 -- Sha256
    ///
    ///       2 -- Sha512
    ///
    ///    If the TLSA record's matching type is a hash, having the record use
    ///    the same hash algorithm that was used in the signature in the
    ///    certificate (if possible) will assist clients that support a small
    ///    number of hash algorithms.
    /// ```
    public enum Matching: Sendable {
        /// Exact match on selected content
        case raw
        /// SHA-256 hash of selected content [RFC6234](https://tools.ietf.org/html/rfc6234)
        case sha256
        /// SHA-512 hash of selected content [RFC6234](https://tools.ietf.org/html/rfc6234)
        case sha512
        /// Unassigned at the time of this writing
        case unassigned(UInt8)
        /// Private usage
        case `private`
    }

    public var certUsage: CertUsage
    public var selector: Selector
    public var matching: Matching
    public var certData: [UInt8]

    public init(certUsage: CertUsage, selector: Selector, matching: Matching, certData: [UInt8]) {
        self.certUsage = certUsage
        self.selector = selector
        self.matching = matching
        self.certData = certData
    }
}

extension TLSA {
    package init(from buffer: inout ByteBuffer) throws {
        self.certUsage = try CertUsage(from: &buffer)
        self.selector = try Selector(from: &buffer)
        self.matching = try Matching(from: &buffer)
        self.certData = [UInt8](buffer: buffer)
        buffer.moveReaderIndex(forwardBy: buffer.readableBytes)
    }
}

extension TLSA {
    package func encode(into buffer: inout ByteBuffer) throws {
        self.certUsage.encode(into: &buffer)
        self.selector.encode(into: &buffer)
        self.matching.encode(into: &buffer)
        buffer.writeBytes(self.certData)
    }
}

extension TLSA.CertUsage: RawRepresentable {
    public init(_ rawValue: UInt8) {
        switch rawValue {
        case 0: self = .pkixTa
        case 1: self = .pkixEe
        case 2: self = .daneTa
        case 3: self = .daneEe
        case 255: self = .private
        case let value: self = .unassigned(value)
        }
    }

    public init?(rawValue: UInt8) {
        self.init(rawValue)
    }

    public var rawValue: UInt8 {
        switch self {
        case .pkixTa: return 0
        case .pkixEe: return 1
        case .daneTa: return 2
        case .daneEe: return 3
        case .unassigned(let value): return value
        case .private: return 255
        }
    }
}

extension TLSA.CertUsage {
    package init(from buffer: inout ByteBuffer) throws {
        guard let rawValue = buffer.readInteger(as: UInt8.self) else {
            throw ProtocolError.failedToRead("TLSA.CertUsage", buffer)
        }
        self.init(rawValue)
    }
}

extension TLSA.CertUsage {
    package func encode(into buffer: inout ByteBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

extension TLSA.Selector: RawRepresentable {
    public init(_ rawValue: UInt8) {
        switch rawValue {
        case 0: self = .full
        case 1: self = .spki
        case 255: self = .private
        case let value: self = .unassigned(value)
        }
    }

    public init?(rawValue: UInt8) {
        self.init(rawValue)
    }

    public var rawValue: UInt8 {
        switch self {
        case .full: return 0
        case .spki: return 1
        case .unassigned(let value): return value
        case .private: return 255
        }
    }
}

extension TLSA.Selector {
    package init(from buffer: inout ByteBuffer) throws {
        guard let rawValue = buffer.readInteger(as: UInt8.self) else {
            throw ProtocolError.failedToRead("TLSA.Selector", buffer)
        }
        self.init(rawValue)
    }
}

extension TLSA.Selector {
    package func encode(into buffer: inout ByteBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

extension TLSA.Matching: RawRepresentable {
    public init(_ rawValue: UInt8) {
        switch rawValue {
        case 0: self = .raw
        case 1: self = .sha256
        case 2: self = .sha512
        case 255: self = .private
        case let value: self = .unassigned(value)
        }
    }

    public init?(rawValue: UInt8) {
        self.init(rawValue)
    }

    public var rawValue: UInt8 {
        switch self {
        case .raw: return 0
        case .sha256: return 1
        case .sha512: return 2
        case .unassigned(let value): return value
        case .private: return 255
        }
    }
}

extension TLSA.Matching {
    package init(from buffer: inout ByteBuffer) throws {
        guard let rawValue = buffer.readInteger(as: UInt8.self) else {
            throw ProtocolError.failedToRead("TLSA.Matching", buffer)
        }
        self.init(rawValue)
    }
}

extension TLSA.Matching {
    func encode(into buffer: inout ByteBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}
