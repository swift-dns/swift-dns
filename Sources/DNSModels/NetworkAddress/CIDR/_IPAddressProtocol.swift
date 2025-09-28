/// DO NOT IMPLEMENT THIS PROTOCOL YOURSELF.
/// THIS PROTOCOL IS NOT CONSIDERED PART OF THE PUBLIC API, DENOTED BY THE UNDERSCORED NAME.
///
/// Use `IPAddress`, `IPv4Address` or `IPv6Address` instead.
///
/// This is always either `IPv4Address` or `IPv6Address`.
/// There is no need to assume any other type will be added in the future, as that would
/// require a new IP version to be introduced, in which case it'll take years before that
/// new IP version is adopted, and at that point we'll have released a new major version
/// to support that new IP version.
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

    @available(swiftDNSApplePlatforms 26, *)
    init?(__uncheckedASCIIspan: Span<UInt8>)
}
