/// The DNS NS record type
public struct NS: Sendable {
    public var name: DomainName

    public init(name: DomainName) {
        self.name = name
    }
}

extension NS {
    package init(from buffer: inout DNSBuffer) throws {
        self.name = try DomainName(from: &buffer)
    }
}

extension NS {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.name.encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension NS: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .NS(let ns):
            self = ns
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .NS(self)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension NS: Queryable {
    @inlinable
    public static var recordType: RecordType { .NS }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
