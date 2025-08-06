/// The DNS NS record type
@available(swiftDNSApplePlatforms 26, *)
public struct NS: Sendable {
    public var name: Name

    public init(name: Name) {
        self.name = name
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension NS {
    /// Expects the whole buffer to be the `NS` record.
    /// This is always true when called from `RData.init(from:recordType:)`.
    package init(from buffer: inout DNSBuffer) throws {
        self.name = try Name(from: &buffer, knownLength: buffer.readableBytes)
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension NS {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.name.encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 26, *)
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

@available(swiftDNSApplePlatforms 26, *)
extension NS: Queryable {
    @inlinable
    public static var recordType: RecordType { .NS }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
