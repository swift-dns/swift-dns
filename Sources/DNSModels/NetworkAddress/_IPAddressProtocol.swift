/// DO NOT IMPLEMENT THIS PROTOCOL YOURSELF.
/// Use `IPv4Address` or `IPv6Address` which conform to this protocol.
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
}
