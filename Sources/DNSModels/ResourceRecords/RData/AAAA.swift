/// The DNS AAAA record type, an IPv6 address
public struct AAAA: Sendable {
    public var value: IPv6Address

    public init(value: IPv6Address) {
        self.value = value
    }
}

extension AAAA {
    package init(from buffer: inout DNSBuffer) throws {
        self.value = try IPv6Address(from: &buffer)
    }
}

extension AAAA {
    package func encode(into buffer: inout DNSBuffer) {
        value.encode(into: &buffer)
    }
}
