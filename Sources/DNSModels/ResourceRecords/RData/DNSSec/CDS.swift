/// Child DS. See RFC 8078.
public struct CDS: Sendable {
    public var keyTag: UInt16
    public var algorithm: DNSSECAlgorithm?
    public var digestType: DNSSECDigestType
    public var digest: [UInt8]

    public init(
        keyTag: UInt16,
        algorithm: DNSSECAlgorithm?,
        digestType: DNSSECDigestType,
        digest: [UInt8]
    ) {
        self.keyTag = keyTag
        self.algorithm = algorithm
        self.digestType = digestType
        self.digest = digest
    }
}

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

extension CDS {
    package func encode(into buffer: inout DNSBuffer) {
        buffer.writeInteger(self.keyTag)
        buffer.writeInteger(3 as UInt8)
        buffer.writeInteger(self.algorithm?.rawValue ?? 0)
        self.digestType.encode(into: &buffer)
        buffer.writeBytes(self.digest)
    }
}

extension CDS: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.CDS(let cds)):
            self = cds
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .DNSSEC(.CDS(self))
    }
}
