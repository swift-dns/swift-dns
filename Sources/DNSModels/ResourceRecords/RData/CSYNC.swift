/// [RFC 7477, Child-to-Parent Synchronization in DNS, March 2015][rfc7477]
///
/// ```text
/// 2.1.1.  The CSYNC Resource Record Wire Format
///
/// The CSYNC RDATA consists of the following fields:
///
///                       1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
///   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///  |                          SOA Serial                           |
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///  |       Flags                   |            Type Bit Map       /
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
///  /                     Type Bit Map (continued)                  /
///  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// ```
///
/// [rfc7477]: https://tools.ietf.org/html/rfc7477
public struct CSYNC: Sendable {
    public var soaSerial: UInt32
    public var immediate: Bool
    public var soaMinimum: Bool
    public var reservedFlags: UInt16
    public var typeBitMaps: RecordTypeSet

    public var flags: UInt16 {
        var flags = self.reservedFlags & 0b1111_1111_1111_1100
        if self.immediate {
            flags |= 0b0000_0001
        }
        if self.soaMinimum {
            flags |= 0b0000_0010
        }
        return flags
    }

    public init(
        soaSerial: UInt32,
        immediate: Bool,
        soaMinimum: Bool,
        reservedFlags: UInt16,
        typeBitMaps: RecordTypeSet
    ) {
        self.soaSerial = soaSerial
        self.immediate = immediate
        self.soaMinimum = soaMinimum
        self.reservedFlags = reservedFlags
        self.typeBitMaps = typeBitMaps
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension CSYNC {
    package init(from buffer: inout DNSBuffer) throws {
        self.soaSerial = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("CSYNC.soaSerial", buffer)
        )
        let flags = try buffer.readInteger(as: UInt16.self).unwrap(
            or: .failedToRead("CSYNC.flags", buffer)
        )
        /// TODO: flag parsing like in Header Bytes3And4
        self.immediate = flags & 0b0000_0001 == 0b0000_0001
        self.soaMinimum = flags & 0b0000_0010 == 0b0000_0010
        self.reservedFlags = flags & 0b1111_1111_1111_1100
        self.typeBitMaps = try RecordTypeSet(from: &buffer)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension CSYNC {
    package func encode(into buffer: inout DNSBuffer) throws {
        buffer.writeInteger(self.soaSerial)
        buffer.writeInteger(self.flags)
        self.typeBitMaps.encode(into: &buffer)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension CSYNC: RDataConvertible {
    @inlinable
    public static var recordType: RecordType { .CSYNC }

    @inlinable
    public init(rdata: RData) throws(FromRDataTypeMismatchError<Self>) {
        switch rdata {
        case .CSYNC(let csync):
            self = csync
        default:
            throw FromRDataTypeMismatchError<Self>(actualValue: rdata)
        }
    }

    @inlinable
    public func toRData() -> RData {
        .CSYNC(self)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension CSYNC: Queryable {
    @inlinable
    public static var dnsClass: DNSClass { .IN }
}
