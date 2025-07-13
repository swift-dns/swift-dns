/// Provides compatibility with IDNA: Internationalized Domain Names in Applications.
/// [Unicode IDNA Compatibility Processing](https://www.unicode.org/reports/tr46/)
public struct IDNA {
    /// [Unicode IDNA Compatibility Processing: Processing](https://www.unicode.org/reports/tr46/#Processing)
    /// All parameters are used in both `toASCII` and `toUnicode`, except for
    /// `verifyDNSLength` which is only used in `toASCII`.
    public struct Configuration {
        /// Disallows usage of "-" (U+002D HYPHEN-MINUS) in certain positions of a domain name.
        /// [Unicode IDNA Compatibility Processing: Validity Criteria](https://www.unicode.org/reports/tr46/#Validity_Criteria)
        public var checkHyphens: Bool
        /// Checks if a domain name is valid if/when containing any bidirectional unicode characters.
        /// [Unicode IDNA Compatibility Processing: Validity Criteria](https://www.unicode.org/reports/tr46/#Validity_Criteria)
        /// `checkBidi` is currently a no-op.
        package var checkBidi: Bool = true
        /// Checks if a domain name is valid if/when containing any joiner unicode characters.
        /// [Unicode IDNA Compatibility Processing: Validity Criteria](https://www.unicode.org/reports/tr46/#Validity_Criteria)
        /// `checkJoiners` is currently a no-op.
        package var checkJoiners: Bool = true
        /// [Unicode IDNA Compatibility Processing: Validity Criteria](https://www.unicode.org/reports/tr46/#Validity_Criteria)
        public var useSTD3ASCIIRules: Bool
        /// Verifies domain name length compatibility with DNS specification.
        /// That is, each label length must be in range 1...63 and each full domain name length must
        /// be in range 1...255.
        /// [Unicode IDNA Compatibility Processing: ToASCII](https://www.unicode.org/reports/tr46/#ToASCII)
        public var verifyDNSLength: Bool
        /// Ignores invalid punycode in `toUnicode`/`mainProcessing` conversions and more, and
        /// doesn't report errors for them.
        public var ignoreInvalidPunycode: Bool

        /// The most strict configuration possible.
        public static var mostStrict: Configuration {
            Configuration(
                checkHyphens: true,
                checkBidi: true,
                checkJoiners: true,
                useSTD3ASCIIRules: true,
                verifyDNSLength: true,
                ignoreInvalidPunycode: false
            )
        }

        /// The most lax configuration possible.
        public static var mostLax: Configuration {
            Configuration(
                checkHyphens: false,
                checkBidi: false,
                checkJoiners: false,
                useSTD3ASCIIRules: false,
                verifyDNSLength: false,
                ignoreInvalidPunycode: true
            )
        }

        /// The default configuration.
        public static var `default`: Configuration {
            Configuration(
                checkHyphens: true,
                checkBidi: true,
                checkJoiners: true,
                useSTD3ASCIIRules: false,
                verifyDNSLength: true,
                ignoreInvalidPunycode: false
            )
        }

        package init(
            checkHyphens: Bool,
            checkBidi: Bool,
            checkJoiners: Bool,
            useSTD3ASCIIRules: Bool,
            verifyDNSLength: Bool,
            ignoreInvalidPunycode: Bool
        ) {
            self.checkHyphens = checkHyphens
            self.checkBidi = checkBidi
            self.checkJoiners = checkJoiners
            self.useSTD3ASCIIRules = useSTD3ASCIIRules
            self.verifyDNSLength = verifyDNSLength
            self.ignoreInvalidPunycode = ignoreInvalidPunycode
        }

