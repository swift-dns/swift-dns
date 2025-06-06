package import struct NIOCore.ByteBuffer

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
    package init(from buffer: inout ByteBuffer) throws {
        self.flags =
            try buffer.readInteger(as: UInt16.self)
            ?? {
                throw ProtocolError.failedToRead("CDNSKEY.flags", buffer)
            }()
        let proto = buffer.readInteger(as: UInt8.self)
        guard proto == 3 else {
            throw ProtocolError.failedToValidate("CDNSKEY.protocol", buffer)
        }
        let algorithm =
            try buffer.readInteger(as: UInt8.self)
            ?? {
                throw ProtocolError.failedToRead("CDNSKEY.algorithm", buffer)
            }()
        self.algorithm = (algorithm == 0) ? nil : DNSSECAlgorithm(algorithm)
        self.publicKey = [UInt8](buffer: buffer)
        buffer.moveReaderIndex(forwardBy: buffer.readableBytes)
    }
}

extension CDNSKEY {
    package func encode(into buffer: inout ByteBuffer) {
        buffer.writeInteger(flags)
        buffer.writeInteger(3 as UInt8)
        buffer.writeInteger(algorithm?.rawValue ?? 0)
        buffer.writeBytes(publicKey)
    }
}
