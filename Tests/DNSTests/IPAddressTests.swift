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
            (IPv4Address(0, 0, 0, 0), "0.0.0.0"),
            (IPv4Address(0, 0, 0, 1), "0.0.0.1"),
            (IPv4Address(0, 0, 1, 0), "0.0.1.0"),
            (IPv4Address(0, 1, 0, 0), "0.1.0.0"),
            (IPv4Address(1, 0, 0, 0), "1.0.0.0"),
            (IPv4Address(1, 1, 1, 1), "1.1.1.1"),
            (IPv4Address(255, 255, 255, 255), "255.255.255.255"),
            (IPv4Address(192, 168, 1, 98), "192.168.1.98"),
        ]
    )
    func ipv4AddressDescription(ip: IPv4Address, expectedDescription: String) {
        #expect(ip.description == expectedDescription)
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
            (0x2001_0DB8_85A3_0000_0000_0000_0000_0100, "[2001:db8:85a3::100]"),
            (0x2001_0DB8_0000_0000_0001_0000_0000_0001, "[2001:db8::1:0:0:1]"),
            (0x2001_0000_0000_0000_0001_0000_0000_0001, "[2001::1:0:0:1]"),
            (0x2001_0000_0000_0001_0000_0000_0000_0001, "[2001:0:0:1::1]"),
            (0x2001_0DB8_AAAA_BBBB_CCCC_DDDD_EEEE_0001, "[2001:db8:aaaa:bbbb:cccc:dddd:eeee:1]"),
            (0x2001_0DB8_0000_0000_0001_0000_0000_0001, "[2001:db8::1:0:0:1]"),
            (0x0000_0000_0000_0000_0000_0000_0000_0000, "[::]"),
            (0x2001_0000_0000_0001_0000_0000_0000_0000, "[2001:0:0:1::]"),
            (0x0000_0000_0000_0000_0001_0000_0000_0001, "[::1:0:0:1]"),
        ]
    )
    func ipv6AddressDescription(ip: UInt128, expectedDescription: String) {
        #expect(IPv6Address(ip).description == expectedDescription)
    }
}
