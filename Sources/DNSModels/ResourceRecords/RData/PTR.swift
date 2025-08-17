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

@available(swiftDNSApplePlatforms 15, *)
extension PTR: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .PTR(let ptr):
            self = ptr
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .PTR(self)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension PTR: Queryable {
    @inlinable
    public static var recordType: RecordType { .PTR }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
