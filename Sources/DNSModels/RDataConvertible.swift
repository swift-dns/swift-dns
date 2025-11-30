@available(swiftDNSApplePlatforms 13, *)
public protocol FromRData: Sendable {
    init(rdata: RData) throws(FromRDataTypeMismatchError<Self>)
}

@available(swiftDNSApplePlatforms 13, *)
public protocol IntoRData: Sendable {
    func toRData() -> RData
}

@available(swiftDNSApplePlatforms 13, *)
public typealias RDataConvertible = FromRData & IntoRData

@available(swiftDNSApplePlatforms 13, *)
public struct FromRDataTypeMismatchError<Expected: FromRData>: Error {
    public let actualValue: RData
}

@available(swiftDNSApplePlatforms 13, *)
extension FromRDataTypeMismatchError: CustomStringConvertible {
    public var description: String {
        "Expected \(type(of: Expected.self)) in RData conversion, but got: \(actualValue)"
    }
}
