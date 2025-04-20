/// Child DNSKEY. See RFC 8078.
public struct CDNSKEY {
    public let flags: UInt16
    public let algorithm: DNSSECAlgorithm?
    public let publicKey: [UInt8]
}
