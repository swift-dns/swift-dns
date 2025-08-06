/// The DNS PTR record type
@available(swiftDNSApplePlatforms 26, *)
public struct PTR: Sendable {
    public var name: Name

    public init(name: Name) {
        self.name = name
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension PTR {
    /// Expects the whole buffer to be the `PTR` record.
    /// This is always true when called from `RData.init(from:recordType:)`.
    package init(from buffer: inout DNSBuffer) throws {
        self.name = try Name(from: &buffer, knownLength: buffer.readableBytes)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension PTR {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.name.encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 26, *)
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

@available(swiftDNSApplePlatforms 26, *)
extension PTR: Queryable {
    @inlinable
    public static var recordType: RecordType { .PTR }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
