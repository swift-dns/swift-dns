import CSwiftDNSIDNATesting
import DNSModels

/// Represents a single test case from the IDNA Test V2 specification:
/// https://www.unicode.org/Public/idna/16.0.0/IdnaTestV2.txt
struct IDNATestV2Case {
    /// Each of these statuses refer to some part of the Unicode document at
    /// https://www.unicode.org/reports/tr46 .
    /// This enum is named "Status" by the IDNAtestV2, but it's more like an "ErrorKind" enum.
    ///
    /// From https://www.unicode.org/Public/idna/16.0.0/IdnaTestV2.txt:
    /// ```text
    ///   Pn for Section 4 Processing step n
    ///   Vn for 4.1 Validity Criteria step n
    ///   U1 for UseSTD3ASCIIRules
    ///   An for 4.2 ToASCII step n
    ///   Bn for Bidi (in IDNA2008)
    ///   Cn for ContextJ (in IDNA2008)
    ///   Xn for toUnicode issues (see below)
    ///
    ///   ...
    ///
    ///   Implementations that allow values of particular input flags to be false would ignore
    ///   the corresponding status codes listed in the table below when testing for errors.
    ///
    ///   VerifyDnsLength:   A4_1, A4_2
    ///   CheckHyphens:      V2, V3
    ///   CheckJoiners:      Cn
    ///   CheckBidi:         Bn
    ///   UseSTD3ASCIIRules: U1
    /// ```
    ///
    /// For example, V4 refers to https://www.unicode.org/reports/tr46/#Validity_Criteria
    /// point number 4: If not CheckHyphens, the label must not begin with “xn--”.
    enum Status: String {
        case A4_1, A4_2
        case B1, B2, B3, B4, B5, B6
        case C1, C2
        case V1, V2, V3, V4, V6, V7
        case U1
        case P4
        case X4_2
    }

    /// The source string to be tested
    let source: String
    /// The result of applying toUnicode to the source, with Transitional_Processing=false
    let toUnicode: String?
    /// A set of status codes for toUnicode operation
    let toUnicodeStatus: [Status]
    /// The result of applying toASCII to the source, with Transitional_Processing=false
    let toAsciiN: String?
    /// A set of status codes for toAsciiN operation
    let toAsciiNStatus: [Status]
    /// The result of applying toASCII to the source, with Transitional_Processing=true
    let toAsciiT: String?
    /// A set of status codes for toAsciiT operation
    let toAsciiTStatus: [Status]

    init(from cCase: IDNATestV2CCase) {
        self.source = String(cString: cCase.source)
        self.toUnicode = cCase.toUnicode.map(String.init(cString:))
        self.toAsciiN = cCase.toAsciiN.map(String.init(cString:))
        self.toAsciiT = cCase.toAsciiT.map(String.init(cString:))
        self.toUnicodeStatus = Array(
            UnsafeBufferPointer(
                start: cCase.toUnicodeStatus!,
                count: Int(cCase.toUnicodeStatusCount)
            )
        ).map {
            String(cString: $0!)
        }.map {
            Status(rawValue: $0)!
        }
        self.toAsciiNStatus = Array(
            UnsafeBufferPointer(
                start: cCase.toAsciiNStatus!,
                count: Int(cCase.toAsciiNStatusCount)
            )
        ).map {
            String(cString: $0!)
        }.map {
            Status(rawValue: $0)!
        }
        self.toAsciiTStatus = Array(
            UnsafeBufferPointer(
                start: cCase.toAsciiTStatus!,
                count: Int(cCase.toAsciiTStatusCount)
            )
        ).map {
            String(cString: $0!)
        }.map {
            Status(rawValue: $0)!
        }
    }

    static func allCases() -> [IDNATestV2Case] {
        var count: Int = 0
        guard let ptr = idna_test_v2_all_cases(&count) else {
            fatalError("Failed to get IDNA Test V2 cases")
        }
        return (0..<count).map { i in IDNATestV2Case(from: ptr[i]) }
    }

    /// This is better for debuggability.
    /// If a certain case is failing, we'll know what index it belongs to so we can
    /// try to investigate that case alone.
    static func enumeratedAllCases() -> [(index: Int, case: IDNATestV2Case)] {
        let allCases = Self.allCases()
        return allCases.enumerated().map { ($0, $1) }
    }
}

extension IDNATestV2Case: CustomStringConvertible {
    var description: String {
        "IDNATestV2Case(source: \(source.debugDescription), toUnicode: \(toUnicode?.debugDescription ?? "nil"), toUnicodeStatus: \(toUnicodeStatus.debugDescription), toAsciiN: \(toAsciiN?.debugDescription ?? "nil"), toAsciiNStatus: \(toAsciiNStatus.debugDescription), toAsciiT: \(toAsciiT?.debugDescription ?? "nil"), toAsciiTStatus: \(toAsciiTStatus.debugDescription))"
    }
}

