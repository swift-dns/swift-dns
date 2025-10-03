/// The DNS NS record type
public struct NS: Sendable {
    public var domainName: DomainName

    public init(domainName: DomainName) {
        self.domainName = domainName
    }
}

extension NS {
    package init(from buffer: inout DNSBuffer) throws {
        self.domainName = try DomainName(from: &buffer)
    }
}

extension NS {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.domainName.encode(into: &buffer)
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
