@available(SwiftStdlib 5.1, *)
public protocol Queryable: RDataConvertible {
    static var dnsClass: DNSClass { get }
}
