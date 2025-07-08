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
            (
                name: "Mijia Cloud", isFQDN: false,
                data: [77, 105, 106, 105, 97, 32, 67, 108, 111, 117, 100], borders: [11]
            ),
            (
                name: "helloß.co.uk.", isFQDN: true,
                data: [
                    13, 120, 110, 45, 45, 104, 101, 108, 108, 111,
                    45, 112, 113, 97, 2, 99, 111, 2, 117, 107,
                ],
                borders: [7, 9, 11]
            ),
        ]
    )
    func initFromString(name: String, isFQDN: Bool, data: [UInt8], borders: [UInt8]) throws {
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
    func initInvalidFromString(name: String) throws {
        #expect(throws: (any Error).self) {
            try Name(string: name)
        }
    }

    @Test(
        arguments: [
            ("xn--1lq90ic7f1rc.cn", "\u{5317}\u{4eac}\u{5927}\u{5b78}.cn"),
            ("xn--36c-tfa.com", "xn--36c-tfa.com"),
            ("www.xn--hello-pqa.co.uk.", "www.helloß.co.uk."),
        ]
    )
    func description(name: String, expected: String) throws {
        let name = try Name(string: name)
        #expect(name.description == expected)
    }

    @Test func equalityWhichShouldBeCaseInsensitive() throws {
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
        #expect(name == uppercased)
        #expect(name == partiallyUppercased)
        #expect(name != notFQDN)
        #expect(name != letterMismatch)
        #expect(name != bordersMismatch)
        #expect(name != different)
        #expect(name != differentNotFQDN)

        let weirdLowercaseDomain = try Name(string: "helloß.co.uk.")
        let weirdPartiallyUppercaseDomain = try Name(string: "helloSS.co.uk.")
        let weirdUppercaseDomain = try Name(string: "HELLOSS.CO.UK.")

        #expect(weirdLowercaseDomain == weirdPartiallyUppercaseDomain)
        #expect(weirdLowercaseDomain == weirdUppercaseDomain)
        #expect(weirdPartiallyUppercaseDomain == weirdUppercaseDomain)
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
    func `fqdnParsing`(name: String, isFQDN: Bool) throws {
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
    func `parsingThenAsStringWorksAsExpected`(name: String, expected: String) throws {
        #expect(try Name(string: name).description == expected)
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
    func `numberOfLabels`(name: String, expectedLabelsCount: Int) throws {
        try #expect(Name(string: name).labelsCount == expectedLabelsCount)
    }

    @Test func decodeFromBufferAndTurnBackIntoString() throws {
        var buffer = DNSBuffer(bytes: [
            0x07, 0x65, 0x78, 0x61,
            0x6d, 0x70, 0x6c, 0x65,
            0x03, 0x63, 0x6f, 0x6d,
            0x00,
        ])
        let name = try Name(from: &buffer)
        #expect(name.description == "example.com.")
    }

    @Test func decodeNonASCIIFromBufferAndTurnBackIntoString() throws {
        /// Testing `helloß.co.uk.` which turns into `www.xn--heloo-pqa.co.uk.` based on punycode.
        var buffer = DNSBuffer(bytes: [
            0x3, 0x77, 0x77, 0x77,
            0xd, 0x78, 0x6e, 0x2d,
            0x2d, 0x68, 0x65, 0x6c,
            0x6c, 0x6f, 0x2d, 0x70,
            0x71, 0x61, 0x2, 0x63,
            0x6f, 0x2, 0x75, 0x6b,
            0x0,
        ])
        let name = try Name(from: &buffer)
        #expect(name.description == "helloß.co.uk.")
    }
}
