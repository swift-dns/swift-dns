package import struct NIOCore.ByteBuffer

/// HTTPS is really a derivation of the original SVCB record data. See SVCB for more documentation
public struct HTTPS: Sendable {
    public var svcb: SVCB
}

extension HTTPS {
    package init(from buffer: inout ByteBuffer) throws {
        self.svcb = try SVCB(from: &buffer)
    }
}

extension HTTPS {
    package func encode(into buffer: inout ByteBuffer) throws {
        try self.svcb.encode(into: &buffer)
    }
}
