/// Child DNSKEY. See RFC 8078.
public struct CDNSKEY: Sendable {
    public var flags: UInt16
    public var algorithm: DNSSECAlgorithm?
    public var publicKey: [UInt8]

    public init(flags: UInt16, algorithm: DNSSECAlgorithm?, publicKey: [UInt8]) {
        self.flags = flags
        self.algorithm = algorithm
        self.publicKey = publicKey
    }
}

extension CDNSKEY {
    package init(from buffer: inout DNSBuffer) throws {
        self.flags = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("CDNSKEY.flags", buffer)
        )
        let proto = buffer.readInteger(as: UInt8.self)
        guard proto == 3 else {
            throw ProtocolError.failedToValidate("CDNSKEY.protocol", buffer)
        }
        let algorithm = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("CDNSKEY.algorithm", buffer)
        )
        self.algorithm = (algorithm == 0) ? nil : DNSSECAlgorithm(algorithm)
        self.publicKey = buffer.readToEnd()
    }
}

extension CDNSKEY {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(flags)
        buffer.writeInteger(3 as UInt8)
        buffer.writeInteger(algorithm?.rawValue ?? 0)
        buffer.writeBytes(publicKey)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension CDNSKEY: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.CDNSKEY(let cdnskey)):
            self = cdnskey
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .DNSSEC(.CDNSKEY(self))
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension CDNSKEY: Queryable {
    @inlinable
    public static var recordType: RecordType { .CDNSKEY }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
