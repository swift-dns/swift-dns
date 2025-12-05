/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// 3.3.14. TXT RDATA format
///
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     /                   TXT-DATA                    /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
///
/// TXT RRs are used to hold descriptive text.  The semantics of the text
/// depends on the domain where it is found.
/// ```
public struct TXT: Sendable {
    public var txtData: [String]

    public init(txtData: [String]) {
        self.txtData = txtData
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension TXT {
    /// Initialize a TXT record from a slice of a buffer.
    /// Due to how TXT record parsing works, this initializer will exhaust the buffer.
    /// Therefore you must only pass the rdata slice to it.
    package init(from buffer: inout DNSBuffer) throws {
        self.txtData = []
        while buffer.readableBytes > 0 {
            self.txtData.append(
                try buffer.readLengthPrefixedStringAsString(name: "TXT.txtData[]")
            )
        }
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension TXT {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.reserveCapacity(
            minimumWritableBytes: self.txtData.reduce(into: 0) {
                $0 += $1.lengthInDNSWireProtocol
            }
        )
        for txt in self.txtData {
            try buffer.writeLengthPrefixedString(
                name: "TXT.txtData[]",
                bytes: txt.utf8,
                maxLength: 255,
                fitLengthInto: UInt8.self
            )
        }
    }
}

extension TXT: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.txtData == rhs.txtData
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension TXT: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .TXT(let txt):
            self = txt
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .TXT(self)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension TXT: Queryable {
    @inlinable
    public static var recordType: RecordType { .TXT }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
