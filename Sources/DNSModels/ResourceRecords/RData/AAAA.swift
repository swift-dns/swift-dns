/// The DNS AAAA record type, an IPv6 address
@available(swiftDNSApplePlatforms 13, *)
public struct AAAA: Sendable {
    public var value: IPv6Address

    public init(value: IPv6Address) {
        self.value = value
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension AAAA {
    package init(from buffer: inout DNSBuffer) throws {
        self.value = try IPv6Address(from: &buffer)
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension AAAA {
    package func encode(into buffer: inout DNSBuffer) {
        value.encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension AAAA: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .AAAA(let aaaa):
            self = aaaa
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .AAAA(self)
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension AAAA: Queryable {
    @inlinable
    public static var recordType: RecordType { .AAAA }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
