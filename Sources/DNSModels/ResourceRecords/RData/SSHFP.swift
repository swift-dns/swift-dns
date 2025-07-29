/// [RFC 4255](https://tools.ietf.org/html/rfc4255#section-3.1)
///
/// ```text
/// 3.1.  The SSHFP RDATA Format
///
///    The RDATA for a SSHFP RR consists of an algorithm number, fingerprint
///    type and the fingerprint of the public host key.
///
///        1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///        0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///        |   algorithm   |    fp type    |                               /
///        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               /
///        /                                                               /
///        /                          fingerprint                          /
///        /                                                               /
///        +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///
/// 3.1.3.  Fingerprint
///
///    The fingerprint is calculated over the public key blob as described
///    in [7].
///
///    The message-digest algorithm is presumed to produce an opaque octet
///    string output, which is placed as-is in the RDATA fingerprint field.
/// ```
public struct SSHFP: Sendable {
    /// ```text
    /// 3.1.2.  Fingerprint Type Specification
    ///
    ///    The fingerprint type octet describes the message-digest algorithm
    ///    used to calculate the fingerprint of the public key.  The following
    ///    values are assigned:
    ///
    ///           Value    Fingerprint type
    ///           -----    ----------------
    ///           0        reserved
    ///           1        SHA-1
    ///
    ///    Reserving other types requires IETF consensus [4].
    ///
    ///    For interoperability reasons, as few fingerprint types as possible
    ///    should be reserved.  The only reason to reserve additional types is
    ///    to increase security.
    /// ```
    ///
    /// The fingerprint type values have been updated in
    /// [RFC 6594](https://tools.ietf.org/html/rfc6594).
    public enum FingerprintType: Sendable {
        /// Reserved value
        case reserved
        /// SHA-1
        case sha1
        /// SHA-256
        case sha256
        /// Unassigned value
        case unassigned(UInt8)
    }

    public var algorithm: Algorithm
    public var fingerprintType: FingerprintType
    public var fingerprint: [UInt8]

    public init(algorithm: Algorithm, fingerprintType: FingerprintType, fingerprint: [UInt8]) {
        self.algorithm = algorithm
        self.fingerprintType = fingerprintType
        self.fingerprint = fingerprint
    }
}

extension SSHFP {
    package init(from buffer: inout DNSBuffer) throws {
        self.algorithm = try Algorithm(from: &buffer)
        self.fingerprintType = try FingerprintType(from: &buffer)
        self.fingerprint = buffer.readToEnd()
    }
}

extension SSHFP {
    package func encode(into buffer: inout DNSBuffer) throws {
        self.algorithm.encode(into: &buffer)
        self.fingerprintType.encode(into: &buffer)
        buffer.writeBytes(self.fingerprint)
    }
}

extension SSHFP.FingerprintType: RawRepresentable {
    public init(_ rawValue: UInt8) {
        switch rawValue {
        case 0: self = .reserved
        case 1: self = .sha1
        case 2: self = .sha256
        case let value: self = .unassigned(value)
        }
    }

    public init?(rawValue: UInt8) {
        self.init(rawValue)
    }

    public var rawValue: UInt8 {
        switch self {
        case .reserved: return 0
        case .sha1: return 1
        case .sha256: return 2
        case .unassigned(let value): return value
        }
    }
}

extension SSHFP.FingerprintType {
    package init(from buffer: inout DNSBuffer) throws {
        let rawValue = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("SSHFP.FingerprintType", buffer)
        )
        self.init(rawValue)
    }
}

extension SSHFP.FingerprintType {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.rawValue)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SSHFP: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .SSHFP(let sshfp):
            self = sshfp
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .SSHFP(self)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension SSHFP: Queryable {
    @inlinable
    public static var recordType: RecordType { .SSHFP }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
