import DNSCore
import DNSModels
import Testing

@Suite
struct NameTests {
    @Test(
        arguments: [
            (name: "*", isFQDN: false, data: [42], borders: [1]),
            (name: "a", isFQDN: false, data: [97], borders: [1]),
            (name: "*.b", isFQDN: false, data: [42, 98], borders: [1, 2]),
            (name: "a.b", isFQDN: false, data: [97, 98], borders: [1, 2]),
            (name: "*.b.c", isFQDN: false, data: [42, 98, 99], borders: [1, 2, 3]),
            (name: "a.b.c", isFQDN: false, data: [97, 98, 99], borders: [1, 2, 3]),
            (name: "a.b.c.", isFQDN: true, data: [97, 98, 99], borders: [1, 2, 3]),
            (name: #"test\."#, isFQDN: false, data: [116, 101, 115, 116, 46], borders: [5]),
        ]
    )
    func initFromString(name: String, isFQDN: Bool, data: [UInt8], borders: [UInt8]) async throws {
        let domainName = try Name(string: name)
        #expect(domainName.isFQDN == isFQDN)
        #expect(domainName.data == data)
        #expect(domainName.borders == borders)
    }

    @Test(
        arguments: [
            ".mahdibm.com"
        ]
    )
    func initInvalidFromString(name: String) async throws {
        #expect(throws: (any Error).self) {
            try Name(string: name)
        }
    }

    @Test func equality() async throws {
        let name = try Name(string: "example.com.")
        let duplicate = try Name(string: "example.com.")
        let uppercased = try Name(string: "EXAMPLE.COM.")
        let partiallyUppercased = try Name(string: "exaMple.com.")
        let notFQDN = try Name(string: "example.com")
        let letterMismatch = try Name(string: "exmmple.com.")
        let bordersMismatch = try Name(string: "example.com.com.")
        let different = try Name(string: "mahdibm.com.")
        let differentNotFQDN = try Name(string: "mahdibm.com")

        #expect(name == duplicate)
        #expect(name != uppercased)
        #expect(name != partiallyUppercased)
        #expect(name != notFQDN)
        #expect(name != letterMismatch)
        #expect(name != bordersMismatch)
        #expect(name != different)
        #expect(name != differentNotFQDN)
    }

    @Test func caseInsensitiveEquality() async throws {
        withKnownIssue(
            "Need to implement cross-platform case-insensitive equality w/o relying on Foundation"
        ) {
            let name = try Name(string: "example.com.")
            let duplicate = try Name(string: "example.com.")
            let uppercased = try Name(string: "EXAMPLE.COM.")
            let partiallyUppercased = try Name(string: "exaMple.com.")
            let notFQDN = try Name(string: "example.com")
            let letterMismatch = try Name(string: "exmmple.com.")
            let bordersMismatch = try Name(string: "example.com.com.")
            let different = try Name(string: "mahdibm.com.")
            let differentNotFQDN = try Name(string: "mahdibm.com")

            #expect(name.__caseInsensitiveEquals(duplicate))
            #expect(name.__caseInsensitiveEquals(uppercased))
            #expect(name.__caseInsensitiveEquals(partiallyUppercased))
            #expect(!name.__caseInsensitiveEquals(notFQDN))
            #expect(!name.__caseInsensitiveEquals(letterMismatch))
            #expect(!name.__caseInsensitiveEquals(bordersMismatch))
            #expect(!name.__caseInsensitiveEquals(different))
            #expect(!name.__caseInsensitiveEquals(differentNotFQDN))
        }
    }

    @Test(
        arguments: [
            (name: ".", isFQDN: true),
            (name: "", isFQDN: false),
            (name: "www.example.com.", isFQDN: true),
            (name: "www.example", isFQDN: false),
            (name: "www", isFQDN: false),
            (name: "test.", isFQDN: true),
            (name: #"test\."#, isFQDN: false),
        ]
    )
    func `fqdnParsing`(name: String, isFQDN: Bool) async throws {
        try #expect(Name(string: name).isFQDN == isFQDN)
    }

    @Test(
        arguments: [
            (name: ".", expected: "."),
            (name: "", expected: ""),
            (name: "www.example.com.", expected: "www.example.com."),
            (name: "www.example", expected: "www.example"),
            (name: "www", expected: "www"),
            (name: "test.", expected: "test."),
            (name: #"test\."#, expected: "test."),
        ]
    )
    func `parsingThenAsStringWorksAsExpected`(name: String, expected: String) async throws {
        #expect(try Name(string: name).asString() == expected)
    }

    @Test(
        arguments: [
            (name: "*", expectedLabelsCount: 0),
            (name: "a", expectedLabelsCount: 1),
            (name: "*.b", expectedLabelsCount: 1),
            (name: "a.b", expectedLabelsCount: 2),
            (name: "*.b.c", expectedLabelsCount: 2),
            (name: "a.b.c", expectedLabelsCount: 3),
        ]
    )
    func `numberOfLabels`(name: String, expectedLabelsCount: Int) async throws {
        try #expect(Name(string: name).labelsCount == expectedLabelsCount)
    }

    @Test func decodeFromBuffer() async throws {
        var buffer = DNSBuffer(bytes: [
            0x07, 0x65, 0x78, 0x61,
            0x6d, 0x70, 0x6c, 0x65,
            0x03, 0x63, 0x6f, 0x6d,
            0x00,
        ])
        let name = try Name(from: &buffer)
        #expect(name.asString() == "example.com.")
    }
}
