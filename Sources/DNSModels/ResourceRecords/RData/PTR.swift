/// The DNS PTR record type
public struct PTR: Sendable {
    public var domainName: DomainName

    public init(domainName: DomainName) {
        self.domainName = domainName
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension PTR {
    package init(from buffer: inout DNSBuffer) throws {
        self.domainName = try DomainName(from: &buffer)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension PTR {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.domainName.encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension PTR: RDataConvertible {
    @inlinable
    public static var recordType: RecordType { .PTR }

    @inlinable
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

@available(swiftDNSApplePlatforms 10.15, *)
extension PTR: Queryable {
    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
