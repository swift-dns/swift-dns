public protocol FromRData: Sendable {
    init(rdata: RData) throws(RDataConversionTypeMismatchError<Self>)
}

public protocol IntoRData: Sendable {
    func toRData() -> RData
}

public typealias RDataConvertible = FromRData & IntoRData

public struct RDataConversionTypeMismatchError<Expected: FromRData>: Error {
    public let actualValue: RData
}

extension RDataConversionTypeMismatchError: CustomStringConvertible {
    public var description: String {
        "Expected \(type(of: Expected.self)) in RData conversion, but got: \(actualValue)"
    }
}
