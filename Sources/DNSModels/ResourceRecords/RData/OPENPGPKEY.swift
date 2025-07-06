/// [RFC 7929](https://tools.ietf.org/html/rfc7929#section-2.1)
///
/// ```text
/// The RDATA portion of an OPENPGPKEY resource record contains a single
/// value consisting of a Transferable Public Key formatted as specified
/// in [RFC4880].
/// ```
public struct OPENPGPKEY: Sendable {
    public var publicKey: [UInt8]

    public init(publicKey: [UInt8]) {
        self.publicKey = publicKey
    }
}

extension OPENPGPKEY {
    package init(from buffer: inout DNSBuffer) throws {
        self.publicKey = buffer.readToEnd()
    }
}

extension OPENPGPKEY {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeBytes(self.publicKey)
    }
}

extension OPENPGPKEY: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .OPENPGPKEY(let openpgpkey):
            self = openpgpkey
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .OPENPGPKEY(self)
    }
}
