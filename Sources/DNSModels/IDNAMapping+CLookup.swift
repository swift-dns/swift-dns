import CSwiftDNSIDNA

// This file provides Swift bindings for the C-based IDNA mapping lookup functions

// C struct definitions (matching the C header)
private struct IDNAMappingResult {
    let type: UInt8
    let status: UInt8
    let mapped_unicode_scalars: UnsafePointer<UInt32>?
    let mapped_count: UInt8
}

extension IDNAMapping {
    /// Look up IDNA mapping for a given Unicode scalar using the C implementation
    /// - Parameter scalar: The Unicode scalar to look up
    /// - Returns: The corresponding `IDNAMapping` value, or `nil` if lookup fails
    @inlinable
    package static func `for`(scalar: UnicodeScalar) -> IDNAMapping {
        /// `unsafelyUnwrapped` because the C function is guaranteed to return a non-nil pointer.
        /// There are also extensive tests in the IDNATests for this function.
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
                /// `unsafelyUnwrapped` because the C function is guaranteed to return a UnicodeScalar.
                /// There are also extensive tests in the IDNATests for this function.
                UnicodeScalar($0).unsafelyUnwrapped
            }
            return .mapped(mappedCodePoints)
        case 2:
            let mappedCodePoints = Array(
                UnsafeBufferPointer(
                    start: result.mapped_unicode_scalars,
                    count: Int(result.mapped_count)
                )
            ).map {
                /// `unsafelyUnwrapped` because the C function is guaranteed to return a UnicodeScalar.
                /// There are also extensive tests in the IDNATests for this function.
                UnicodeScalar($0).unsafelyUnwrapped
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
