package import struct NIOCore.ByteBuffer

/// The DNS PTR record type
public struct PTR: Sendable {
    public var name: Name

    public init(name: Name) {
        self.name = name
    }
}

extension PTR {
    package init(from buffer: inout ByteBuffer) throws {
        self.name = try Name(from: &buffer)
    }
}

extension PTR {
    package func encode(into buffer: inout ByteBuffer) throws {
        try self.name.encode(into: &buffer)
    }
}
