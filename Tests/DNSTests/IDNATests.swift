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

    /// For debugging you can choose a specific test case based on its index. For example
    /// for index 188, use `@Test(arguments: IDNATestV2Case.enumeratedAllCases()[188...188])`.
    @Test(arguments: IDNATestV2Case.enumeratedAllCases())
    func runIDNATestV2SuiteAgainstToASCIIFunction(index: Int, arg: IDNATestV2Case) throws {
        var idna = IDNA(configuration: .strict)
        /// Because ToASCII will go through ToUnicode too
        var statuses = arg.toUnicodeStatus + arg.toAsciiNStatus
        try runTestCase(
            idna: &idna,
            function: IDNA.toASCII,
            source: arg.source,
            expected: arg.toAsciiN,
            remainingStatuses: &statuses
        )
    }

    /// For debugging you can choose a specific test case based on its index. For example
    /// for index 188, use `@Test(arguments: IDNATestV2Case.enumeratedAllCases()[188...188])`.
    @Test(arguments: IDNATestV2Case.enumeratedAllCases())
    func runIDNATestV2SuiteAgainstToUnicodeFunction(index: Int, arg: IDNATestV2Case) throws {
        var idna = IDNA(configuration: .strict)
        var statuses = arg.toUnicodeStatus
        try runTestCase(
            idna: &idna,
            function: IDNA.toUnicode,
            source: arg.source,
            expected: arg.toUnicode,
            remainingStatuses: &statuses
        )
    }

    /// Runs the certain IDNA function using the source string and the makes sure it produces the
    /// expected result according the the IDNA test V2 suite.
    ///
    /// How it works:
    /// 1. Runs the `function` using `source`.
    /// 2. If there are no errors thrown by `function`, then checks if the result is
    ///     equal to `expected`.
    /// 3. If there are errors thrown by `function`, then it disables one of the thrown errors
    ///    by setting the corresponding flag in `idna.configuration` to a value that would disable
    ///    that certain error. Then jumps back to step 1.
    ///
    /// This process continues until either the `function` succeeds or runs tries to make.
    func runTestCase(
        idna: inout IDNA,
        function: (IDNA) -> ((inout String) throws(IDNA.MappingErrors) -> Void),
        source: String,
        expected: String?,
        remainingStatuses: inout [IDNATestV2Case.Status],
        tryNumber: Int = 0
    ) throws {
        guard let expected = expected else {
            return
        }

        if tryNumber > 10 {
            Issue.record("Too many tries: \(tryNumber), idna.configuration: \(idna.configuration)")
            return
        }

        do {
            var source = source
            try function(idna)(&source)
            #expect(source == expected, "tries: \(tryNumber)")
        } catch let idnaError {
            /// If there are multiple errors, we need to disable one of them and try again.
            /// We try to do `ignoresInvalidPunycode = true` last, because it single-handedly
            /// disables a lot of errors.
            /// We also try to disable `P4` as late as possible because it'll disable checkHyphens
            /// too, other than enabling `ignoresInvalidPunycode`.
            guard
                let error = idnaError.errors
                    .sorted(by: { l, _ in !l.disablingWillRequireIgnoringInvalidPunycode })
                    .sorted(by: { l, _ in !(l.correspondingIDNAStatus == .P4) })
                    .first
            else {
                fatalError("No error element found in errors: \(idnaError)")
            }
            if let correspondingStatus = error.correspondingIDNAStatus {
                #expect(
                    remainingStatuses.containsRelatedStatusCode(to: correspondingStatus),
                    "current error: \(error), errors: \(idnaError.errors)"
                )
            }
            guard
                error.disable(
                    inConfiguration: &idna.configuration,
                    removingFrom: &remainingStatuses
                )
            else {
                Issue.record(
                    "Failed to disable error: \(error), idna.configuration: \(idna.configuration)"
                )
                return
            }
            try self.runTestCase(
                idna: &idna,
                function: function,
                source: source,
                expected: expected,
                remainingStatuses: &remainingStatuses,
                tryNumber: tryNumber + 1
            )
        }
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
