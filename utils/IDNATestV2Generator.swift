#!/usr/bin/env swift

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let testV2URL = "https://www.unicode.org/Public/idna/16.0.0/IdnaTestV2.txt"
let outputPath = "Sources/CSwiftDNSIDNATesting/src/idna_test_v2_cases.c"

struct IDNATestV2CCase {
    let source: String
    let toUnicode: String
    let toUnicodeStatus: [String]
    let toAsciiN: String
    let toAsciiNStatus: [String]
    let toAsciiT: String
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

func escapeString(_ string: String) -> String {
    var result = ""
    for scalar in string.unicodeScalars {
        switch scalar {
        case #"""#:
            result += #"\""#
        default:
            result.append(String(scalar))
        }
    }
    return result
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
    var buffer = ""
    for rawLine in utf8String.split(separator: "\n", omittingEmptySubsequences: false) {
        let line = String(rawLine)
        if line.trimmingWhitespaces().hasPrefix("#") { continue }
        if line.trimmingWhitespaces().isEmpty { continue }
        if buffer.isEmpty {
            buffer = line
        } else {
            buffer += "\n" + line
        }
        let commentIdx = buffer.firstIndex(of: "#")
        let semicolonCount: Int
        if let idx = commentIdx {
            semicolonCount = buffer[..<idx].reduce(0) { $1 == ";" ? $0 + 1 : $0 }
        } else {
            semicolonCount = buffer.reduce(0) { $1 == ";" ? $0 + 1 : $0 }
        }
        if semicolonCount < 6 { continue }
        var record = buffer
        buffer = ""
        if let commentIndex = record.firstIndex(of: "#") {
            record = String(record[..<commentIndex]).trimmingWhitespaces()
        }
        let parts = record.unicodeScalars.split(
            separator: ";",
            omittingEmptySubsequences: false
        ).map {
            String($0).trimmingWhitespaces()
        }
        let paddedParts = parts + Array(repeating: "", count: max(0, 7 - parts.count))
        let source = paddedParts[0]
        let toUnicode = paddedParts[1]
        let toUnicodeStatus = parseStatusString(paddedParts[2])
        let toAsciiN = paddedParts[3]
        let toAsciiNStatus = parseStatusString(paddedParts[4])
        let toAsciiT = paddedParts[5]
        let toAsciiTStatus = parseStatusString(paddedParts[6])
        let testCase = IDNATestV2CCase(
            source: source,
            toUnicode: toUnicode.isEmpty ? source : toUnicode,
            toUnicodeStatus: toUnicodeStatus,
            toAsciiN: toAsciiN.isEmpty ? (toUnicode.isEmpty ? source : toUnicode) : toAsciiN,
            toAsciiNStatus: toAsciiNStatus.isEmpty ? toUnicodeStatus : toAsciiNStatus,
            toAsciiT: toAsciiT.isEmpty
                ? (toAsciiN.isEmpty ? (toUnicode.isEmpty ? source : toUnicode) : toAsciiN)
                : toAsciiT,
            toAsciiTStatus: toAsciiTStatus.isEmpty
                ? (toAsciiNStatus.isEmpty ? toUnicodeStatus : toAsciiNStatus) : toAsciiTStatus
        )
        testCases.append(testCase)
    }

    // Filter out test cases that contain \uD900 or \u0080 in toUnicode
    // Clang doesn't accept those characters in the generated code
    let filteredTestCases = testCases.filter { testCase in
        !testCase.toUnicode.contains("\\uD900") && !testCase.toUnicode.contains("\\u0080")
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
        let toUnicodeStatusArray = testCase.toUnicodeStatus.map { "\"\($0)\"" }.joined(
            separator: ", "
        )
        generatedCode += "            { \(toUnicodeStatusArray) },\n"
        let toAsciiNStatusArray = testCase.toAsciiNStatus.map { "\"\($0)\"" }.joined(
            separator: ", "
        )
        generatedCode += "            { \(toAsciiNStatusArray) },\n"
        let toAsciiTStatusArray = testCase.toAsciiTStatus.map { "\"\($0)\"" }.joined(
            separator: ", "
        )
        generatedCode += "            { \(toAsciiTStatusArray) },\n"
    }

    generatedCode += """
        };

        const IDNATestV2CCase idna_test_v2_cases[] = {

        """

    for (index, testCase) in filteredTestCases.enumerated() {
        let sourceEscaped = escapeString(testCase.source)
        let toUnicodeEscaped = escapeString(testCase.toUnicode)
        let toAsciiNEscaped = escapeString(testCase.toAsciiN)
        let toAsciiTEscaped = escapeString(testCase.toAsciiT)
        generatedCode += """
                    {
                        .source = "\(sourceEscaped)",
                        .toUnicode = "\(toUnicodeEscaped)",
                        .toUnicodeStatus = idna_test_v2_status_arrays[\(index * 3)],
                        .toUnicodeStatusCount = \(testCase.toUnicodeStatus.count),
                        .toAsciiN = "\(toAsciiNEscaped)",
                        .toAsciiNStatus = idna_test_v2_status_arrays[\(index * 3 + 1)],
                        .toAsciiNStatusCount = \(testCase.toAsciiNStatus.count),
                        .toAsciiT = "\(toAsciiTEscaped)",
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
            String(
                self
                    .trimmingPrefix(while: \.isWhitespace)
                    .reversed()
            )
            .trimmingPrefix(while: \.isWhitespace)
            .reversed()
        )
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
