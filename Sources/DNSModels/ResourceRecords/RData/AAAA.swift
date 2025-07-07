/// The DNS AAAA record type, an IPv6 address
public struct AAAA: Sendable {
    public var value: IPv6Address

    public init(value: IPv6Address) {
        self.value = value
    }
}

extension AAAA {
    package init(from buffer: inout DNSBuffer) throws {
        self.value = try IPv6Address(from: &buffer)
    }
}

extension AAAA {
    package func encode(into buffer: inout DNSBuffer) {
        value.encode(into: &buffer)
    }
}

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

extension AAAA: Queryable {
    @inlinable
    public static var recordType: RecordType { .AAAA }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
