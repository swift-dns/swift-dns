package import struct NIOCore.ByteBuffer

/// The DNS AAAA record type, an IPv6 address
public struct AAAA: Sendable {
    public var value: IPv6Address

    public init(value: IPv6Address) {
        self.value = value
    }
}

extension AAAA {
    package init(from buffer: inout ByteBuffer) throws {
        self.value = try IPv6Address(from: &buffer)
    }
}

extension AAAA {
    package func encode(into buffer: inout ByteBuffer) {
        value.encode(into: &buffer)
    }
}
