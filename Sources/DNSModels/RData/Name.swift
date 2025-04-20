/// A domain name
@available(macOS 9999, *)
public struct Name {
    let isFQDN: Bool
    let labelData: InlineArray<32, UInt8>
    let labelEnds: InlineArray<24, UInt8>
}

@available(macOS 9999, *)
extension Name {
    public static func fromASCII(_ ascii: String) -> Name {
        fatalError("Not implemented")
    }
}