        /// - Parameters:
        ///   - checkHyphens: Disallows usage of "-" (U+002D HYPHEN-MINUS) in certain positions of a domain name.
        ///     [Unicode IDNA Compatibility Processing: Validity Criteria](https://www.unicode.org/reports/tr46/#Validity_Criteria)
        ///   - useSTD3ASCIIRules: [Unicode IDNA Compatibility Processing: Validity Criteria](https://www.unicode.org/reports/tr46/#Validity_Criteria)
        ///   - verifyDNSLength: Verifies domain name length compatibility with DNS specification.
        ///     That is, each label length must be in range 1...63 and each full domain name length must
        ///     be in range 1...255.
        ///     [Unicode IDNA Compatibility Processing: ToASCII](https://www.unicode.org/reports/tr46/#ToASCII)
        ///   - ignoreInvalidPunycode: Ignores invalid punycode in `toUnicode`/`mainProcessing` conversions and more,
        ///     and doesn't report errors for them.
        public init(
            checkHyphens: Bool,
            useSTD3ASCIIRules: Bool,
            verifyDNSLength: Bool,
            ignoreInvalidPunycode: Bool
        ) {
            self.checkHyphens = checkHyphens
            /// `checkBidi` is currently a no-op.
            self.checkBidi = false
            /// `checkJoiners` is currently a no-op.
            self.checkJoiners = false
            self.useSTD3ASCIIRules = useSTD3ASCIIRules
            self.verifyDNSLength = verifyDNSLength
            self.ignoreInvalidPunycode = ignoreInvalidPunycode
        }
    }

    package var configuration: Configuration

    @usableFromInline
    package init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// `ToASCII` IDNA implementation.
    /// https://www.unicode.org/reports/tr46/#ToASCII
    @usableFromInline
    package func toASCII(domainName: inout String) throws(MappingErrors) {
        switch performASCIICheck(domainName: &domainName) {
        case .containsOnlyIDNANoOpASCII:
            return
        case .isASCIIButContainsUppercasedLetters:
            convertToLowercasedASCII(domainName: &domainName)
            return
        case .containsNonASCII:
            break
        }

        var errors = MappingErrors(domainName: domainName)

        // 1.
        self.mainProcessing(domainName: &domainName, errors: &errors)

        // 2., 3.
        var labels = domainName.unicodeScalars.split(
            separator: Unicode.Scalar.asciiDot,
            omittingEmptySubsequences: false
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

        if configuration.verifyDNSLength {
            if labels.last?.isEmpty == true {
                errors.append(
                    .trueVerifyDNSLengthArgumentDisallowsEmptyRootLabelWithTrailingDot(
                        labels: labels
                    )
                )
                labels.removeLast()
            }

            var totalByteLength = 0
            for label in labels {
                /// All scalars are already ASCII so each scalar is 1 byte
                /// So each scalar will only count 1 towards the DNS Domain Name byte limit
                let labelByteLength = label.unicodeScalars.count
                totalByteLength += labelByteLength
                if labelByteLength > 63 {
                    errors.append(
                        .trueVerifyDNSLengthArgumentRequiresLabelToBe63BytesOrLess(
                            length: labelByteLength,
                            label: label
                        )
                    )
                }
                if labelByteLength == 0 {
                    errors.append(
                        .trueVerifyDNSLengthArgumentDisallowsEmptyLabel(label: label)
                    )
                }
            }

            let dnsLength = totalByteLength + labels.count
            if dnsLength > 254 {
                errors.append(
                    .trueVerifyDNSLengthArgumentRequiresDomainNameToBe254BytesOrLess(
                        length: dnsLength,
                        labels: labels
                    )
                )
            }
            if totalByteLength == 0 {
                errors.append(
                    .trueVerifyDNSLengthArgumentDisallowsEmptyDomainName(labels: labels)
                )
            }
        }

        if !errors.isEmpty {
            throw errors
        }

        domainName = labels.joined(separator: ".")
    }

    /// `ToUnicode` IDNA implementation.
    /// https://www.unicode.org/reports/tr46/#ToUnicode
    @usableFromInline
    package func toUnicode(domainName: inout String) throws(MappingErrors) {
        switch performASCIICheck(domainName: &domainName) {
        case .containsOnlyIDNANoOpASCII:
            return
        case .isASCIIButContainsUppercasedLetters:
            convertToLowercasedASCII(domainName: &domainName)
            return
        case .containsNonASCII:
            break
        }

        var errors = MappingErrors(domainName: domainName)

        // 1.
        self.mainProcessing(domainName: &domainName, errors: &errors)

        // 2.
        if !errors.isEmpty {
            throw errors
        }
    }

    /// Main `Processing` IDNA implementation.
    /// https://www.unicode.org/reports/tr46/#Processing
    @usableFromInline
    func mainProcessing(domainName: inout String, errors: inout MappingErrors) {
        var newUnicodeScalars: [Unicode.Scalar] = []
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
            separator: Unicode.Scalar.asciiDot,
            omittingEmptySubsequences: false
        ).map { label in
            Substring(convertAndValidateLabel(label, errors: &errors))
        }.joined(separator: ".")
    }

