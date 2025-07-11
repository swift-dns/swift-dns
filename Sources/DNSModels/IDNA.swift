package enum IDNA {
    package struct MappingErrors: Error {
        package enum Element: CustomStringConvertible {
            case domainNameContainsDisallowedCharacter(UnicodeScalar)
            case labelStartsWithXNDashDashButContainsNonASCII(UnicodeScalar)
            case labelPunycodeEncodeFailed(label: Substring.UnicodeScalarView)
            case labelPunycodeDecodeFailed(label: Substring.UnicodeScalarView)
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
                    return ".labelPunycodeEncodeFailed(\(String(label).debugDescription))"
                case .labelPunycodeDecodeFailed(let label):
                    return ".labelPunycodeDecodeFailed(\(String(label).debugDescription))"
                case .labelIsEmptyAfterPunycodeConversion(let label):
                    return
                        ".labelIsEmptyAfterPunycodeConversion(\(String(label).debugDescription))"
                case .labelContainsOnlyASCIIAfterPunycodeConversion(let label):
                    return
                        ".labelContainsOnlyASCIIAfterPunycodeConversion(\(String(label).debugDescription))"
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

    /// https://www.unicode.org/reports/tr46/#ToASCII
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
        let labels = domainName.unicodeScalars.split(
            separator: UnicodeScalar.asciiDot
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
                let labelLength = label.unicodeScalars.count
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

    /// https://www.unicode.org/reports/tr46/#ToUnicode
    package static func toUnicode(
        domainName: inout String,
        checkHyphens: Bool,
        checkBidi: Bool,
        checkJoiners: Bool,
        useSTD3ASCIIRules: Bool,
        ignoreInvalidPunycode: Bool
    ) throws(MappingErrors) {
        var errors = MappingErrors(domainName: domainName)

        // 1.
        mainProcessing(
            domainName: &domainName,
            useSTD3ASCIIRules: useSTD3ASCIIRules,
            checkHyphens: checkHyphens,
            checkBidi: checkBidi,
            checkJoiners: checkJoiners,
            ignoreInvalidPunycode: ignoreInvalidPunycode,
            errors: &errors
        )

        // 2.
        if !errors.isEmpty {
            throw errors
        }
    }

    /// https://www.unicode.org/reports/tr46/#Processing
    static func mainProcessing(
        domainName: inout String,
        useSTD3ASCIIRules: Bool,
        checkHyphens: Bool,
        checkBidi: Bool,
        checkJoiners: Bool,
        ignoreInvalidPunycode: Bool,
        errors: inout MappingErrors
    ) {
        var newUnicodeScalars: [UnicodeScalar] = []
        /// TODO: optimize reserve capacity
        newUnicodeScalars.reserveCapacity(domainName.unicodeScalars.count * 12 / 10)

        /// 1. Map
        for scalar in domainName.unicodeScalars {
            switch IDNAMapping.for(scalar: scalar) {
            case .valid(_):
                newUnicodeScalars.append(scalar)
            case .mapped(let mappedScalars):
                newUnicodeScalars.append(contentsOf: mappedScalars)
            case .deviation(_):
                newUnicodeScalars.append(scalar)
            case .disallowed:
                newUnicodeScalars.append(scalar)
            case .ignored:
                break
            }
        }

        /// 2. Normalize
        domainName = String(String.UnicodeScalarView(newUnicodeScalars))
        domainName = domainName.asNFC

        /// 3. Break, 4. Convert/Validate.
        domainName = domainName.unicodeScalars.split(
            separator: UnicodeScalar.asciiDot
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
        _ label: Substring.UnicodeScalarView,
        ignoreInvalidPunycode: Bool,
        errors: inout MappingErrors
    ) -> Substring.UnicodeScalarView {
        var newLabel = Substring(label)

        /// Checks if the label starts with “xn--”
        if label.count > 3,
            label[label.startIndex] == UnicodeScalar.asciiLowercasedX,
            label[label.index(label.startIndex, offsetBy: 1)] == UnicodeScalar.asciiLowercasedN,
            label[label.index(label.startIndex, offsetBy: 2)] == UnicodeScalar.asciiDash,
            label[label.index(label.startIndex, offsetBy: 3)] == UnicodeScalar.asciiDash
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

        verifyValidLabel(&newLabel, errors: &errors)

        return newLabel.unicodeScalars
    }

    static func verifyValidLabel(
        _ label: inout Substring,
        errors: inout MappingErrors
    ) {
        // Do nothing for now
    }
}
