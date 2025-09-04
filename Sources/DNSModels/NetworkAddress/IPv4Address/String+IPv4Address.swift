public import SwiftIDNA

extension IPv4Address: CustomStringConvertible {
    /// The textual representation of an IPv4 address.
    @inlinable
    public var description: String {
        var result: String = ""
        /// TODO: Smarter reserving capacity
        result.reserveCapacity(7)
        withUnsafeBytes(of: self.address) {
            let range = 0..<4
            var iterator = range.makeIterator()

            let first = iterator.next().unsafelyUnwrapped
            /// TODO: This can be optimized to not have to convert to a string
            result.append(String($0[3 - first]))

            while let idx = iterator.next() {
                result.append(".")
                /// TODO: This can be optimized to not have to convert to a string
                result.append(String($0[3 - idx]))
            }
        }
        return result
    }
}

extension IPv4Address: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt32) {
        self.address = value
    }
}

extension IPv4Address: LosslessStringConvertible {
    /// Initialize an IPv4 address from its textual representation.
    /// That is, 4 decimal UInt8s separated by `.`.
    /// This implementation is IDNA compliant.
    /// That means the following addresses are considered equal: `192｡₁₆₈｡₁｡98`, `192.168.1.98`.
    @inlinable
    public init?(_ description: String) {
        var address: UInt32 = 0

        let scalars = description.unicodeScalars

        var byteIdx = 0
        var chunkStartIndex = scalars.startIndex
        let endIndex = scalars.endIndex
        /// We accept any of the 4 IDNA label separators (including `.`)
        /// This will make sure a valid ipv4 domain-name parses fine using this method
        while let nextSeparatorIdx = scalars[chunkStartIndex..<endIndex].firstIndex(
            where: \.isIDNALabelSeparator
        ) {
            /// TODO: Don't go through an String conversion here
            guard
                let part = IPv4Address.mapToDecimalDigitsBasedOnIDNA(
                    scalars[chunkStartIndex..<nextSeparatorIdx]
                ),
                let byte = UInt8(String(part))
            else {
                return nil
            }

            let shift = 8 &* (3 &- byteIdx)
            address |= UInt32(byte) &<< shift

            /// This is safe, nothing will crash with this increase in index
            chunkStartIndex = scalars.index(nextSeparatorIdx, offsetBy: 1)

            if byteIdx == 2 {
                /// TODO: Don't go through an String conversion here
                /// Read last byte and return
                guard
                    let part = IPv4Address.mapToDecimalDigitsBasedOnIDNA(
                        scalars[chunkStartIndex..<endIndex]
                    ),
                    let byte = UInt8(String(part))
                else {
                    return nil
                }

                address |= UInt32(byte)

                self.init(address)
                return
            }

            byteIdx &+= 1
        }

        /// Should not have reached here
        return nil
    }

    @usableFromInline
    static func mapToDecimalDigitsBasedOnIDNA(
        _ scalars: String.UnicodeScalarView.SubSequence
    ) -> String.UnicodeScalarView.SubSequence? {
        /// Short-circuit if all scalars are ASCII
        if scalars.allSatisfy(\.isASCII) {
            /// Still might not be a valid number
            return scalars
        }

        var newScalars = [Unicode.Scalar]()
        newScalars.reserveCapacity(scalars.count)

        for idx in scalars.indices {
            let scalar = scalars[idx]
            switch IDNAMapping.for(scalar: scalar) {
            case .valid:
                newScalars.append(scalar)
            case .mapped(let mapped), .deviation(let mapped):
                guard mapped.count == 1 else {
                    /// If this was a number it would have never had a mapped value of > 1
                    return nil
                }
                newScalars.append(mapped.first.unsafelyUnwrapped)
            case .ignored:
                continue
            case .disallowed:
                return nil
            }
        }

        return String.UnicodeScalarView.SubSequence(newScalars)
    }
}