extension IDNATestV2Case.Status: CustomStringConvertible {
    var description: String {
        ".\(self.rawValue)"
    }
}

extension IDNA.MappingErrors.Element {
    var correspondingIDNAStatus: IDNATestV2Case.Status? {
        switch self {
        case .labelStartsWithXNHyphenMinusHyphenMinusButContainsNonASCII:
            return .P4
        case .labelPunycodeEncodeFailed:
            return nil
        case .labelPunycodeDecodeFailed:
            return .X4_2
        case .labelIsEmptyAfterPunycodeConversion:
            return .P4
        case .labelContainsOnlyASCIIAfterPunycodeDecode:
            return .P4
        case .trueVerifyDNSLengthArgumentRequiresLabelToBe63BytesOrLess:
            return .A4_2
        case .trueVerifyDNSLengthArgumentDisallowsEmptyLabel:
            return .A4_2
        case .trueVerifyDNSLengthArgumentDisallowsEmptyRootLabelWithTrailingDot:
            return .A4_2
        case .trueVerifyDNSLengthArgumentRequiresDomainNameToBe254BytesOrLess:
            return .A4_1
        case .trueVerifyDNSLengthArgumentDisallowsEmptyDomainName:
            return .A4_1
        case .labelIsNotInNormalizationFormC:
            return .V1
        case .trueCheckHyphensArgumentRequiresLabelToNotContainHyphenMinusAtPostion3and4:
            return .V2
        case .trueCheckHyphensArgumentRequiresLabelToNotStartOrEndWithHyphenMinus:
            return .V3
        case .falseCheckHyphensArgumentRequiresLabelToNotStartWithXNHyphenMinusHyphenMinus:
            return .V4
        case .labelStartsWithCombiningMark:
            return .V6
        case .labelContainsInvalidUnicode:
            return .V7
        case .trueUseSTD3ASCIIRulesArgumentRequiresLabelToOnlyContainCertainASCIICharacters:
            return .U1
        }
    }

    var disablingWillRequireIgnoringInvalidPunycode: Bool {
        switch self.correspondingIDNAStatus {
        case .none:
            return false
        case .some(let status):
            switch status {
            case .P4, .V1, .V4, .V6, .V7, .X4_2:
                return true
            case .A4_1, .A4_2, .B1, .B2, .B3, .B4, .B5, .B6, .C1, .C2, .V2, .V3, .U1:
                return false
            }
        }
    }

    /// Returns true if the error can be disabled, false otherwise.
    func disable(
        inConfiguration configuration: inout IDNA.Configuration,
        removingFrom statuses: inout [IDNATestV2Case.Status]
    ) -> Bool {
        guard let correspondingStatus = self.correspondingIDNAStatus else {
            return false
        }

        switch correspondingStatus {
        case .A4_1:
            configuration.verifyDnsLength = false
        case .A4_2:
            configuration.verifyDnsLength = false
        case .B1, .B2, .B3, .B4, .B5, .B6:
            configuration.checkBidi = false
        case .C1, .C2:
            configuration.checkJoiners = false
        case .P4:
            configuration.ignoreInvalidPunycode = true
            configuration.checkHyphens = false
        case .V1:
            configuration.ignoreInvalidPunycode = true
        case .V2:
            configuration.checkHyphens = false
        case .V3:
            configuration.checkHyphens = false
        case .V4:
            configuration.ignoreInvalidPunycode = true
        case .V6:
            configuration.ignoreInvalidPunycode = true
        case .V7:
            configuration.ignoreInvalidPunycode = true
        case .U1:
            configuration.useSTD3ASCIIRules = false
        case .X4_2:
            configuration.ignoreInvalidPunycode = true
        }

        statuses = statuses.filter { !$0.isRelated(to: correspondingStatus) }

        return true
    }
}

extension IDNATestV2Case.Status {
    func isRelated(to other: Self) -> Bool {
        self == other
            || (self == .P4 && other.isCheckHyphensStatus)
            || (other == .P4 && self.isCheckHyphensStatus)
    }
}

extension [IDNATestV2Case.Status] {
    func containsRelatedStatusCode(to statusCode: IDNATestV2Case.Status) -> Bool {
        self.contains { $0.isRelated(to: statusCode) }
    }
}

extension IDNATestV2Case.Status {
    var isCheckHyphensStatus: Bool {
        switch self {
        case .V1, .V2, .V3, .V4, .V6, .V7:
            return true
        default:
            return false
        }
    }
}
