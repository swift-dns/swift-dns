/// Query struct for looking up resource records, basically a resource record without RDATA.
///
/// [RFC 1035, DOMAIN NAMES - IMPLEMENTATION AND SPECIFICATION, November 1987](https://tools.ietf.org/html/rfc1035)
///
/// ```text
/// 4.1.2. Question section format
///
/// The question section is used to carry the "question" in most queries,
/// i.e., the parameters that define what is being asked.  The section
/// contains QDCOUNT (usually 1) entries, each of the following format:
///
///                                     1  1  1  1  1  1
///       0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                                               |
///     /                     QNAME / ZNAME             /
///     /                                               /
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                     QTYPE / ZTYPE             |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///     |                     QCLASS / ZCLASS           |
///     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
///
/// ```
public struct Query: Sendable {
    /// QNAME
    public var name: DomainName
    /// QTYPE
    public var queryType: RecordType
    /// QCLASS
    public var queryClass: DNSClass

    public init(name: DomainName, queryType: RecordType, queryClass: DNSClass) {
        self.name = name
        self.queryType = queryType
        self.queryClass = queryClass
    }
}

extension Query {
    package init(from buffer: inout DNSBuffer) throws {
        self.name = try DomainName(from: &buffer)
        self.queryType = try RecordType(from: &buffer)
        self.queryClass = try DNSClass(from: &buffer)
    }
}

extension Query {
    package func encode(into buffer: inout DNSBuffer) throws {
        try self.name.encode(into: &buffer)
        self.queryType.encode(into: &buffer)
        self.queryClass.encode(into: &buffer)
    }
}
