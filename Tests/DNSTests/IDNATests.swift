import DNSCore
import DNSModels
import Testing

@Suite
struct IDNATests {
    /// For debugging you can choose a specific test case based on its index. For example
    /// for index 5101, use `@Test(arguments: IDNATestV2Case.enumeratedAllCases()[5101...5101])`.
    @Test(arguments: IDNATestV2Case.enumeratedAllCases())
    func runIDNATestV2SuiteAgainstToASCIIFunction(index: Int, arg: IDNATestV2Case) throws {
        var idna = IDNA(configuration: .mostStrict)
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
    /// for index 5101, use `@Test(arguments: IDNATestV2Case.enumeratedAllCases()[5101...5101])`.
    @Test(arguments: IDNATestV2Case.enumeratedAllCases())
    func runIDNATestV2SuiteAgainstToUnicodeFunction(index: Int, arg: IDNATestV2Case) throws {
        var idna = IDNA(configuration: .mostStrict)
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
    /// 1. If `expected` is `nil`, then it runs the `function` using `source` and makes sure the
    ///    conversion is not successful or it simply results in the same `source` string.
    /// 2. If `expected` is not `nil`, runs the `function` using `source`. Then:
    /// 3. If there are no errors thrown by `function`, then checks if the result is
    ///     equal to `expected`.
    /// 4. If there are errors thrown by `function`, then it disables one of the thrown errors
    ///    by setting the corresponding flag in `idna.configuration` to a value that would disable
    ///    that certain error. Then jumps back to step 1.
    ///
    /// This process continues until either the `function` succeeds or runs out of tries to make.
    func runTestCase(
        idna: inout IDNA,
        function: (IDNA) -> ((inout String) throws(IDNA.MappingErrors) -> Void),
        source: String,
        expected: String?,
        remainingStatuses: inout [IDNATestV2Case.Status],
        tryNumber: Int = 0
    ) throws {
        if tryNumber > 10 {
            Issue.record("Too many tries: \(tryNumber), idna.configuration: \(idna.configuration)")
            return
        }

        guard let expected = expected else {
            var convertedSource = source
            do {
                try function(idna)(&convertedSource)
                if convertedSource != source,
                    convertedSource.uppercased() != source.uppercased()
                {
                    Issue.record(
                        "Didn't expect a converted value for source: \(source.debugDescription) in the first try, but got: \(convertedSource.debugDescription)"
                    )
                }
            } catch {
                /// good
            }
            return
        }

        do {
            var convertedSource = source
            try function(idna)(&convertedSource)
            #expect(convertedSource == expected, "tries: \(tryNumber)")
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
