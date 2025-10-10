public import struct NIOCore.ByteBuffer

/// [RFC 3403 DDDS DNS Database, October 2002](https://tools.ietf.org/html/rfc3403#section-4)
///
/// ```text
/// 4.1 Packet Format
///
///   The packet format of the NAPTR RR is given below.  The DNS type code
///   for NAPTR is 35.
///
///      The packet format for the NAPTR record is as follows
///                                       1  1  1  1  1  1
///         0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       |                     ORDER                     |
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       |                   PREFERENCE                  |
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       /                     FLAGS                     /
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       /                   SERVICES                    /
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       /                    REGEXP                     /
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///       /                  REPLACEMENT                  /
///       /                                               /
///       +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
///   <character-string> and <domain-name> as used here are defined in RFC
///   1035 [7].
/// ```
public struct NAPTR: Sendable {
    public var order: UInt16
    public var preference: UInt16
    public var flags: ByteBuffer
    public var services: ByteBuffer
    public var regexp: ByteBuffer
    public var replacement: DomainName

    public init(
        order: UInt16,
        preference: UInt16,
        flags: ByteBuffer,
        services: ByteBuffer,
        regexp: ByteBuffer,
        replacement: DomainName
    ) {
        self.order = order
        self.preference = preference
        self.flags = flags
        self.services = services
        self.regexp = regexp
        self.replacement = replacement
    }
}

@available(swiftDNSApplePlatforms 13, *)
extension NAPTR {
    package init(from buffer: inout DNSBuffer) throws {
        self.order = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("NAPTR.order", buffer)
        )
        self.preference = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("NAPTR.preference", buffer)
        )
        self.flags = try buffer.readLengthPrefixedStringByteBuffer(name: "NAPTR.flags")
        self.services = try buffer.readLengthPrefixedStringByteBuffer(name: "NAPTR.services")
        self.regexp = try buffer.readLengthPrefixedStringByteBuffer(name: "NAPTR.regexp")
        self.replacement = try DomainName(from: &buffer)
    }
}

extension NAPTR {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.order)
        buffer.writeInteger(self.preference)
        try buffer.writeLengthPrefixedString(
            name: "NAPTR.flags",
            bytes: self.flags,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
        try buffer.writeLengthPrefixedString(
            name: "NAPTR.services",
            bytes: self.services,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
        try buffer.writeLengthPrefixedString(
            name: "NAPTR.regexp",
            bytes: self.regexp,
            maxLength: 255,
            fitLengthInto: UInt8.self
        )
        try self.replacement.encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension NAPTR: RDataConvertible {
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .NAPTR(let naptr):
            self = naptr
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .NAPTR(self)
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension NAPTR: Queryable {
    @inlinable
    public static var recordType: RecordType { .NAPTR }

    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
