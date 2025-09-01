/// Not intended to be implemented by users.
/// Use `IPv4Address` or `IPv6Address` which conform to this protocol.
public protocol _IPAddressProtocol: Sendable, Hashable, ExpressibleByIntegerLiteral {
    associatedtype
        AddressType:
            Sendable,
            Hashable,
            FixedWidthInteger,
            UnsignedInteger,
            BitwiseCopyable,
            Comparable
    where AddressType == IntegerLiteralType

    var address: AddressType { get }
}
