@available(swiftDNSApplePlatforms 10.15, *)
public protocol Queryable: RDataConvertible {
    static var recordType: RecordType { get }
    static var dnsClass: DNSClass { get }
}
