import DNSCore
import DNSModels
import Testing

@Suite
struct IDNATests {
    @Test(arguments: LookupWorksArg.all)
    func lookupWorks(arg: LookupWorksArg) {
        let mapping = IDNAMapping.for(scalar: arg.scalar)
        #expect(mapping == arg.expected)
    }

    @Test(
        arguments: IDNATestV2Case.allCases().filter {
            $0.toAsciiNStatus.isEmpty
        }
    )
    func idnaTestSuite(arg: IDNATestV2Case) throws {
        var toAsciiN = arg.source
        try IDNA.toASCII(
            domainName: &toAsciiN,
            checkHyphens: false,
            checkBidi: false,
            checkJoiners: false,
            useSTD3ASCIIRules: false,
            verifyDnsLength: false,
            ignoreInvalidPunycode: false
        )
        #expect(toAsciiN == arg.toAsciiN, "\(arg)")

        var toUnicode = arg.source
        try IDNA.toUnicode(
            domainName: &toUnicode,
            checkHyphens: false,
            checkBidi: false,
            checkJoiners: false,
            useSTD3ASCIIRules: false,
            ignoreInvalidPunycode: false
        )
        #expect(toUnicode == arg.toUnicode, "\(arg)")
    }
}

struct LookupWorksArg {

    typealias U = UnicodeScalar

    let scalar: UnicodeScalar
    let expected: IDNAMapping

    init(_ scalar: UnicodeScalar, _ expected: IDNAMapping) {
        self.scalar = scalar
        self.expected = expected
    }

    /// Some hand-chosen ones from https://www.unicode.org/Public/idna/16.0.0/IdnaMappingTable.txt
    static var all: [LookupWorksArg] {
        [
            LookupWorksArg(U(0x002F)!, .valid(.NV8)),
            LookupWorksArg(U(0x005A)!, .mapped([U(0x007A)!])),
            LookupWorksArg(U(0x0385)!, .mapped([U(0x0020)!, U(0x0308)!, U(0x0301)!])),
            LookupWorksArg(U(0x034F)!, .ignored),
            LookupWorksArg(U(0x00DF)!, .deviation([U(0x0073)!, U(0x0073)!])),
            LookupWorksArg(U(0x04DE)!, .mapped([U(0x04DF)!])),
            LookupWorksArg(U(0x0B02)!, .valid(.none)),
            LookupWorksArg(U(0x19DA)!, .valid(.XV8)),
            LookupWorksArg(U(0x1B4D)!, .disallowed),
            LookupWorksArg(U(0x200D)!, .deviation([])),
        ]
    }
}
