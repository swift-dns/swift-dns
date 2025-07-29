@available(swiftDNSApplePlatforms 26.0, *)
public protocol Queryable: RDataConvertible {
    static var recordType: RecordType { get }
    static var dnsClass: DNSClass { get }
}
