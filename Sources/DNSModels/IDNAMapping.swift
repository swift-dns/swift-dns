import CSwiftDNSIDNA

@usableFromInline
package enum IDNAMapping {
    @usableFromInline
    package enum IDNA2008Status {
        case NV8
        case XV8
        case none
    }

    @usableFromInline
    package struct UnicodeScalarsView {
        @usableFromInline
        let pointer: UnsafeBufferPointer<UInt32>
        @usableFromInline
        var readerIndex: UInt8

        @inlinable
        package init(pointer: UnsafeBufferPointer<UInt32>) {
            self.pointer = pointer
            self.readerIndex = 0
        }

        @inlinable
        mutating func next() -> Unicode.Scalar? {
            guard readerIndex < pointer.count else { return nil }
            defer { readerIndex += 1 }
            return Unicode.Scalar(pointer[Int(readerIndex)]).unsafelyUnwrapped
        }
    }

    case valid(IDNA2008Status)
    case mapped(UnicodeScalarsView)
    case deviation(UnicodeScalarsView)
    case disallowed
    case ignored
}

extension IDNAMapping {
    /// Look up IDNA mapping for a given Unicode scalar using the C implementation
    /// - Parameter scalar: The Unicode scalar to look up
    /// - Returns: The corresponding `IDNAMapping` value
    package static func `for`(scalar: Unicode.Scalar) -> IDNAMapping {
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
            let pointer = UnsafeBufferPointer(
                start: result.mapped_unicode_scalars,
                count: Int(result.mapped_count)
            )
            let mappedCodePoints = UnicodeScalarsView(pointer: pointer)
            return .mapped(mappedCodePoints)
        case 2:
            let pointer = UnsafeBufferPointer(
                start: result.mapped_unicode_scalars,
                count: Int(result.mapped_count)
            )
            let mappedCodePoints = UnicodeScalarsView(pointer: pointer)
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

extension [Unicode.Scalar] {
    @inlinable
    mutating func append(contentsOf view: IDNAMapping.UnicodeScalarsView) {
        self.reserveCapacity(Int(view.pointer.count))
        var view = view
        while let scalar = view.next() {
            self.append(scalar)
        }
    }
}
