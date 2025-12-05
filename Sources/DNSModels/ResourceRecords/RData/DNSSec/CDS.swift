public import struct NIOCore.ByteBuffer

/// Child DS. See RFC 8078.
public struct CDS: Sendable {
    public var keyTag: UInt16
    public var algorithm: DNSSECAlgorithm?
    public var digestType: DNSSECDigestType
    public var digest: ByteBuffer

    public init(
        keyTag: UInt16,
        algorithm: DNSSECAlgorithm?,
        digestType: DNSSECDigestType,
        digest: ByteBuffer
    ) {
        self.keyTag = keyTag
        self.algorithm = algorithm
        self.digestType = digestType
        self.digest = digest
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension CDS {
    package init(from buffer: inout DNSBuffer) throws {
        self.keyTag = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("CDS.keyTag", buffer)
        )
        let proto = buffer.readInteger(as: UInt8.self)
        guard proto == 3 else {
            throw ProtocolError.failedToValidate("CDS.protocol", buffer)
        }
        let algorithm = try buffer.readInteger(as: UInt8.self).unwrap(
            or: .failedToRead("CDS.algorithm", buffer)
        )
        self.algorithm = (algorithm == 0) ? nil : DNSSECAlgorithm(algorithm)
        self.digestType = try DNSSECDigestType(from: &buffer)
        self.digest = buffer.readToEnd()
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension CDS {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.keyTag)
        buffer.writeInteger(3 as UInt8)
        buffer.writeInteger(self.algorithm?.rawValue ?? 0)
        self.digestType.encode(into: &buffer)
        buffer.writeBuffer(self.digest)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension CDS: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.CDS(let cds)):
            self = cds
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .DNSSEC(.CDS(self))
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension CDS: Queryable {
    @inlinable
    public static var recordType: RecordType { .CDS }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