    /// https://www.unicode.org/reports/tr46/#ProcessingStepConvertValidate
    @usableFromInline
    func convertAndValidateLabel(
        _ label: Substring.UnicodeScalarView,
        errors: inout MappingErrors
    ) -> Substring.UnicodeScalarView {
        var newLabel = Substring(label)

        /// Checks if the label starts with “xn--”
        if label.count > 3,
            label[label.startIndex] == Unicode.Scalar.asciiLowercasedX,
            label[label.index(label.startIndex, offsetBy: 1)] == Unicode.Scalar.asciiLowercasedN,
            label[label.index(label.startIndex, offsetBy: 2)] == Unicode.Scalar.asciiHyphenMinus,
            label[label.index(label.startIndex, offsetBy: 3)] == Unicode.Scalar.asciiHyphenMinus
        {
            /// 4.1:
            if !configuration.ignoreInvalidPunycode,
                label.contains(where: { !$0.isASCII })
            {
                errors.append(
                    .labelStartsWithXNHyphenMinusHyphenMinusButContainsNonASCII(label: label)
                )
                return label/// continue to next label
            }

            /// 4.2:
            /// If conversion fails, and we're not ignoring invalid punycode, record an error

            /// Drop the "xn--" prefix
            newLabel = Substring(newLabel.unicodeScalars.dropFirst(4))

            let conversionResult = Punycode.decode(&newLabel)
            switch conversionResult {
            case true:
                break
            case false:
                switch configuration.ignoreInvalidPunycode {
                case true:
                    newLabel = Substring(label)
                case false:
                    errors.append(.labelPunycodeDecodeFailed(label: label))
                    /// continue to next label
                    return label
                }
            }

            /// 4.3:
            if !configuration.ignoreInvalidPunycode {
                if newLabel.isEmpty {
                    errors.append(.labelIsEmptyAfterPunycodeConversion(label: newLabel))
                }

                if newLabel.allSatisfy(\.isASCII) {
                    errors.append(.labelContainsOnlyASCIIAfterPunycodeDecode(label: newLabel))
                }
            }
        }

        verifyValidLabel(newLabel.unicodeScalars, errors: &errors)

        return newLabel.unicodeScalars
    }

    /// https://www.unicode.org/reports/tr46/#Validity_Criteria
    @usableFromInline
    func verifyValidLabel(_ label: Substring.UnicodeScalarView, errors: inout MappingErrors) {
        if !configuration.ignoreInvalidPunycode,
            !String(label).isInNFC
        {
            errors.append(.labelIsNotInNormalizationFormC(label: label))
        }

        switch configuration.checkHyphens {
        case true:
            if label.count > 3,
                label[label.index(label.startIndex, offsetBy: 2)]
                    == Unicode.Scalar.asciiHyphenMinus,
                label[label.index(label.startIndex, offsetBy: 3)] == Unicode.Scalar.asciiHyphenMinus
            {
                errors.append(
                    .trueCheckHyphensArgumentRequiresLabelToNotContainHyphenMinusAtPostion3and4(
                        label: label
                    )
                )
            }
            if label.first == Unicode.Scalar.asciiHyphenMinus
                || label.last == Unicode.Scalar.asciiHyphenMinus
            {
                errors.append(
                    .trueCheckHyphensArgumentRequiresLabelToNotStartOrEndWithHyphenMinus(
                        label: label
                    )
                )
            }
        case false:
            if !configuration.ignoreInvalidPunycode,
                label.count > 3,
                label[label.startIndex] == Unicode.Scalar.asciiLowercasedX,
                label[label.index(label.startIndex, offsetBy: 1)]
                    == Unicode.Scalar.asciiLowercasedN,
                label[label.index(label.startIndex, offsetBy: 2)]
                    == Unicode.Scalar.asciiHyphenMinus,
                label[label.index(label.startIndex, offsetBy: 3)] == Unicode.Scalar.asciiHyphenMinus
            {
                errors.append(
                    .falseCheckHyphensArgumentRequiresLabelToNotStartWithXNHyphenMinusHyphenMinus(
                        label: label
                    )
                )
            }
        }

        if !configuration.ignoreInvalidPunycode,
            label.first?.properties.generalCategory.isMark == true
        {
            errors.append(.labelStartsWithCombiningMark(label: label))
        }

        if !configuration.ignoreInvalidPunycode {
            for codePoint in label {
                switch IDNAMapping.for(scalar: codePoint) {
                case .valid, .deviation:
                    break
                case .mapped, .disallowed, .ignored:
                    errors.append(
                        .labelContainsInvalidUnicode(codePoint, label: label)
                    )
                }
            }
        }

        if configuration.useSTD3ASCIIRules {
            for codePoint in label where codePoint.isASCII {
                if !codePoint.isNumberOrLowercasedLetterOrHyphenMinusASCII {
                    errors.append(
                        .trueUseSTD3ASCIIRulesArgumentRequiresLabelToOnlyContainCertainASCIICharacters(
                            label: label
                        )
                    )
                }
            }
        }

        // if configuration.checkJoiners {
        // TODO: implement
        // }

        // if configuration.checkBidi {
        // TODO: implement
        // }
    }

