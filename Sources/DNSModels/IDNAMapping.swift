import CSwiftDNSIDNA

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

extension IDNAMapping {
    /// Look up IDNA mapping for a given Unicode scalar using the C implementation
    /// - Parameter scalar: The Unicode scalar to look up
    /// - Returns: The corresponding `IDNAMapping` value
    @inlinable
    package static func `for`(scalar: Unicode.Scalar) -> IDNAMapping {
        /// `unsafelyUnwrapped` because the C function is guaranteed to return a non-nil pointer.
        /// There are also extensive tests in IDNATests for this function.
        let result = idna_mapping_lookup(scalar.value).unsafelyUnwrapped.pointee
        switch result.type {
        case 0:
            let status: IDNAMapping.IDNA2008Status =
                switch result.status {
                case 0: .NV8
                case 1: .XV8
                case 2: .none
                default:
                    fatalError(
                        "Unexpected IDNAMapping.IDNA2008Status: \(result.status) for type \(result.type)"
                    )
                }
            return .valid(status)
        case 1:
            let mappedCodePoints = Array(
                UnsafeBufferPointer(
                    start: result.mapped_unicode_scalars,
                    count: Int(result.mapped_count)
                )
            ).map {
                /// `unsafelyUnwrapped` because the C function is guaranteed to return a Unicode.Scalar.
                /// There are also extensive tests in IDNATests for this function.
                Unicode.Scalar($0).unsafelyUnwrapped
            }
            return .mapped(mappedCodePoints)
        case 2:
            let mappedCodePoints = Array(
                UnsafeBufferPointer(
                    start: result.mapped_unicode_scalars,
                    count: Int(result.mapped_count)
                )
            ).map {
                /// `unsafelyUnwrapped` because the C function is guaranteed to return a Unicode.Scalar.
                /// There are also extensive tests in IDNATests for this function.
                Unicode.Scalar($0).unsafelyUnwrapped
            }
            return .deviation(mappedCodePoints)
        case 3:
            return .disallowed
        case 4:
            return .ignored
        default:
            fatalError("Unexpected IDNAMappingResultType: \(result.type)")
        }
    }
}
