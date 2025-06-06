package import struct NIOCore.ByteBuffer

/// RRSIG is really a derivation of the original SIG record data. See SIG for more documentation
public struct RRSIG: Sendable {
    public var value: SIG

    public init(value: SIG) {
        self.value = value
    }
}

extension RRSIG {
    package init(from buffer: inout ByteBuffer) throws {
        self.value = try SIG(from: &buffer)
    }
}

extension RRSIG {
    package func encode(into buffer: inout ByteBuffer) throws {
        try self.value.encode(into: &buffer)
    }
}
