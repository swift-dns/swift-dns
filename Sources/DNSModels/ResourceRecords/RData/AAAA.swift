/// The DNS AAAA record type, an IPv6 address
@available(SwiftStdlib 5.1, *)
public struct AAAA: Sendable, Hashable {
    public var value: IPv6Address

    public init(value: IPv6Address) {
        self.value = value
    }
}

@available(SwiftStdlib 5.1, *)
extension AAAA {
    package init(from buffer: inout DNSBuffer) throws {
        self.value = try IPv6Address(from: &buffer)
    }
}

@available(SwiftStdlib 5.1, *)
extension AAAA {
    package func encode(into buffer: inout DNSBuffer) {
        value.encode(into: &buffer)
    }
}

@available(SwiftStdlib 5.1, *)
extension AAAA: RDataConvertible {
    @inlinable
    public static var recordType: RecordType { .AAAA }

    @inlinable
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

@available(SwiftStdlib 5.1, *)
extension AAAA: Queryable {
    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
