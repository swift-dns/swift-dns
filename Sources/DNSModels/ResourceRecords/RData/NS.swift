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

extension NS: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .NS(let ns):
            self = ns
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .NS(self)
    }
}

extension NS: Queryable {
    @inlinable
    public static var recordType: RecordType { .NS }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
