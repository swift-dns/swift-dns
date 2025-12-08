@available(swiftDNSApplePlatforms 10.15, *)
public protocol FromRData: Sendable {
    static var recordType: RecordType { get }

    init(rdata: RData) throws(FromRDataTypeMismatchError<Self>)
}

@available(swiftDNSApplePlatforms 10.15, *)
public protocol IntoRData: Sendable {
    static var recordType: RecordType { get }

    func toRData() -> RData
}

@available(swiftDNSApplePlatforms 10.15, *)
public typealias RDataConvertible = FromRData & IntoRData

@available(swiftDNSApplePlatforms 10.15, *)
public struct FromRDataTypeMismatchError<Expected: FromRData>: Error {
    public let actualValue: RData

    @inlinable
    package init(actualValue: RData) {
        self.actualValue = actualValue
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension FromRDataTypeMismatchError: CustomStringConvertible {
    public var description: String {
        "Expected \(type(of: Expected.self)) in RData conversion, but got: \(actualValue)"
    }
}
