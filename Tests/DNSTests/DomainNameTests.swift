import DNSCore
import DNSModels
import NIOCore
import Testing

@Suite
struct DomainNameTests {
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
        #expect(domainName._data.readableBytesView.last != 0)
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
        #expect(domainName._data.readableBytesView.last != 0)
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
}
