package enum IDNA {
    package struct MappingErrors: Error {
        package enum Element: CustomStringConvertible {
            case domainNameContainsDisallowedCharacter(UnicodeScalar)
            case labelStartsWithXNDashDashButContainsNonASCII(UnicodeScalar)
            case labelPunycodeEncodeFailed(label: Substring.UTF8View)
            case labelPunycodeDecodeFailed(label: Substring.UTF8View)
            case labelIsEmptyAfterPunycodeConversion(label: Substring)
            case labelContainsOnlyASCIIAfterPunycodeConversion(label: Substring)
            case labelTooLongForDNS(label: Substring)
            case labelEmptyForDNS(label: Substring)
            case domainNameTooLongForDNS(labels: [Substring])

            package var description: String {
                switch self {
                case .domainNameContainsDisallowedCharacter(let scalar):
                    return ".domainNameContainsDisallowedCharacter(\(scalar.debugDescription))"
                case .labelStartsWithXNDashDashButContainsNonASCII(let scalar):
                    return
                        ".labelStartsWithXNDashDashButContainsNonASCII(\(scalar.debugDescription))"
                case .labelPunycodeEncodeFailed(let label):
                    return
                        ".labelPunycodeEncodeFailed(\(String(Substring(label)).debugDescription))"
                case .labelPunycodeDecodeFailed(let label):
                    return
                        ".labelPunycodeDecodeFailed(\(String(label).debugDescription))"
                case .labelIsEmptyAfterPunycodeConversion(let label):
                    return
                        ".labelIsEmptyAfterPunycodeConversion(\(String(Substring(label)).debugDescription))"
                case .labelContainsOnlyASCIIAfterPunycodeConversion(let label):
                    return
                        ".labelContainsOnlyASCIIAfterPunycodeConversion(\(String(Substring(label)).debugDescription))"
                case .labelTooLongForDNS(let label):
                    return ".labelTooLongForDNS(\(String(label).debugDescription))"
                case .labelEmptyForDNS(let label):
                    return ".labelEmptyForDNS(\(String(label).debugDescription))"
                case .domainNameTooLongForDNS(let labels):
                    return ".domainNameTooLongForDNS(\(labels.map(String.init)))"
                }
            }
        }

        package let domainName: String
        package private(set) var errors: [Element]

        var isEmpty: Bool {
            self.errors.isEmpty
        }

        init(domainName: String) {
            self.domainName = domainName
            self.errors = []
        }

        mutating func append(_ error: Element) {
            self.errors.append(error)
        }
    }

    package static func toASCII(
        domainName: inout String,
        checkHyphens: Bool,
        checkBidi: Bool,
        checkJoiners: Bool,
        useSTD3ASCIIRules: Bool,
        verifyDnsLength: Bool,
        ignoreInvalidPunycode: Bool
    ) throws(MappingErrors) {
        var errors = MappingErrors(domainName: domainName)
        // 1.
        IDNA.mainProcessing(
            domainName: &domainName,
            useSTD3ASCIIRules: useSTD3ASCIIRules,
            checkHyphens: checkHyphens,
            checkBidi: checkBidi,
            checkJoiners: checkJoiners,
            ignoreInvalidPunycode: ignoreInvalidPunycode,
            errors: &errors
        )

        // 2., 3.
        let labels = domainName.utf8.split(
            separator: UInt8.asciiDot
        ).map { label -> Substring in
            if label.allSatisfy(\.isASCII) {
                return Substring(label)
            }
            var newLabel = Substring(label)
            if !Punycode.encode(&newLabel) {
                errors.append(.labelPunycodeEncodeFailed(label: label))
            }
            return "xn--" + Substring(newLabel)
        }

        if verifyDnsLength {
            /// FIXME: what about the trailing 0? make sure tests cover that

            var totalLength = 0
            for label in labels {
                let labelLength = label.utf8.count
                totalLength += labelLength
                if labelLength > 63 {
                    errors.append(.labelTooLongForDNS(label: label))
                }
                if labelLength == 0 {
                    errors.append(.labelEmptyForDNS(label: label))
                }
            }

            /// 254 but excluding the trailing null byte aka root label
            if totalLength > 253 {
                errors.append(.domainNameTooLongForDNS(labels: labels))
            }
        }

        if !errors.isEmpty {
            throw errors
        }

        domainName = labels.joined(separator: ".")
    }

    /// An implementation of https://www.unicode.org/reports/tr46/#Processing
    static func mainProcessing(
        domainName: inout String,
        useSTD3ASCIIRules: Bool,
        checkHyphens: Bool,
        checkBidi: Bool,
        checkJoiners: Bool,
        ignoreInvalidPunycode: Bool,
        errors: inout MappingErrors
    ) {
        var newBytes: [UInt8] = []
        /// TODO: optimize reserve capacity
        newBytes.reserveCapacity(domainName.utf8.count * 12 / 10)

        /// 1. Map
        for scalar in domainName.unicodeScalars {
            switch IDNAMapping.for(scalar: scalar) {
            case .valid(_):
                newBytes.append(contentsOf: scalar.utf8)
            case .mapped(let mappedScalars):
                newBytes.append(contentsOf: mappedScalars.flatMap(\.utf8))
            case .deviation(_):
                newBytes.append(contentsOf: scalar.utf8)
            case .disallowed:
                newBytes.append(contentsOf: scalar.utf8)
            case .ignored:
                break
            }
        }

        /// 2. Normalize
        domainName = String(decoding: newBytes, as: UTF8.self)
        domainName = domainName.asNFC

        /// 3. Break, 4. Convert/Validate.
        domainName = domainName.utf8.split(
            separator: UInt8.asciiDot
        ).map { label in
            Substring(
                convertAndValidateLabel(
                    label,
                    ignoreInvalidPunycode: ignoreInvalidPunycode,
                    errors: &errors
                )
            )
        }.joined(separator: ".")
    }

    static func convertAndValidateLabel(
        _ label: Substring.UTF8View,
        ignoreInvalidPunycode: Bool,
        errors: inout MappingErrors
    ) -> Substring.UTF8View {
        var newLabel = Substring(label)

        /// Checks if the label starts with “xn--”
        if label.count > 3,
            label[label.startIndex] == UInt8.asciiLowercasedX,
            label[label.index(label.startIndex, offsetBy: 1)] == UInt8.asciiLowercasedN,
            label[label.index(label.startIndex, offsetBy: 2)] == UInt8.asciiDash,
            label[label.index(label.startIndex, offsetBy: 3)] == UInt8.asciiDash
        {
            /// 4.1:
            if let nonASCII = label.first(where: { !$0.isASCII }) {
                errors.append(
                    .labelStartsWithXNDashDashButContainsNonASCII(UnicodeScalar(nonASCII))
                )
                return label/// continue to next label
            }

            /// 4.2:
            /// If conversion fails, and we're not ignoring invalid punycode, record an error

            /// Drop the "xn--" prefix
            newLabel = Substring(newLabel.unicodeScalars.dropFirst(4))

            if !Punycode.decode(&newLabel),
                !ignoreInvalidPunycode
            {
                errors.append(.labelPunycodeDecodeFailed(label: label))
                return label/// continue to next label
            }

            if newLabel.isEmpty {
                errors.append(.labelIsEmptyAfterPunycodeConversion(label: newLabel))
            }

            if newLabel.allSatisfy(\.isASCII) {
                errors.append(.labelContainsOnlyASCIIAfterPunycodeConversion(label: newLabel))
            }
        }

        verifyValidLabel(newLabel.utf8, errors: &errors)

        return newLabel.utf8
    }

    static func verifyValidLabel(
        _ label: Substring.UTF8View,
        errors: inout MappingErrors
    ) {
        // Do nothing for now
    }
}
