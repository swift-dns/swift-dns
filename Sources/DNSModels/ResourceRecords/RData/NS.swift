package import struct NIOCore.ByteBuffer

/// The DNS NS record type
public struct NS: Sendable {
    public var name: Name

    public init(name: Name) {
        self.name = name
    }
}

extension NS {
    package init(from buffer: inout ByteBuffer) throws {
        self.name = try Name(from: &buffer)
    }
}

extension NS {
    package func encode(into buffer: inout ByteBuffer) throws {
        try self.name.encode(into: &buffer)
    }
}
