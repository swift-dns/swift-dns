public import DNSCore

/// DNS Request options.
public struct DNSRequestOptions: Sendable, OptionSet {
    public var rawValue: UInt

    @inlinable
    public static var edns: DNSRequestOptions {
        DNSRequestOptions(rawValue: 1 &<<< 0)
    }

    @inlinable
    public static var `default`: DNSRequestOptions {
        DNSRequestOptions()
    }

    @inlinable
    public init(rawValue: UInt = 0) {
        self.rawValue = rawValue
    }
}
