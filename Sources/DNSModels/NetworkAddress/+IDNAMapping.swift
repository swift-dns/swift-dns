public import SwiftIDNA

extension IDNAMapping {
    /// Based on https://www.unicode.org/Public/idna/17.0.0/IdnaMappingTable.txt
    @inlinable
    static func isIDNAEquivalentAssumingSingleScalarMapping(
        to toScalar: Unicode.Scalar,
        scalar: Unicode.Scalar
    ) -> Bool {
        switch IDNAMapping.for(scalar: scalar) {
        case .valid:
            return scalar == toScalar
        case .mapped(let mapped), .deviation(let mapped):
            return mapped.count == 1 && mapped.first.unsafelyUnwrapped == toScalar
        case .disallowed, .ignored:
            return false
        }
    }
}
