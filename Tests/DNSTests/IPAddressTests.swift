import DNSModels
import Testing

@Suite
struct IPAddressTests {
    @Test func ipv4Address() {
        let ip = IPv4Address(127, 0, 0, 1)
        #expect(ip.address == 0x7F00_0001)
        #expect(ip.bytes == (0x7F, 0x00, 0x00, 0x01))
    }

    @Test(
        arguments: [
            (IPv4Address(127, 0, 0, 1), "127.0.0.1"),
            (IPv4Address(120, 102, 12, 100), "120.102.12.100"),
            (IPv4Address(0, 0, 0, 0), "0.0.0.0"),
            (IPv4Address(0, 0, 0, 1), "0.0.0.1"),
            (IPv4Address(0, 0, 1, 0), "0.0.1.0"),
            (IPv4Address(0, 1, 0, 0), "0.1.0.0"),
            (IPv4Address(1, 0, 0, 0), "1.0.0.0"),
            (IPv4Address(1, 1, 1, 1), "1.1.1.1"),
            (IPv4Address(123, 251, 98, 234), "123.251.98.234"),
            (IPv4Address(255, 255, 255, 255), "255.255.255.255"),
            (IPv4Address(192, 168, 1, 98), "192.168.1.98"),
        ]
    )
    func ipv4AddressDescription(ip: IPv4Address, expectedDescription: String) {
        #expect(ip.description == expectedDescription)
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: ipv4StringAndAddressTestCases
            + ipv4IDNAStringAndAddressTestCases.map { ($0.0, nil, $0.2) }
    )
    func ipv4AddressFromString(
        string: String,
        expectedAddress: IPv4Address?,
        isValidIPv6: Bool
    ) {
        #expect(IPv4Address(string) == expectedAddress)
        #expect(IPv4Address(Substring(string)) == expectedAddress)
        #expect(IPv4Address(textualRepresentation: string.utf8Span) == expectedAddress)
        #expect(IPv4Address(textualRepresentation: string.utf8Span.span) == expectedAddress)

        if isValidIPv6 {
            #expect(IPAddress(string)?.isIPv6 == true)
            #expect(IPAddress(Substring(string))?.isIPv6 == true)
            #expect(IPAddress(textualRepresentation: string.utf8Span)?.isIPv6 == true)
            #expect(IPAddress(textualRepresentation: string.utf8Span.span)?.isIPv6 == true)
        } else {
            let expectedIPv4: IPAddress? = expectedAddress.map { .v4($0) }
            #expect(IPAddress(string) == expectedIPv4)
            #expect(IPAddress(Substring(string)) == expectedIPv4)
            #expect(IPAddress(textualRepresentation: string.utf8Span) == expectedIPv4)
            #expect(IPAddress(textualRepresentation: string.utf8Span.span) == expectedIPv4)
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: ipv4StringAndAddressTestCases
            + ipv4IDNAStringAndAddressTestCases
    )
    func ipv4AddressFromStringThroughDomainName(
        string: String,
        expectedAddress: IPv4Address?,
        isValidIPv6: Bool
    ) {
        let domainName = try? DomainName(string: string)

        let ipv4Address = domainName.flatMap { IPv4Address(domainName: $0) }
        #expect(ipv4Address == expectedAddress)

        let ipAddress = domainName.flatMap { IPAddress(domainName: $0) }
        switch ipAddress {
        case .v4(let ipv4):
            #expect(ipv4 == expectedAddress)
        case .none:
            #expect(expectedAddress == nil)
        case .v6:
            if !isValidIPv6 {
                Issue.record("Expected IPv4 but got: \(ipAddress)")
            }
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: [(IPv4Address?, String)]([
            (IPv4Address(192, 0, 2, 128), "::ffff:c000:0280"),
            (IPv4Address(18, 52, 86, 120), "::ffff:1234:5678"),
            (IPv4Address(171, 205, 239, 1), "::ffff:abcd:ef01"),
            (nil, "0:0:1:0:0:ffff:abcd:ef01"),
            (nil, "ffff:ffff:ffff:ffff:ffff:ffff:abcd:ef01"),
        ])
    )
    func ipv4AddressFromIpv6Address(
        ipv4: IPv4Address?,
        expectedIPv6: String
    ) throws {
        let ipv6 = try #require(IPv6Address(expectedIPv6))
        #expect(ipv4 == IPv4Address(ipv6: ipv6))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [(IPv4Address, String, (@Sendable (IPv4Address) -> Bool))]([
            (IPv4Address(127, 0, 0, 0), "isLoopback", \.isLoopback),
            (IPv4Address(127, 0, 0, 1), "isLoopback", \.isLoopback),
            (IPv4Address(127, 128, 9, 22), "isLoopback", \.isLoopback),
            (IPv4Address(127, 255, 255, 255), "isLoopback", \.isLoopback),
            (IPv4Address(126, 0, 0, 0), "!isLoopback", { @Sendable in !$0.isLoopback }),
            (IPv4Address(128, 0, 0, 0), "!isLoopback", { @Sendable in !$0.isLoopback }),
            (IPv4Address(224, 0, 0, 0), "isMulticast", \.isMulticast),
            (IPv4Address(239, 255, 255, 255), "isMulticast", \.isMulticast),
            (IPv4Address(229, 28, 192, 233), "isMulticast", \.isMulticast),
            (IPv4Address(244, 0, 0, 0), "!isMulticast", { @Sendable in !$0.isMulticast }),
            (IPv4Address(169, 254, 0, 0), "isLinkLocal", \.isLinkLocal),
            (IPv4Address(169, 254, 222, 138), "isLinkLocal", \.isLinkLocal),
            (IPv4Address(169, 254, 255, 255), "isLinkLocal", \.isLinkLocal),
            (
                IPv4Address(169, 253, 0, 0), "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            (
                IPv4Address(169, 255, 0, 0), "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            (
                IPv4Address(168, 254, 0, 0), "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
            (
                IPv4Address(170, 254, 0, 0), "!isLinkLocal",
                { @Sendable in !$0.isLinkLocal }
            ),
        ])
    )
    func ipv4AddressPropertiesWorkCorrectly(
        ip: IPv4Address,
        testCaseDescription: String,
        predicate: @Sendable (IPv4Address) -> Bool
    ) throws {
        #expect(predicate(ip), "\(testCaseDescription)")
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func ipv6Address() {
        let ipWithUInt16 = IPv6Address(
            0x2001,
            0x0DB8,
            0x85A3,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x0100
        )
        let ip = IPv6Address(
            0x20,
            0x01,
            0x0D,
            0xB8,
            0x85,
            0xA3,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x00,
            0x01,
            0x00
        )
        #expect(ip.address == ipWithUInt16.address)
        #expect(ip.address == 0x2001_0DB8_85A3_0000_0000_0000_0000_0100)

        #expect(ip.bytes.0 == 0x20)
        #expect(ip.bytes.1 == 0x01)
        #expect(ip.bytes.2 == 0x0D)
        #expect(ip.bytes.3 == 0xB8)
        #expect(ip.bytes.4 == 0x85)
        #expect(ip.bytes.5 == 0xA3)
        #expect(ip.bytes.6 == 0x00)
        #expect(ip.bytes.7 == 0x00)
        #expect(ip.bytes.8 == 0x00)
        #expect(ip.bytes.9 == 0x00)
        #expect(ip.bytes.10 == 0x00)
        #expect(ip.bytes.11 == 0x00)
        #expect(ip.bytes.12 == 0x00)
        #expect(ip.bytes.13 == 0x00)
        #expect(ip.bytes.14 == 0x01)
        #expect(ip.bytes.15 == 0x00)

        #expect(ip.bytePairs.0 == 0x2001)
        #expect(ip.bytePairs.1 == 0x0DB8)
        #expect(ip.bytePairs.2 == 0x85A3)
        #expect(ip.bytePairs.3 == 0x0000)
        #expect(ip.bytePairs.4 == 0x0000)
        #expect(ip.bytePairs.5 == 0x0000)
        #expect(ip.bytePairs.6 == 0x0000)
        #expect(ip.bytePairs.7 == 0x0100)
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [
            (
                0x1111_2222_3333_4444_5555_6666_7777_8888,
                "[1111:2222:3333:4444:5555:6666:7777:8888]"
            ),
            (0x2001_0DB8_85A0_0000_0000_0000_0000_0100, "[2001:db8:85a0::100]"),
            (0x2001_0DB8_8503_0000_0000_0000_0000_0100, "[2001:db8:8503::100]"),
            (0x2001_0DB8_80A3_0000_0000_0000_0000_0100, "[2001:db8:80a3::100]"),
            (0x2001_0DB8_0000_0000_0001_0000_0000_0002, "[2001:db8::1:0:0:2]"),
            (0x2001_0DB8_1111_2222_3333_4444_0000_0000, "[2001:db8:1111:2222:3333:4444::]"),
            (0x2001_0DB8_1111_2222_3333_4444_5555_0000, "[2001:db8:1111:2222:3333:4444:5555:0]"),
            (0x2001_0DB8_1111_2222_0000_3333_4444_5555, "[2001:db8:1111:2222:0:3333:4444:5555]"),
            (0x2001_0000_0000_0000_0001_0000_0000_0002, "[2001::1:0:0:2]"),
            (0x2001_0000_0000_0001_0000_0000_0000_0002, "[2001:0:0:1::2]"),
            (0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001, "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]"),
            (0x2001_0DB8_0000_0000_0001_0000_0000_0002, "[2001:db8::1:0:0:2]"),
            (0x0000_0000_0000_0000_0000_0000_0000_0000, "[::]"),
            (0x2001_0000_0000_0001_0000_0000_0000_0000, "[2001:0:0:1::]"),
            (0x0000_0000_0000_0000_0001_0000_0000_0002, "[::1:0:0:2]"),
            (0x0000_0000_0001_0002_0003_0000_0004_0005, "[::1:2:3:0:4:5]"),
            (0x0000_0001_0002_0003_0004_0000_0005_0006, "[0:1:2:3:4:0:5:6]"),
        ]
    )
    func ipv6AddressDescription(ip: UInt128, expectedDescription: String) {
        #expect(IPv6Address(ip).description == expectedDescription)
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: ipv6StringAndAddressTestCases
            + ipv6IDNAStringAndAddressTestCases.map { ($0.0, nil, $0.2) }
    )
    func ipv6AddressFromString(
        string: String,
        expectedAddress: IPv6Address?,
        isValidIPv4: Bool
    ) {
        #expect(IPv6Address(string) == expectedAddress)
        #expect(IPv6Address(Substring(string)) == expectedAddress)
        #expect(IPv6Address(textualRepresentation: string.utf8Span) == expectedAddress)
        #expect(
            IPv6Address(textualRepresentation: string.utf8Span.span) == expectedAddress
        )

        if isValidIPv4 {
            #expect(IPAddress(string)?.isIPv4 == true)
            #expect(IPAddress(Substring(string))?.isIPv4 == true)
            #expect(IPAddress(textualRepresentation: string.utf8Span)?.isIPv4 == true)
            #expect(IPAddress(textualRepresentation: string.utf8Span.span)?.isIPv4 == true)
        } else {
            let expectedIPv6: IPAddress? = expectedAddress.map { .v6($0) }
            #expect(IPAddress(string) == expectedIPv6)
            #expect(IPAddress(Substring(string)) == expectedIPv6)
            #expect(IPAddress(textualRepresentation: string.utf8Span) == expectedIPv6)
            #expect(IPAddress(textualRepresentation: string.utf8Span.span) == expectedIPv6)
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: ipv6StringAndAddressTestCases
            + ipv6IDNAStringAndAddressTestCases
    )
    func ipv6AddressFromStringThroughDomainName(
        string: String,
        expectedAddress: IPv6Address?,
        isValidIPv4: Bool
    ) {
        let domainName = try? DomainName(string: string)

        let ipv6Address = domainName.flatMap { IPv6Address(domainName: $0) }

        if string == "::FFFF:204.152.189.116."
            || string == "::FFFF:1."
        {
            /// Manually skip these specific cases for now
            /// These are valid domain names, but invalid ipv6 addresses since they end in a dot
            #expect(ipv6Address != nil)
            return
        }

        #expect(ipv6Address == expectedAddress)

        let ipAddress = domainName.flatMap { IPAddress(domainName: $0) }
        switch ipAddress {
        case .v6(let ipv6):
            #expect(ipv6 == expectedAddress)
        case .none:
            #expect(expectedAddress == nil)
        case .v4:
            if !isValidIPv4 {
                Issue.record("Expected IPv6 but got: \(ipAddress)")
            }
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [
            (IPAddress.v4(IPv4Address(192, 168, 1, 1)), "v4(192.168.1.1)"),
            (
                IPAddress.v6(IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0100)),
                "v6([2001:db8:85a3::100])"
            ),
        ]
    )
    func ipAddressDescription(ip: IPAddress, expectedDescription: String) {
        #expect(ip.description == expectedDescription)
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: [(String, IPAddress?)]([
            ("192.168.1.1", .v4(IPv4Address(192, 168, 1, 1))),
            ("[192.168.1.256]", nil),
            ("[2001:0:0:1::]", .v6(IPv6Address(0x2001_0000_0000_0001_0000_0000_0000_0000))),
            ("[0:1:2:3:4:0:5:6::]", nil),
        ])
    )
    func ipAddressFromString(string: String, expectedAddress: IPAddress?) {
        #expect(IPAddress(string) == expectedAddress)
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: [(String, IPv4Address)]([
            ("::ffff:c000:0280", IPv4Address(192, 0, 2, 128)),
            ("::ffff:1234:5678", IPv4Address(18, 52, 86, 120)),
            ("::ffff:abcd:ef01", IPv4Address(171, 205, 239, 1)),
            ("::ffff:7f00:0001", IPv4Address(127, 0, 0, 1)),
        ])
    )
    func ipv6AddressFromIpv4Address(
        ipv6: String,
        expectedIPv4: IPv4Address
    ) throws {
        let ipv6 = try #require(IPv6Address(ipv6))
        #expect(ipv6 == IPv6Address(ipv4: expectedIPv4))
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: [(String, String, (@Sendable (IPv6Address) -> Bool))]([
            ("::1", "isLoopback", \.isLoopback),
            ("::1:1", "!isLoopback", { @Sendable in !$0.isLoopback }),
            ("FF00::", "isMulticast", \.isMulticast),
            ("FF92::", "isMulticast", \.isMulticast),
            ("FFFF:998A::1", "isMulticast", \.isMulticast),
            ("FF::", "!isMulticast", { @Sendable in !$0.isMulticast }),
            ("00FF::", "!isMulticast", { @Sendable in !$0.isMulticast }),
            ("FAFF::", "!isMulticast", { @Sendable in !$0.isMulticast }),
            ("FE80::", "isLinkLocalUnicast", \.isLinkLocalUnicast),
            ("FE90::", "isLinkLocalUnicast", \.isLinkLocalUnicast),
            ("FEBF::", "isLinkLocalUnicast", \.isLinkLocalUnicast),
            ("FEAA:9876:1928::9", "isLinkLocalUnicast", \.isLinkLocalUnicast),
            ("FE70::", "!isLinkLocalUnicast", { @Sendable in !$0.isLinkLocalUnicast }),
        ])
    )
    func ipv6AddressPropertiesWorkCorrectly(
        ip: String,
        testCaseDescription: String,
        predicate: @Sendable (IPv6Address) -> Bool
    ) throws {
        let ip = try #require(IPv6Address(ip))
        #expect(predicate(ip), "\(testCaseDescription)")
    }
}

/// (IPv4String, IPv4Address, isValidIPv6)
private let ipv4StringAndAddressTestCases: [(String, IPv4Address?, Bool)] = [
    ("127.0.0.1", IPv4Address(127, 0, 0, 1), false),
    ("0.0.0.0", IPv4Address(0, 0, 0, 0), false),
    ("0.0.0.1", IPv4Address(0, 0, 0, 1), false),
    ("0.0.1.0", IPv4Address(0, 0, 1, 0), false),
    ("0.1.0.0", IPv4Address(0, 1, 0, 0), false),
    ("1.0.0.0", IPv4Address(1, 0, 0, 0), false),
    ("1.1.1.1", IPv4Address(1, 1, 1, 1), false),
    ("123.251.98.234", IPv4Address(123, 251, 98, 234), false),
    ("255.255.255.255", IPv4Address(255, 255, 255, 255), false),
    ("192.168.1.98", IPv4Address(192, 168, 1, 98), false),
    ("192.168.1.256", nil, false),
    ("192.168.1.", nil, false),
    ("1111.168.1.1", nil, false),
    ("192.168.1.2.3", nil, false),
    ("192.168.1", nil, false),
    (".168.1.123", nil, false),
    ("168.1.123", nil, false),
    ("-1.168.1.123", nil, false),
    ("1.-168.1.123", nil, false),
    ("1.-168.1.0xaa", nil, false),
    ("1.-168.1.aa", nil, false),
    ("9", nil, false),
    ("9.87", nil, false),
    ("", nil, false),
    ("m.a.h.d", nil, false),
    ("m:a:h:d::", nil, false),
    ("1111:2222:3333:4444:5555:6666:7777:8888", nil, true),
]

/// (IPv4String, IPv4Address, isValidIPv6)
private let ipv4IDNAStringAndAddressTestCases: [(String, IPv4Address?, Bool)] = [
    /// These all should work based on IDNA.
    /// For example, the weird `1`s in the ip address below is:
    /// 2081          ; mapped     ; 0031          # 1.1  SUBSCRIPT ONE
    ///
    /// IDNA label separators other than U+002E ( . ) FULL STOP, are:
    /// U+FF0E ( ． ) FULLWIDTH FULL STOP
    /// U+3002 ( 。 ) IDEOGRAPHIC FULL STOP
    /// U+FF61 ( ｡ ) HALFWIDTH IDEOGRAPHIC FULL STOP
    ///
    /// Some ignored IDNA unicode scalars that are used below:
    /// U+00AD ( ­ ) SOFT HYPHEN
    /// U+200B ( ​ ) ZERO WIDTH SPACE
    /// U+2064 ( ⁤ ) INVISIBLE PLUS
    ///
    /// Would parse to 192.168.1.98 assuming IDNA-compliant parsing
    ("\u{AD}1\u{AD}92.₁₆\u{2064}\u{200B}\u{AD}₈.₁.98\u{AD}", IPv4Address(192, 168, 1, 98), false),
    /// Would parse to 192.168.1.98 assuming IDNA-compliant parsing
    ("192．168。1｡\u{AD}98", IPv4Address(192, 168, 1, 98), false),
    ("192.\u{AD}.166.9", nil, false),
]

/// (IPv6String, IPv6Address, isValidIPv4)
@available(swiftDNSApplePlatforms 15, *)
private let ipv6StringAndAddressTestCases: [(String, IPv6Address?, Bool)] = [
    ("1111:2222:3333:4444:5555:6666:7777:8888", 0x1111_2222_3333_4444_5555_6666_7777_8888, false),
    ("[FF::]", 0x00FF_0000_0000_0000_0000_0000_0000_0000, false),
    ("[::FF]", 0x0000_0000_0000_0000_0000_0000_0000_00FF, false),
    ("[0:FF::]", 0x0000_00FF_0000_0000_0000_0000_0000_0000, false),
    ("[2001:db8:85a3::100]", 0x2001_0DB8_85A3_0000_0000_0000_0000_0100, false),
    ("2001:db8:85a3::100", 0x2001_0DB8_85A3_0000_0000_0000_0000_0100, false),
    ("[2001:db8::1:0:0:2]", 0x2001_0DB8_0000_0000_0001_0000_0000_0002, false),
    ("[2001:db8:1111:2222:3333:4444::]", 0x2001_0DB8_1111_2222_3333_4444_0000_0000, false),
    ("[2001:db8:1111:2222:3333:4444:5555:6666]", 0x2001_0DB8_1111_2222_3333_4444_5555_6666, false),
    ("[2001:db8:1111:2222:0:3333:4444:5555]", 0x2001_0DB8_1111_2222_0000_3333_4444_5555, false),
    ("[2001::1:0:0:2]", 0x2001_0000_0000_0000_0001_0000_0000_0002, false),
    ("2001::1:0:0:2", 0x2001_0000_0000_0000_0001_0000_0000_0002, false),
    ("[2001:0:0:1::2]", 0x2001_0000_0000_0001_0000_0000_0000_0002, false),
    ("[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]", 0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001, false),
    ("2001:db8:aaaa:bbbb:cccc:dddd:eeee:1", 0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001, false),
    ("01:db8:a0a:bb:cc0:0dd0:ee:1", 0x0001_0DB8_0A0A_00BB_0CC0_0DD0_00EE_0001, false),
    ("[2001:db8::1:0:0:2]", 0x2001_0DB8_0000_0000_0001_0000_0000_0002, false),
    ("[::]", 0x0000_0000_0000_0000_0000_0000_0000_0000, false),
    ("::", 0x0000_0000_0000_0000_0000_0000_0000_0000, false),
    ("[2001:0:0:1::]", 0x2001_0000_0000_0001_0000_0000_0000_0000, false),
    ("[::1:0:0:2]", 0x0000_0000_0000_0000_0001_0000_0000_0002, false),
    ("[::1:2:3:0:4:5]", 0x0000_0000_0001_0002_0003_0000_0004_0005, false),
    ("[0:1:2:3:4:0:5:6]", 0x0000_0001_0002_0003_0004_0000_0005_0006, false),
    ("[0:1:2:3:4:0:5:f]", 0x0000_0001_0002_0003_0004_0000_0005_000F, false),
    ("0:1:2:3:4:0:5:6", 0x0000_0001_0002_0003_0004_0000_0005_0006, false),
    ("[::1]", 0x0000_0000_0000_0000_0000_0000_0000_0001, false),
    ("::1", 0x0000_0000_0000_0000_0000_0000_0000_0001, false),
    ("::FFFF:204.152.189.116", 0x0000_0000_0000_0000_0000_FFFF_CC98_BD74, false),
    ("::FFFF:255.255.255.255", 0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF, false),
    ("::FFFF:1.1.1.1", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("[::FFFF:1.1.1.1]", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("0:0:0:0:0:FFFF:204.152.189.116", 0x0000_0000_0000_0000_0000_FFFF_CC98_BD74, false),
    ("0:0:0:0:0:FFFF:255.255.255.255", 0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF, false),
    (
        "[0000:0000:0000:0000:0000:FFFF:255.255.255.255]",
        0x0000_0000_0000_0000_0000_FFFF_FFFF_FFFF, false
    ),
    ("0:0:0:0:0:FFFF:1.1.1.1", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("0::0:FFFF:1.1.1.1", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("0:0::0:FFFF:1.1.1.1", 0x0000_0000_0000_0000_0000_FFFF_0101_0101, false),
    ("0:0:0:0:0:0:FFFF:1.1.1.1", nil, false),
    ("0:0:1:0:0:FFFF:204.152.189.116", nil, false),
    ("0:0:0:0:FFFF:1.1.1.1:FFFF", nil, false),
    ("0:0:0:0:0:1.1.1.1:FFFF", nil, false),
    ("::FFFF:1.1.1.1:FFFF", nil, false),
    ("::1.1.1.1:FFFF", nil, false),
    (":FFFF:1.1.1.1", nil, false),
    ("::FFFF:1.", nil, false),
    ("::FFFF:1.1", nil, false),
    ("::FFFF:1.1.", nil, false),
    ("::FFFF:1.1.1", nil, false),
    ("::FFFF:1.1.1.", nil, false),
    ("::1.1.1.1", nil, false),
    ("::FFFF:256.152.189.116", nil, false),
    ("[0000:0000:0000:0000:0000:FFFF:255.255.255.1111]", nil, false),
    ("::FFFF:204.152.189.116.", nil, false),
    ("::FFFF:.204.152.189.116", nil, false),
    ("::FFFF::204.152.189.116", nil, false),
    ("::FFFF:204.152.189", nil, false),
    ("::FFFF:204.152.189.", nil, false),
    ("::FFFF:.204.152.189", nil, false),
    ("", nil, false),
    (":", nil, false),
    ("[:]", nil, false),
    (":::", nil, false),
    ("[:::]", nil, false),
    ("[2001:0:0:1:::]", nil, false),
    ("[:::2001:0:0:1]", nil, false),
    ("[2001:0:0:1::2", nil, false),
    ("2001:0:0:1::2]", nil, false),
    ("[1::2::]", nil, false),
    ("[1::2::3]", nil, false),
    ("[:0:1:2:3:4:0:5:6]", nil, false),
    ("[0:1:2:3:4:0:5:6:]", nil, false),
    ("[0:1:2:3:4:0:5:6:]", nil, false),
    ("[::0:1:2:3:4:5:6:7]", nil, false),
    ("[0:1:2:3:4:5:6:7::]", nil, false),
    ("[0:1:2:3:4:0:5]", nil, false),
    ("[1:2:3:4:5:6:7]", nil, false),
    ("[1:2:3:4:5:6:7:8:9]", nil, false),
    ("[1:2:3]", nil, false),
    ("[1:2:3:]", nil, false),
    ("[:1:2:3]", nil, false),
    ("[0:1:2:3:4:0:5:6:7]", nil, false),
    ("[0:1:2:3:4:0:5:-6]", nil, false),
    ("[0:1:2:3:4:0:5:g]", nil, false),
    ("[0:11111:2:3:4:0:5:6]", nil, false),
    ("[0:11111::]", nil, false),
    ("[::11111:0]", nil, false),
    ("[11111::]", nil, false),
    ("[::11111]", nil, false),
    ("m.a.h.d", nil, false),
    ("m:a:h:d::", nil, false),
    ("192.168.1.255", nil, true),
]

/// (IPv6String, IPv6Address, isValidIPv4)
@available(swiftDNSApplePlatforms 15, *)
private let ipv6IDNAStringAndAddressTestCases: [(String, IPv6Address?, Bool)] = [
    /// Contains weird characters that are mapped to the correct characters in IDNA
    /// These all should work based on IDNA.
    /// For example, the weird `1`s in the ip address below is:
    /// 2081          ; mapped     ; 0031          # 1.1  SUBSCRIPT ONE
    ///
    /// Some ignored IDNA unicode scalars that are used below:
    /// U+00AD ( ­ ) SOFT HYPHEN
    /// U+200B ( ​ ) ZERO WIDTH SPACE
    /// U+2064 ( ⁤ ) INVISIBLE PLUS
    ///
    /// Would parse to 1111:2222:3333:4444:5555:6666:7777:8888 assuming IDNA-compliant parsing
    ("₁₁₁₁:2222:3333:4444:5555:₆6₆6:7777:8888", 0x1111_2222_3333_4444_5555_6666_7777_8888, false),
    /// Would parse to 1111:2222:3333:4444:5555:6666:7777:8888 assuming IDNA-compliant parsing
    (
        "\u{AD}1\u{AD}111:2222︓\u{AD}3333:4444︓55\u{200B}\u{2064}55:₆6₆6:7777:8888\u{200B}",
        0x1111_2222_3333_4444_5555_6666_7777_8888,
        false
    ),
    /// Would parse to 2001:0DB8:85A3:F109:197A:8A2E:0370:7334 assuming IDNA-compliant parsing
    (
        "\u{200B}﹇₂₀\u{AD}\u{200B}₀₁︓\u{2064}₀ⒹⒷ₈︓₈₅Ⓐ₃\u{2064}︓Ⓕ₁₀₉︓₁₉₇Ⓐ︓₈Ⓐ₂Ⓔ︓₀₃₇₀︓₇₃₃₄﹈\u{2064}",
        0x2001_0DB8_85A3_F109_197A_8A2E_0370_7334,
        false
    ),
    ("\u{AD}", nil, false),
    ("\u{AD}\u{200B}\u{2064}", nil, false),
    ("[\u{AD}]", nil, false),
    ("[\u{AD}\u{200B}\u{2064}]", nil, false),
    /// We should support parsing these next 4 as valid if we were to support IDNA-compliant parsing,
    /// but we can skip them if necessary for performance.
    /// If you remove the IDNA-ignored unicode scalars, it becomes clear they are valid.
    ("[\u{AD}::]", 0x0000_0000_0000_0000_0000_0000_0000_0000, false),
    ("[::\u{AD}]", 0x0000_0000_0000_0000_0000_0000_0000_0000, false),
    ("[1:\u{AD}:1]", 0x0001_0000_0000_0000_0000_0000_0000_0001, false),
    ("[1:\u{AD}\u{200B}:1]", 0x0001_0000_0000_0000_0000_0000_0000_0001, false),
]
