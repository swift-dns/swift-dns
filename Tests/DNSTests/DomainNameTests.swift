import DNSCore
import DNSModels
import NIOCore
import Testing

@Suite
struct DomainNameTests {
    @Test(
        arguments: [
            (name: "*", isFQDN: false, data: ByteBuffer([1, 42])),
            (name: "a", isFQDN: false, data: ByteBuffer([1, 97])),
            (name: "*.b", isFQDN: false, data: ByteBuffer([1, 42, 1, 98])),
            (name: "a.b", isFQDN: false, data: ByteBuffer([1, 97, 1, 98])),
            (name: "*.b.c", isFQDN: false, data: ByteBuffer([1, 42, 1, 98, 1, 99])),
            (name: "a.b.c", isFQDN: false, data: ByteBuffer([1, 97, 1, 98, 1, 99])),
            (name: "a.b.c.", isFQDN: true, data: ByteBuffer([1, 97, 1, 98, 1, 99])),
            (name: #"test\."#, isFQDN: true, data: ByteBuffer([5, 116, 101, 115, 116, 92])),
            (
                name: "Mijia Cloud",
                isFQDN: false,
                data: ByteBuffer([
                    11, 109, 105, 106, 105, 97, 32, 99, 108, 111, 117, 100,
                ])
            ),
            (
                name: "helloß.co.uk.",
                isFQDN: true,
                data: ByteBuffer([
                    13, 120, 110, 45, 45, 104, 101, 108, 108, 111, 45, 112, 113, 97,
                    2, 99, 111, 2, 117, 107,
                ])
            ),
        ]
    )
    func initFromString(name: String, isFQDN: Bool, data: ByteBuffer) throws {
        let domainName = try DomainName(string: name)
        #expect(domainName.isFQDN == isFQDN)
        #expect(domainName.data == data)
    }

    @Test(
        arguments: [".mahdibm.com", ""]
    )
    func initInvalidFromString(name: String) throws {
        #expect(throws: (any Error).self) {
            try DomainName(string: name)
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
        let name = try DomainName(string: unicode)
        let nameASCII = try DomainName(string: ascii)

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
        let name = try DomainName(string: "example.com.")
        let duplicate = try DomainName(string: "example.com.")
        let uppercased = try DomainName(string: "EXAMPLE.COM.")
        let partiallyUppercased = try DomainName(string: "exaMple.com.")
        let notFQDN = try DomainName(string: "example.com")
        let letterMismatch = try DomainName(string: "exmmple.com.")
        let bordersMismatch = try DomainName(string: "example.com.com.")
        let different = try DomainName(string: "mahdibm.com.")
        let differentNotFQDN = try DomainName(string: "mahdibm.com")

        #expect(name == duplicate)
        #expect(name == uppercased)
        #expect(name == partiallyUppercased)
        #expect(name != notFQDN)
        #expect(name != letterMismatch)
        #expect(name != bordersMismatch)
        #expect(name != different)
        #expect(name != differentNotFQDN)

        let weirdUniccdeLowercaseDomain = try DomainName(string: "helloß.co.uk.")
        let weirdPartiallyUppercaseDomain = try DomainName(string: "helloSS.co.uk.")
        let weirdUppercaseDomain = try DomainName(string: "HELLOSS.CO.UK.")

        /// The DomainName initializers turn non-ascii domain names to IDNA-encoded domain names.
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
        try #expect(DomainName(string: name).isFQDN == isFQDN)
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
            try DomainName(string: name).description(
                format: .unicode,
                options: .includeRootLabelIndicator
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
        try #expect(DomainName(string: name).labelsCount == expectedLabelsCount)
    }

    @Test func decodeFromBufferContainingOtherBytesAsWellAsUppercasedThenTurnBackIntoString() throws
    {
        var buffer = DNSBuffer(bytes: [
            0x01, 0x02, 0x03, 0x04,

            0x07, 0x45, 0x78, 0x61,
            0x6d, 0x70, 0x6c, 0x65,
            0x03, 0x63, 0x4f, 0x6d,
            0x00,

            0x01, 0x02, 0x03,
        ])
        /// The first 4 and the last 3 bytes are intentionally not part of the name
        buffer.moveReaderIndex(forwardBy: 4)
        let endIndex = buffer.writerIndex
        let name = try DomainName(from: &buffer)
        #expect(name.data.readableBytesView.last != 0)
        #expect(buffer.readerIndex == endIndex - 3)
        #expect(buffer.readableBytes == 3)
        #expect(
            name.description(format: .unicode, options: .includeRootLabelIndicator)
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
        let endIndex = buffer.writerIndex
        let name = try DomainName(from: &buffer)
        #expect(name.data.readableBytesView.last != 0)
        #expect(buffer.readerIndex == endIndex)
        #expect(buffer.readableBytes == 0)
        #expect(name.description == "新华网.中国")
        #expect(
            name.description(format: .unicode, options: .includeRootLabelIndicator)
                == "新华网.中国."
        )
        #expect(
            name.description(format: .ascii, options: .includeRootLabelIndicator)
                == "xn--xkrr14bows.xn--fiqs8s."
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func ipv4AddressToName() throws {
        let ipAddress = IPv4Address(192, 168, 1, 1)
        let name1 = DomainName(ipv4: ipAddress)
        let name2 = DomainName(ip: .v4(ipAddress))
        #expect(name1.description == "192.168.1.1")
        #expect(name2.description == "192.168.1.1")
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func ipv6AddressToName() {
        let ipAddress: IPv6Address = 0x2a01_5cc0_0001_0002_0000_0000_0000_0004
        let name1 = DomainName(ipv6: ipAddress)
        let name2 = DomainName(ip: .v6(ipAddress))
        #expect(name1.description == "[2a01:5cc0:1:2::4]")
        #expect(name2.description == "[2a01:5cc0:1:2::4]")
    }

    /// The file pointing to `Resources.topDomains` contains only 200 top domains, but you can
    /// try bigger files too.
    /// For example you can manually go to cloudflare radar (https://radar.cloudflare.com/domains)
    /// and download the top 1 million domains csv file (or really top any-number, just csv).
    /// Just make sure the download file is only 1 column (so only a new domain on each new line).
    /// Then put it in Tests/Resources/ directory named exactly as `top-domains.csv`.
    /// And untrack the file so it's not committed to git (it's 14+ MiB).
    /// The file is 14+ MiB in size so it's not included in the repo.
    ///
    /// Not using swift-testing arguments because that slows things down significantly if we're
    /// testing against 1 million domains.
    @Test func testAgainstTopCloudflareRadarDomains() throws {
        for (index, domainName) in enumeratedTopDomains() {
            let comment: Comment = "index: \(index), domainName: \(domainName)"
            #expect(throws: Never.self, comment) {
                let name = try DomainName(string: domainName)
                let recreatedDomainName = name.description(
                    format: .ascii,
                    options: .includeRootLabelIndicator
                )
                #expect(recreatedDomainName == domainName, comment)
            }
        }
    }
}

private func enumeratedTopDomains() -> EnumeratedSequence<[String]> {
    String(
        decoding: Resources.topDomains.data(),
        as: UTF8.self
    ).split(
        whereSeparator: \.isNewline
    )
    .dropFirst()
    .map(String.init)
    .enumerated()
}
