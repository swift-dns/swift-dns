/// RRSIG is really a derivation of the original SIG record data. See SIG for more documentation
public struct RRSIG: Sendable {
    public var value: SIG

    public init(value: SIG) {
        self.value = value
    }
}

extension RRSIG {
    package init(from buffer: inout DNSBuffer) throws {
        self.value = try SIG(from: &buffer)
    }
}

extension RRSIG {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.value.encode(into: &buffer)
    }
}
