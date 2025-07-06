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

extension PTR: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .PTR(let ptr):
            self = ptr
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .PTR(self)
    }
}

extension PTR: Queryable {
    @inlinable
    public static var recordType: RecordType { .PTR }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
