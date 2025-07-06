/// RRSIG is really a derivation of the original SIG record data. See SIG for more documentation
public struct RRSIG: Sendable {
    public var value: SIG

    public init(value: SIG) {
        self.value = value
    }
}

extension RRSIG {
    package init(from buffer: inout DNSBuffer) throws {
        self.value = try SIG(from: &buffer)
    }
}

extension RRSIG {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.value.encode(into: &buffer)
    }
}

extension RRSIG: RDataConvertible {
    public init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>) {
        switch rdata {
        case .DNSSEC(.RRSIG(let rrsig)):
            self = rrsig
        default:
            throw RDataConversionTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    public func toRData() -> RData {
        .DNSSEC(.RRSIG(self))
    }
}

extension RRSIG: Queryable {
    @inlinable
    public static var recordType: RecordType { .RRSIG }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
