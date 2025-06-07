/// The DNS NS record type
public struct NS: Sendable {
    public var name: Name

    public init(name: Name) {
        self.name = name
    }
}

extension NS {
    package init(from buffer: inout DNSBuffer) throws {
        self.name = try Name(from: &buffer)
    }
}

extension NS {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.name.encode(into: &buffer)
    }
}
