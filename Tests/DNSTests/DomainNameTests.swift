import DNSCore
import DNSModels
import NIOCore
import Testing

@Suite
struct DomainNameTests {
    @Test(
        arguments: [
            (domainName: "*", isFQDN: false, data: ByteBuffer([1, 42])),
            (domainName: "a", isFQDN: false, data: ByteBuffer([1, 97])),
            (domainName: "*.b", isFQDN: false, data: ByteBuffer([1, 42, 1, 98])),
            (domainName: "a.b", isFQDN: false, data: ByteBuffer([1, 97, 1, 98])),
            (domainName: "*.b.c", isFQDN: false, data: ByteBuffer([1, 42, 1, 98, 1, 99])),
            (domainName: "a.b.c", isFQDN: false, data: ByteBuffer([1, 97, 1, 98, 1, 99])),
            (domainName: "a.b.c.", isFQDN: true, data: ByteBuffer([1, 97, 1, 98, 1, 99])),
            (domainName: #"test\."#, isFQDN: true, data: ByteBuffer([5, 116, 101, 115, 116, 92])),
            (
                domainName: "Mijia Cloud",
                isFQDN: false,
                data: ByteBuffer([
                    11, 109, 105, 106, 105, 97, 32, 99, 108, 111, 117, 100,
                ])
            ),
            (
                domainName: "helloß.co.uk.",
                isFQDN: true,
                data: ByteBuffer([
                    13, 120, 110, 45, 45, 104, 101, 108, 108, 111, 45, 112, 113, 97,
                    2, 99, 111, 2, 117, 107,
                ])
            ),
        ]
    )
    func initFromString(domainName: String, isFQDN: Bool, data: ByteBuffer) throws {
        let domainName = try DomainName(string: domainName)
        #expect(domainName.isFQDN == isFQDN)
        #expect(domainName.data == data)
    }

    @Test(
        arguments: [".mahdibm.com", ""]
    )
    func initInvalidFromString(domainName: String) throws {
        #expect(throws: (any Error).self) {
            try DomainName(string: domainName)
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
        let domainName = try DomainName(string: unicode)
        let nameASCII = try DomainName(string: ascii)

        /// If the names are the same then we don't need to compare their descriptions
        #expect(domainName == nameASCII)

        #expect(
            domainName.description(format: .ascii, options: .includeRootLabelIndicator)
                == ascii
        )
        #expect(
            domainName.description(format: .unicode, options: .includeRootLabelIndicator)
                == unicode
        )
        #expect(
            domainName.description(format: .ascii)
                == asciiNoRootLabel
        )
        #expect(
            domainName.description(format: .unicode)
                == unicodeNoRootLabel
        )
    }

    @Test func equalityWhichMustBeCaseInsensitive() throws {
        let domainName = try DomainName(string: "example.com.")
        let duplicate = try DomainName(string: "example.com.")
        let uppercased = try DomainName(string: "EXAMPLE.COM.")
        let partiallyUppercased = try DomainName(string: "exaMple.com.")
        let notFQDN = try DomainName(string: "example.com")
        let letterMismatch = try DomainName(string: "exmmple.com.")
        let bordersMismatch = try DomainName(string: "example.com.com.")
        let different = try DomainName(string: "mahdibm.com.")
        let differentNotFQDN = try DomainName(string: "mahdibm.com")

        #expect(domainName == duplicate)
        #expect(domainName == uppercased)
        #expect(domainName == partiallyUppercased)
        #expect(domainName != notFQDN)
        #expect(domainName != letterMismatch)
        #expect(domainName != bordersMismatch)
        #expect(domainName != different)
        #expect(domainName != differentNotFQDN)

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
            (domainName: ".", isFQDN: true),
            (domainName: "www.example.com.", isFQDN: true),
            (domainName: "www.example", isFQDN: false),
            (domainName: "www", isFQDN: false),
            (domainName: "test.", isFQDN: true),
            (domainName: #"test\."#, isFQDN: true),
        ]
    )
    func `fqdnParsing`(domainName: String, isFQDN: Bool) throws {
        try #expect(DomainName(string: domainName).isFQDN == isFQDN)
    }

    @Test(
        arguments: [
            (domainName: ".", expected: "."),
            (domainName: "www.example.com.", expected: "www.example.com."),
            (domainName: "www.example", expected: "www.example"),
            (domainName: "www", expected: "www"),
            (domainName: "test.", expected: "test."),
            (domainName: #"test\."#, expected: #"test\."#),
        ]
    )
    func `parsingThenAsStringWorksAsExpected`(domainName: String, expected: String) throws {
        #expect(
            try DomainName(string: domainName).description(
                format: .unicode,
                options: .includeRootLabelIndicator
            ) == expected
        )
    }

    @Test(
        arguments: [
            (domainName: "*", expectedLabelsCount: 0),
            (domainName: "a", expectedLabelsCount: 1),
            (domainName: "*.b", expectedLabelsCount: 1),
            (domainName: "a.b", expectedLabelsCount: 2),
            (domainName: "*.b.c", expectedLabelsCount: 2),
            (domainName: "a.b.c", expectedLabelsCount: 3),
        ]
    )
    func `numberOfLabels`(domainName: String, expectedLabelsCount: Int) throws {
        try #expect(DomainName(string: domainName).labelsCount == expectedLabelsCount)
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
        /// The first 4 and the last 3 bytes are intentionally not part of the domainName
        buffer.moveReaderIndex(forwardBy: 4)
        let endIndex = buffer.writerIndex
        let domainName = try DomainName(from: &buffer)
        #expect(domainName.data.readableBytesView.last != 0)
        #expect(buffer.readerIndex == endIndex - 3)
        #expect(buffer.readableBytes == 3)
        #expect(
            domainName.description(format: .unicode, options: .includeRootLabelIndicator)
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
        let domainName = try DomainName(from: &buffer)
        #expect(domainName.data.readableBytesView.last != 0)
        #expect(buffer.readerIndex == endIndex)
        #expect(buffer.readableBytes == 0)
        #expect(domainName.description == "新华网.中国")
        #expect(
            domainName.description(format: .unicode, options: .includeRootLabelIndicator)
                == "新华网.中国."
        )
        #expect(
            domainName.description(format: .ascii, options: .includeRootLabelIndicator)
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
        for (index, domainNameString) in enumeratedTopDomains() {
            let comment: Comment = "index: \(index), domainName: \(domainNameString)"
            #expect(throws: Never.self, comment) {
                let domainName = try DomainName(string: domainNameString)
                let recreatedDomainName = domainName.description(
                    format: .ascii,
                    options: .includeRootLabelIndicator
                )
                #expect(recreatedDomainName == domainNameString, comment)
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
