public protocol FromRData: Sendable {
    init(rdata: RData) throws(FromRDataTypeMismatchError<Self>)
}

public protocol IntoRData: Sendable {
    func toRData() -> RData
}

public typealias RDataConvertible = FromRData & IntoRData

public struct FromRDataTypeMismatchError<Expected: FromRData>: Error {
    public let actualValue: RData
}

extension FromRDataTypeMismatchError: CustomStringConvertible {
    public var description: String {
        "Expected \(type(of: Expected.self)) in RData conversion, but got: \(actualValue)"
    }
}
