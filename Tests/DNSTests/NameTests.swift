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
            (name: #"test\."#, isFQDN: true, data: [116, 101, 115, 116, 92], borders: [5]),
            (
                name: "Mijia Cloud",
                isFQDN: false,
                data: [109, 105, 106, 105, 97, 32, 99, 108, 111, 117, 100],
                borders: [11]
            ),
            (
                name: "helloß.co.uk.",
                isFQDN: true,
                data: [
                    120, 110, 45, 45, 104, 101, 108, 108, 111, 45, 112, 113, 97, 99, 111, 117, 107,
                ],
                borders: [13, 15, 17]
            ),
        ]
    )
    func initFromString(name: String, isFQDN: Bool, data: [UInt8], borders: [UInt8]) throws {
        let domainName = try Name(domainName: name)
        print(domainName.debugDescription)
        #expect(domainName.isFQDN == isFQDN)
        #expect(domainName.data == data)
        #expect(domainName.borders == borders)
    }

    @Test(
        arguments: [".mahdibm.com", ""]
    )
    func initInvalidFromString(name: String) throws {
        #expect(throws: (any Error).self) {
            try Name(domainName: name)
        }
    }

    @Test(
        arguments: [
            (
                ascii: "royale.mahdibm.com.",
                unicode: "royale.mahdibm.com.",
                asciiNoRootLabel: "royale.mahdibm.com",
                unicodeNoRootLabel: "royale.mahdibm.com",
            ),
            (
                ascii: "xn--1lq90ic7f1rc.cn",
                unicode: "\u{5317}\u{4eac}\u{5927}\u{5b78}.cn",
                asciiNoRootLabel: "xn--1lq90ic7f1rc.cn",
                unicodeNoRootLabel: "\u{5317}\u{4eac}\u{5927}\u{5b78}.cn",
            ),
            (
                ascii: "xn--36c-tfa.com",
                unicode: "36°c.com",
                asciiNoRootLabel: "xn--36c-tfa.com",
                unicodeNoRootLabel: "36°c.com"
            ),
            (
                ascii: "www.xn--hello-pqa.co.uk.",
                unicode: "www.helloß.co.uk.",
                asciiNoRootLabel: "www.xn--hello-pqa.co.uk",
                unicodeNoRootLabel: "www.helloß.co.uk"
            ),
        ]
    )
    func description(
        ascii: String,
        unicode: String,
        asciiNoRootLabel: String,
        unicodeNoRootLabel: String
    ) throws {
        let name = try Name(domainName: unicode)
        let nameASCII = try Name(domainName: ascii)

        /// If the names are the same then we don't need to compare their descriptions
        #expect(name == nameASCII)

        #expect(
            name.description(format: .ascii, options: .includeRootLabelIndicator)
                == ascii
        )
        #expect(
            name.description(format: .unicode, options: .includeRootLabelIndicator)
                == unicode
        )
        #expect(
            name.description(format: .ascii)
                == asciiNoRootLabel
        )
        #expect(
            name.description(format: .unicode)
                == unicodeNoRootLabel
        )
    }

    @Test func equalityWhichMustBeCaseInsensitive() throws {
        let name = try Name(domainName: "example.com.")
        let duplicate = try Name(domainName: "example.com.")
        let uppercased = try Name(domainName: "EXAMPLE.COM.")
        let partiallyUppercased = try Name(domainName: "exaMple.com.")
        let notFQDN = try Name(domainName: "example.com")
        let letterMismatch = try Name(domainName: "exmmple.com.")
        let bordersMismatch = try Name(domainName: "example.com.com.")
        let different = try Name(domainName: "mahdibm.com.")
        let differentNotFQDN = try Name(domainName: "mahdibm.com")

        #expect(name == duplicate)
        #expect(name == uppercased)
        #expect(name == partiallyUppercased)
        #expect(name != notFQDN)
        #expect(name != letterMismatch)
        #expect(name != bordersMismatch)
        #expect(name != different)
        #expect(name != differentNotFQDN)

        let weirdUniccdeLowercaseDomain = try Name(domainName: "helloß.co.uk.")
        let weirdPartiallyUppercaseDomain = try Name(domainName: "helloSS.co.uk.")
        let weirdUppercaseDomain = try Name(domainName: "HELLOSS.CO.UK.")

        /// The Name initializers turn non-ascii domain names to IDNA-encoded domain names.
        /// `ß` and `SS` are case-insensitively equal, so with no IDNA these 2 names would be equal.
        #expect(weirdUniccdeLowercaseDomain != weirdPartiallyUppercaseDomain)
        #expect(weirdUniccdeLowercaseDomain != weirdUppercaseDomain)
        #expect(weirdPartiallyUppercaseDomain == weirdUppercaseDomain)
    }

    @Test(
        arguments: [
            (name: ".", isFQDN: true),
            (name: "www.example.com.", isFQDN: true),
            (name: "www.example", isFQDN: false),
            (name: "www", isFQDN: false),
            (name: "test.", isFQDN: true),
            (name: #"test\."#, isFQDN: true),
        ]
    )
    func `fqdnParsing`(name: String, isFQDN: Bool) throws {
        try #expect(Name(domainName: name).isFQDN == isFQDN)
    }

    @Test(
        arguments: [
            (name: ".", expected: "."),
            (name: "www.example.com.", expected: "www.example.com."),
            (name: "www.example", expected: "www.example"),
            (name: "www", expected: "www"),
            (name: "test.", expected: "test."),
            (name: #"test\."#, expected: #"test\."#),
        ]
    )
    func `parsingThenAsStringWorksAsExpected`(name: String, expected: String) throws {
        #expect(
            try Name(domainName: name).description(
                format: .unicode,
                options: .sourceAccurate
            ) == expected
        )
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
        try #expect(Name(domainName: name).labelsCount == expectedLabelsCount)
    }

    @Test func decodeFromBufferAndTurnBackIntoString() throws {
        var buffer = DNSBuffer(bytes: [
            0x07, 0x65, 0x78, 0x61,
            0x6d, 0x70, 0x6c, 0x65,
            0x03, 0x63, 0x6f, 0x6d,
            0x00,
        ])
        let name = try Name(from: &buffer)
        #expect(
            name.description(format: .unicode, options: .sourceAccurate)
                == "example.com."
        )
    }

    /// Testing `新华网.中国.` which turns into `xn--xkrr14bows.xn--fiqs8s.` based on punycode.
    /// There are non-ascii bytes in this buffer which is technically not correct.
    /// The initializer is expected to repair the bytes into ASCII.
    @Test func decodeInvalidNonASCIIDomainAndRepairItIntoASCII() throws {
        var buffer = DNSBuffer(bytes: [
            0x9, 0xe6, 0x96, 0xb0,
            0xe5, 0x8d, 0x8e, 0xe7,
            0xbd, 0x91, 0x6, 0xe4,
            0xb8, 0xad, 0xe5, 0x9b,
            0xbd, 0x0,
        ])
        let name = try Name(from: &buffer)
        #expect(name.description == "新华网.中国")
        #expect(
            name.description(format: .unicode, options: .sourceAccurate)
                == "新华网.中国."
        )
        #expect(
            name.description(format: .ascii, options: .sourceAccurate)
                == "xn--xkrr14bows.xn--fiqs8s."
        )
    }

    @Test(
        .tags(.veryTimeConsuming),
        .enabled(
            if: Resources.top1mDomains.fileExists(),
            """
            Need to manually go to cloudflare radar (https://radar.cloudflare.com/domains) and download
            the top 1 million domains csv file (or really top any-number, just csv).
            Then put it in Tests/Resources/ directory named exactly as `top-1m-domains.csv`.
            The file is 14+ MiB in size so it's not included in the repo.
            """
        ),
        arguments: String(
            decoding: Resources.top1mDomains.data(),
            as: UTF8.self
        ).split(
            whereSeparator: \.isNewline
        ).dropFirst().map(String.init)
    )
    func handleTop1MillionDomains(domainName: String) throws {
        let name = try Name(domainName: domainName)
        let recreatedDomainName = name.description(format: .ascii, options: .sourceAccurate)
        #expect(recreatedDomainName == domainName)
    }
}
