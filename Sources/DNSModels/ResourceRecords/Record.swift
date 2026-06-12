/// Resource records are storage value in DNS, into which all key/value pair data is stored.
///
/// # Generic type
/// * `R` - the RecordData type this resource record represents, if unknown at runtime use the `RData` abstract enum type
///
/// [RFC 1035](https://tools.ietf.org/html/rfc1035), DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987
///
/// ```text
/// 4.1.3. Resource record format
///
/// The answer, authority, and additional sections all share the same
/// format: a variable number of resource records, where the number of
/// records is specified in the corresponding count field in the header.
/// Each resource record has the following format:
///                                     1  1  1  1  1  1
///       0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                                               |
///     /                                               /
///     /                      NAME                     /
///     |                                               |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                      TYPE                     |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                     CLASS                     |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                      TTL                      |
///     |                                               |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                   RDLENGTH                    |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
///     /                     RDATA                     /
///     /                                               /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// ```
@available(swiftDNSApplePlatforms 10.15, *)
public struct Record: Sendable {
    public var nameLabels: DomainName
    public var recordType: RecordType {
        rdata.recordType
    }
    public var dnsClass: DNSClass
    public var ttl: UInt32
    public var rdata: RData

    package init(nameLabels: DomainName, dnsClass: DNSClass, ttl: UInt32, rdata: RData) {
        self.nameLabels = nameLabels
        self.dnsClass = dnsClass
        self.ttl = ttl
        self.rdata = rdata
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension Record {
    package init(from buffer: inout DNSBuffer) throws {
        self.nameLabels = try DomainName(from: &buffer)
        let recordType = try RecordType(from: &buffer)
        self.dnsClass = try DNSClass(from: &buffer)
        self.ttl = try buffer.readInteger(as: UInt32.self).unwrap(
            or: .failedToRead("Record.ttl", buffer)
        )
        self.rdata = try RData(
            from: &buffer,
            recordType: recordType
        )
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension [Record] {
    package enum DecodingError: Error {
        case mustBeFinalResourceRecord(String)
        case multipleEDNSRecords
    }

    package static func from(
        buffer: inout DNSBuffer,
        count: UInt16,
        isAdditional: Bool
    ) throws -> (records: TinyArray<1, Record>, edns: EDNS?, sigs: TinyArray<1, Record>) {
        var records = TinyArray<1, Record>()
        var edns: EDNS? = nil
        var sigs = TinyArray<1, Record>()

        // SIG0 must be last, once this is set, disable.
        var sawSIG0 = false
        // TSIG must be last, once this is set, disable.
        var sawTSIG = false
        for _ in 0..<count {
            let record = try Record(from: &buffer)
            if sawTSIG {
                throw DecodingError.mustBeFinalResourceRecord("TSIG")
            }  // TSIG must be last and multiple TSIG records are not allowed
            if !isAdditional {
                if sawSIG0 {
                    throw DecodingError.mustBeFinalResourceRecord("SIG0")
                }  // SIG0 must be last
                records.append(record)
            } else {
                switch record.rdata.recordType {
                case .SIG:
                    sawSIG0 = true
                    sigs.append(record)
                case .TSIG:
                    if sawSIG0 {
                        throw DecodingError.mustBeFinalResourceRecord("SIG0")
                    }  // SIG0 must be last
                    sawTSIG = true
                    sigs.append(record)
                case .OPT:
                    if sawSIG0 {
                        throw DecodingError.mustBeFinalResourceRecord("SIG0")
                    }  // SIG0 must be last
                    if edns != nil {
                        throw DecodingError.multipleEDNSRecords
                    }
                    edns = EDNS(fromOPTRecord: record)
                default:
                    if sawSIG0 {
                        throw DecodingError.mustBeFinalResourceRecord("SIG0")
                    }  // SIG0 must be last
                    records.append(record)
                }
            }
        }

        return (records, edns, sigs)
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension Record {
    package func encode(into buffer: inout DNSBuffer) throws {
        try nameLabels.encode(into: &buffer)
        recordType.encode(into: &buffer)
        dnsClass.encode(into: &buffer)
        buffer.writeInteger(ttl)
        try rdata.encode(into: &buffer)
    }
}
