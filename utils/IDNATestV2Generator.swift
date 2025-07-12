#!/usr/bin/env swift

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let testV2URL = "https://www.unicode.org/Public/idna/16.0.0/IdnaTestV2.txt"
let outputPath = "Sources/CSwiftDNSIDNATesting/src/idna_test_v2_cases.c"

struct IDNATestV2CCase {
    let source: String
    let toUnicode: String?
    let toUnicodeStatus: [String]
    let toAsciiN: String?
    let toAsciiNStatus: [String]
    let toAsciiT: String?
    let toAsciiTStatus: [String]
}

func parseStatusString(_ statusStr: String) -> [String] {
    let trimmed = statusStr.trimmingWhitespaces()
    if trimmed.isEmpty || trimmed == "[]" {
        return []
    }
    let content = String(trimmed.trimmingPrefix("[").dropLast())
    return content.split(separator: ",").map { $0.trimmingWhitespaces() }
}

func generate() -> String {
    let currentDirectory = FileManager.default.currentDirectoryPath
    guard currentDirectory.hasSuffix("swift-dns") else {
        fatalError(
            "This script must be run from the swift-dns root directory. Current directory: \(currentDirectory)."
        )
    }

    print("Downloading \(testV2URL) ...")
    let file = try! Data(contentsOf: URL(string: testV2URL)!)
    print("Downloaded \(file.count) bytes.")

    let utf8String = String(decoding: file, as: UTF8.self)

    var testCases: [IDNATestV2CCase] = []
    for var line in utf8String.split(separator: "\n", omittingEmptySubsequences: false) {
        line = Substring(line.trimmingWhitespaces())
        if line.hasPrefix("#") { continue }
        if line.isEmpty { continue }
        if let commentIndex = line.lastIndex(of: "#") {
            line = Substring(String(line[..<commentIndex]).trimmingWhitespaces())
        }
        let parts = line.unicodeScalars.split(
            separator: ";",
            omittingEmptySubsequences: false
        ).map {
            String($0).trimmingWhitespaces()
        }
        guard parts.count == 7 else {
            fatalError("Invalid parts count: \(parts.debugDescription)")
        }
        let source = parts[0]
        let toUnicode = parts[1].emptyIfIsOnlyQuotesAndNilIfEmpty()
        let toUnicodeStatus = parseStatusString(parts[2])
        let toAsciiN = parts[3].emptyIfIsOnlyQuotesAndNilIfEmpty()
        let toAsciiNStatus = parseStatusString(parts[4])
        let toAsciiT = parts[5].emptyIfIsOnlyQuotesAndNilIfEmpty()
        let toAsciiTStatus = parseStatusString(parts[6])
        let testCase = IDNATestV2CCase(
            source: source,
            toUnicode: toUnicode,
            toUnicodeStatus: toUnicodeStatus,
            toAsciiN: toAsciiN,
            toAsciiNStatus: toAsciiNStatus,
            toAsciiT: toAsciiT,
            toAsciiTStatus: toAsciiTStatus
        )
        testCases.append(testCase)
    }

    // Filter out test cases that contain \uD900 or \u0080 in specific fields
    // Clang doesn't accept those characters in the generated code
    let filteredTestCases = testCases.filter { testCase in
        !testCase.source.contains("\\uD900") && !(testCase.toUnicode?.contains("\\u0080") ?? false)
    }

    print("Parsed \(testCases.count) test cases, filtered to \(filteredTestCases.count) cases")

    var generatedCode = """
        #include "../include/CSwiftDNSIDNATesting.h"
        #include <stddef.h>

        #define IDNA_TEST_V2_CASES_COUNT \(filteredTestCases.count)

        extern const IDNATestV2CCase idna_test_v2_cases[];

        const IDNATestV2CCase* idna_test_v2_all_cases(size_t* count) {
            *count = IDNA_TEST_V2_CASES_COUNT;
            return idna_test_v2_cases;
        }

        static const char* empty_status[1] = {NULL};

        static const char* idna_test_v2_status_arrays[][100] = {

        """

    for testCase in filteredTestCases {
        let toUnicodeStatusArray = testCase.toUnicodeStatus.map {
            "\"\($0)\""
        }.joined(separator: ", ")
        generatedCode += "            { \(toUnicodeStatusArray) },\n"
        let toAsciiNStatusArray = testCase.toAsciiNStatus.map {
            "\"\($0)\""
        }.joined(separator: ", ")
        generatedCode += "            { \(toAsciiNStatusArray) },\n"
        let toAsciiTStatusArray = testCase.toAsciiTStatus.map {
            "\"\($0)\""
        }.joined(separator: ", ")
        generatedCode += "            { \(toAsciiTStatusArray) },\n"
    }

    generatedCode += """
        };

        const IDNATestV2CCase idna_test_v2_cases[] = {

        """

    for (index, testCase) in filteredTestCases.enumerated() {
        generatedCode += """
                    {
                        .source = "\(testCase.source)",
                        .toUnicode = \(testCase.toUnicode.quotedOrNULL()),
                        .toUnicodeStatus = idna_test_v2_status_arrays[\(index * 3)],
                        .toUnicodeStatusCount = \(testCase.toUnicodeStatus.count),
                        .toAsciiN = \(testCase.toAsciiN.quotedOrNULL()),
                        .toAsciiNStatus = idna_test_v2_status_arrays[\(index * 3 + 1)],
                        .toAsciiNStatusCount = \(testCase.toAsciiNStatus.count),
                        .toAsciiT = \(testCase.toAsciiT.quotedOrNULL()),
                        .toAsciiTStatus = idna_test_v2_status_arrays[\(index * 3 + 2)],
                        .toAsciiTStatusCount = \(testCase.toAsciiTStatus.count),
                    },

            """
    }

    generatedCode += """
        };

        """

    return generatedCode
}

extension StringProtocol {
    func trimmingWhitespaces() -> String {
        String(
            Substring.UnicodeScalarView(
                self.unicodeScalars
                    .drop(while: { $0.value == 32 })
                    .reversed()
                    .drop(while: { $0.value == 32 })
                    .reversed()
            )
        )
    }

    func emptyIfIsOnlyQuotesAndNilIfEmpty() -> String? {
        if self.isEmpty {
            return nil
        } else if self.unicodeScalars.count == 2,
            self.unicodeScalars.first == #"""#
                && self.unicodeScalars.last == #"""#
        {
            return ""
        } else {
            return String(self)
        }
    }
}

extension String? {
    func quotedOrNULL() -> String {
        switch self {
        case .some(let value):
            return "\"\(value)\""
        case .none:
            return "NULL"
        }
    }
}

let text = generate()
print("Generated \(text.split(whereSeparator: \.isNewline).count) lines")

if FileManager.default.fileExists(atPath: outputPath),
    try! String(contentsOfFile: outputPath, encoding: .utf8) == text
{
    print("Generated code matches current contents, no changes needed.")
} else {
    print("Writing to \(outputPath) ...")
    try! text.write(toFile: outputPath, atomically: true, encoding: .utf8)
}

print("Done!")
