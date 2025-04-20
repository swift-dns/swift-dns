/// Child DS. See RFC 8078.
public struct CDS {
    public let keyTag: UInt16
    public let algorithm: DNSSECAlgorithm?
    public let digestType: DNSSECDigestType
    public let digest: [UInt8]
}