    enum ASCIICheckResult {
        case containsOnlyIDNANoOpASCII
        case isASCIIButContainsUppercasedLetters
        case containsNonASCII
    }

    func performASCIICheck(domainName: inout String) -> ASCIICheckResult {
        var containsUppercased = false

        for unicodeScalar in domainName.unicodeScalars {
            if unicodeScalar.isNumberOrLowercasedLetterOrDotASCII {
                continue
            } else if unicodeScalar.isUppercasedASCII {
                containsUppercased = true
            } else {
                return .containsNonASCII
            }
        }

        return containsUppercased
            ? .isASCIIButContainsUppercasedLetters : .containsOnlyIDNANoOpASCII
    }

    @usableFromInline
    func convertToLowercasedASCII(domainName: inout String) {
        domainName = String(
            String.UnicodeScalarView(
                domainName.unicodeScalars.map {
                    /// https://ss64.com/ascii.html
                    /// The difference between an upper and lower cased ASCII byte is their sixth bit.
                    /// Turn the sixth bit on to ensure lowercased ASCII byte.
                    Unicode.Scalar($0.value.uncheckedASCIIToLowercase())!
                }
            )
        )
    }
}

extension IDNA {
    @usableFromInline
    package struct MappingErrors: Error {
        package enum Element: CustomStringConvertible {
            case labelStartsWithXNHyphenMinusHyphenMinusButContainsNonASCII(
                label: Substring.UnicodeScalarView
            )
            case labelPunycodeEncodeFailed(label: Substring.UnicodeScalarView)
            case labelPunycodeDecodeFailed(label: Substring.UnicodeScalarView)
            case labelIsEmptyAfterPunycodeConversion(label: Substring)
            case labelContainsOnlyASCIIAfterPunycodeDecode(label: Substring)
            case trueVerifyDNSLengthArgumentRequiresLabelToBe63BytesOrLess(
                length: Int,
                label: Substring
            )
            case trueVerifyDNSLengthArgumentDisallowsEmptyLabel(label: Substring)
            case trueVerifyDNSLengthArgumentDisallowsEmptyRootLabelWithTrailingDot(
                labels: [Substring]
            )
            case trueVerifyDNSLengthArgumentRequiresDomainNameToBe254BytesOrLess(
                length: Int,
                labels: [Substring]
            )
            case trueVerifyDNSLengthArgumentDisallowsEmptyDomainName(labels: [Substring])
            case labelIsNotInNormalizationFormC(label: Substring.UnicodeScalarView)
            case trueCheckHyphensArgumentRequiresLabelToNotContainHyphenMinusAtPostion3and4(
                label: Substring.UnicodeScalarView
            )
            case trueCheckHyphensArgumentRequiresLabelToNotStartOrEndWithHyphenMinus(
                label: Substring.UnicodeScalarView
            )
            case falseCheckHyphensArgumentRequiresLabelToNotStartWithXNHyphenMinusHyphenMinus(
                label: Substring.UnicodeScalarView
            )
            case labelStartsWithCombiningMark(label: Substring.UnicodeScalarView)
            case labelContainsInvalidUnicode(Unicode.Scalar, label: Substring.UnicodeScalarView)
            case trueUseSTD3ASCIIRulesArgumentRequiresLabelToOnlyContainCertainASCIICharacters(
                label: Substring.UnicodeScalarView
            )

            package var description: String {
                switch self {
                case .labelStartsWithXNHyphenMinusHyphenMinusButContainsNonASCII(let label):
                    return
                        ".labelStartsWithXNHyphenMinusHyphenMinusButContainsNonASCII(\(String(label).debugDescription))"
                case .labelPunycodeEncodeFailed(let label):
                    return ".labelPunycodeEncodeFailed(\(String(label).debugDescription))"
                case .labelPunycodeDecodeFailed(let label):
                    return ".labelPunycodeDecodeFailed(\(String(label).debugDescription))"
                case .labelIsEmptyAfterPunycodeConversion(let label):
                    return
                        ".labelIsEmptyAfterPunycodeConversion(\(String(label).debugDescription))"
                case .labelContainsOnlyASCIIAfterPunycodeDecode(let label):
                    return
                        ".labelContainsOnlyASCIIAfterPunycodeDecode(\(String(label).debugDescription))"
                case .trueVerifyDNSLengthArgumentRequiresLabelToBe63BytesOrLess(
                    let length,
                    let label
                ):
                    return
                        ".trueVerifyDNSLengthArgumentRequiresLabelToBe63BytesOrLess(length: \(length), label: \(String(label).debugDescription))"
                case .trueVerifyDNSLengthArgumentDisallowsEmptyLabel(let label):
                    return
                        ".trueVerifyDNSLengthArgumentDisallowsEmptyLabel(\(String(label).debugDescription))"
                case .trueVerifyDNSLengthArgumentDisallowsEmptyRootLabelWithTrailingDot(let labels):
                    return
                        ".trueVerifyDNSLengthArgumentDisallowsEmptyRootLabelWithTrailingDot(labels: \(labels.map(String.init)))"
                case .trueVerifyDNSLengthArgumentRequiresDomainNameToBe254BytesOrLess(
                    let length,
                    let labels
                ):
                    return
                        ".trueVerifyDNSLengthArgumentRequiresDomainNameToBe254BytesOrLess(length: \(length), labels: \(labels.map(String.init)))"
                case .trueVerifyDNSLengthArgumentDisallowsEmptyDomainName(let labels):
                    return
                        ".trueVerifyDNSLengthArgumentDisallowsEmptyDomainName(\(labels.map(String.init)))"
                case .labelIsNotInNormalizationFormC(let label):
                    return ".labelIsNotInNormalizationFormC(\(String(label).debugDescription))"
                case .trueCheckHyphensArgumentRequiresLabelToNotContainHyphenMinusAtPostion3and4(
                    let label
                ):
                    return
                        ".trueCheckHyphensArgumentRequiresLabelToNotContainHyphenMinusAtPostion3and4(\(String(label).debugDescription))"
                case .trueCheckHyphensArgumentRequiresLabelToNotStartOrEndWithHyphenMinus(let label):
                    return
                        ".trueCheckHyphensArgumentRequiresLabelToNotStartOrEndWithHyphenMinus(\(String(label).debugDescription))"
                case .falseCheckHyphensArgumentRequiresLabelToNotStartWithXNHyphenMinusHyphenMinus(
                    let label
                ):
                    return
                        ".falseCheckHyphensArgumentRequiresLabelToNotStartWithXNHyphenMinusHyphenMinus(\(String(label).debugDescription))"
                case .labelStartsWithCombiningMark(let label):
                    return ".labelStartsWithCombiningMark(\(String(label).debugDescription))"
                case .labelContainsInvalidUnicode(let codePoint, let label):
                    return
                        ".labelContainsInvalidUnicode(\(codePoint.debugDescription), label: \(String(label).debugDescription))"
                case .trueUseSTD3ASCIIRulesArgumentRequiresLabelToOnlyContainCertainASCIICharacters(
                    let label
                ):
                    return
                        ".trueUseSTD3ASCIIRulesArgumentRequiresLabelToOnlyContainCertainASCIICharacters(\(String(label).debugDescription))"
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
}
