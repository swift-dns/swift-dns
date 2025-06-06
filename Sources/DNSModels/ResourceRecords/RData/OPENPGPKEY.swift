package import struct NIOCore.ByteBuffer

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
    package init(from buffer: inout ByteBuffer) throws {
        self.publicKey = [UInt8](buffer: buffer)
        buffer.moveReaderIndex(forwardBy: buffer.readableBytes)
    }
}

extension OPENPGPKEY {
    package func encode(into buffer: inout ByteBuffer) throws {
        buffer.writeBytes(self.publicKey)
    }
}
