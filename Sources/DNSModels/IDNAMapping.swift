package enum IDNAMapping: Equatable {
    package enum IDNA2008Status {
        case NV8
        case XV8
        case none
    }

    case valid(IDNA2008Status)
    /// TODO: This can be just a InlineArray<4, Unicode.Scalar?>
    /// Investigate if that helps with the IDNA performance
    case mapped([Unicode.Scalar])
    /// TODO: This can be just a InlineArray<4, Unicode.Scalar?>
    /// Investigate if that helps with the IDNA performance
    case deviation([Unicode.Scalar])
    case disallowed
    case ignored
}
