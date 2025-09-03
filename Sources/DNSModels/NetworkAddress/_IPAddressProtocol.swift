/// DO NOT IMPLEMENT THIS PROTOCOL YOURSELF.
/// Use `IPv4Address` or `IPv6Address` which conform to this protocol.
///
/// This is always either `IPv4Address` or `IPv6Address`.
/// There is no need to assume any other type will be added in the future, as that would
/// require a new IP version to be introduced, in which case it'll take years before that
/// new IP version is adopted, and at that point we'll just have released a new major version.
public protocol _IPAddressProtocol:
    Sendable,
    Hashable,
    ExpressibleByIntegerLiteral
where
    IntegerLiteralType: Sendable
        & Hashable
        & FixedWidthInteger
        & UnsignedInteger
        & BitwiseCopyable
        & Comparable
{
    var address: IntegerLiteralType { get }
    @available(swiftDNSApplePlatforms 15, *)
    init?(exactly ipAddress: IPAddress)
}
