import DNSModels
import Testing

@Suite
struct CIDRTests {
    @available(swiftDNSApplePlatforms 15, *)
    @Test func testCIDR() {
        let cidr = CIDR(
            prefix: IPv4Address(192, 168, 1, 0),
            countOfMaskedBits: 24
        )
        #expect(cidr.prefix == IPv4Address(192, 168, 1, 0))
        #expect(cidr.mask == 0b11111111_11111111_11111111_00000000)
        for number in UInt8(0)...UInt8(255) {
            #expect(cidr.contains(IPv4Address(192, 168, 1, number)))
        }
    }
}
