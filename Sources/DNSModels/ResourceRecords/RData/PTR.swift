/// The DNS PTR record type
public struct PTR: Sendable {
    public var name: Name

    public init(name: Name) {
        self.name = name
    }
}

extension PTR {
    package init(from buffer: inout DNSBuffer) throws {
        self.name = try Name(from: &buffer)
    }
}

extension PTR {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.name.encode(into: &buffer)
    }
}
