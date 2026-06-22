@available(SwiftStdlib 5.1, *)
public protocol FromRData: Sendable {
    static var recordType: RecordType { get }

    init(rdata: RData) throws(FromRDataTypeMismatchError<Self>)
}

@available(SwiftStdlib 5.1, *)
public protocol IntoRData: Sendable {
    static var recordType: RecordType { get }

    func toRData() -> RData
}

@available(SwiftStdlib 5.1, *)
public typealias RDataConvertible = FromRData & IntoRData

@available(SwiftStdlib 5.1, *)
public struct FromRDataTypeMismatchError<Expected: FromRData>: Error {
    public let actualValue: RData

    @inlinable
    package init(actualValue: RData) {
        self.actualValue = actualValue
    }
}

@available(SwiftStdlib 5.1, *)
extension FromRDataTypeMismatchError: CustomStringConvertible {
    public var description: String {
        "Expected \(type(of: Expected.self)) in RData conversion, but got: \(actualValue)"
    }
}
