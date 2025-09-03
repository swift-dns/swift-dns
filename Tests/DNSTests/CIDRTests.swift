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

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [(countOfMaskedBits: UInt8, ip: IPv4Address, expectedIP: IPv4Address)]([
            (
                countOfMaskedBits: 0 as UInt8,
                ip: 0b00000000_00000000_00000000_00000000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                countOfMaskedBits: 0 as UInt8,
                ip: 0b10000000_00000000_00000000_00000000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                countOfMaskedBits: 0 as UInt8,
                ip: 0b10000000_00001000_00000000_00100000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                countOfMaskedBits: 1 as UInt8,
                ip: 0b00000000_00001000_00000000_00100000,
                expectedIP: 0b00000000_00000000_00000000_00000000
            ),
            (
                countOfMaskedBits: 1 as UInt8,
                ip: 0b10000000_00000000_00000000_00000000,
                expectedIP: 0b10000000_00000000_00000000_00000000
            ),
            (
                countOfMaskedBits: 1 as UInt8,
                ip: 0b11000000_00000000_00000000_00000000,
                expectedIP: 0b10000000_00000000_00000000_00000000
            ),
            (
                countOfMaskedBits: 9 as UInt8,
                ip: 0b1111111_10000000_00000000_00000000,
                expectedIP: 0b1111111_10000000_00000000_00000000
            ),
            (
                countOfMaskedBits: 9 as UInt8,
                ip: 0b1111111_10001000_00010010_00000001,
                expectedIP: 0b1111111_10000000_00000000_00000000
            ),
            (
                countOfMaskedBits: 24 as UInt8,
                ip: 0b1111111_11111111_11111111_00000000,
                expectedIP: 0b1111111_11111111_11111111_00000000
            ),
            (
                countOfMaskedBits: 24 as UInt8,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_00000000
            ),
            (
                countOfMaskedBits: 25 as UInt8,
                ip: 0b1111111_11111111_11111111_11111000,
                expectedIP: 0b1111111_11111111_11111111_10000000
            ),
            (
                countOfMaskedBits: 30 as UInt8,
                ip: 0b1111111_11111111_11111111_11111101,
                expectedIP: 0b1111111_11111111_11111111_11111100
            ),
            (
                countOfMaskedBits: 31 as UInt8,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_11111110
            ),
            (
                countOfMaskedBits: 32 as UInt8,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_11111111
            ),
            (
                countOfMaskedBits: 33 as UInt8,
                ip: 0b1111111_11111111_11111111_11111111,
                expectedIP: 0b1111111_11111111_11111111_11111111
            ),
        ])
    ) func `ipv4 CIDR standard initializer truncates prefix if needed`(
        countOfMaskedBits: UInt8,
        ip: IPv4Address,
        expectedIP: IPv4Address
    ) {
        let cidr = CIDR(
            prefix: ip,
            countOfMaskedBits: countOfMaskedBits
        )
        #expect(
            cidr.prefix == expectedIP,
            """
            countOfMaskedBits: \(countOfMaskedBits)
            prefix:   0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            expected: 0b\(String(expectedIP.address, radix: 2)); \(expectedIP.address.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [(countOfMaskedBits: UInt8, expectedMask: UInt32)]([
            (0 as UInt8, 0b00000000_00000000_00000000_00000000 as UInt32),
            (1 as UInt8, 0b10000000_00000000_00000000_00000000 as UInt32),
            (2 as UInt8, 0b11000000_00000000_00000000_00000000 as UInt32),
            (3 as UInt8, 0b11100000_00000000_00000000_00000000 as UInt32),
            (19 as UInt8, 0b11111111_11111111_11100000_00000000 as UInt32),
            (20 as UInt8, 0b11111111_11111111_11110000_00000000 as UInt32),
            (27 as UInt8, 0b11111111_11111111_11111111_11100000 as UInt32),
            (30 as UInt8, 0b11111111_11111111_11111111_11111100 as UInt32),
            (31 as UInt8, 0b11111111_11111111_11111111_11111110 as UInt32),
            (32 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (33 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (34 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (50 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (150 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
            (255 as UInt8, 0b11111111_11111111_11111111_11111111 as UInt32),
        ])
    )
    func `ipv4 mask is correctly calculated when using countOfMaskedBits`(
        countOfMaskedBits: UInt8,
        expectedMask: UInt32
    ) {
        let calculatedMask = CIDR<IPv4Address>.makeMaskBasedOn(
            countOfMaskedBits: countOfMaskedBits
        )
        #expect(
            calculatedMask == expectedMask,
            """
            countOfMaskedBits: \(countOfMaskedBits)
            calculated: 0b\(String(calculatedMask, radix: 2)); \(calculatedMask.trailingZeroBitCount) trailing zeros
            expected:   0b\(String(expectedMask, radix: 2)); \(expectedMask.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [(countOfMaskedBits: UInt8, ip: IPv6Address, expectedIP: IPv6Address)]([
            (
                countOfMaskedBits: 0 as UInt8,
                ip: IPv6Address(0b00000000_00000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
            ),
            (
                countOfMaskedBits: 0 as UInt8,
                ip: IPv6Address(0b10000000_00000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
            ),
            (
                countOfMaskedBits: 0 as UInt8,
                ip: IPv6Address(0b10000000_00001000_00000000_00100000 << 96),
                expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
            ),
            (
                countOfMaskedBits: 1 as UInt8,
                ip: IPv6Address(0b00000000_00001000_00000000_00100000 << 96),
                expectedIP: IPv6Address(0b00000000_00000000_00000000_00000000 << 96)
            ),
            (
                countOfMaskedBits: 1 as UInt8,
                ip: IPv6Address(0b10000000_00000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b10000000_00000000_00000000_00000000 << 96)
            ),
            (
                countOfMaskedBits: 1 as UInt8,
                ip: IPv6Address(0b11000000_00000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b10000000_00000000_00000000_00000000 << 96)
            ),
            (
                countOfMaskedBits: 9 as UInt8,
                ip: IPv6Address(0b1111111_10000000_00000000_00000000 << 96),
                expectedIP: IPv6Address(0b1111111_10000000_00000000_00000000 << 96)
            ),
            (
                countOfMaskedBits: 9 as UInt8,
                ip: IPv6Address(0b1111111_10001000_00010010_00000001 << 96),
                expectedIP: IPv6Address(0b1111111_10000000_00000000_00000000 << 96)
            ),
            (
                countOfMaskedBits: 24 as UInt8,
                ip: IPv6Address(0b1111111_11111111_11111111_00000000 << 96),
                expectedIP: IPv6Address(0b1111111_11111111_11111111_00000000 << 96)
            ),
            (
                countOfMaskedBits: 24 as UInt8,
                ip: IPv6Address(0b1111111_11111111_11111111_11111111 << 96),
                expectedIP: IPv6Address(0b1111111_11111111_11111111_00000000 << 96)
            ),
            (
                countOfMaskedBits: 25 as UInt8,
                ip: IPv6Address(0b1111111_11111111_11111111_11111000 << 96),
                expectedIP: IPv6Address(0b1111111_11111111_11111111_10000000 << 96)
            ),
            (
                countOfMaskedBits: 120 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_01000100
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
                )
            ),
            (
                countOfMaskedBits: 120 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
                )
            ),
            (
                countOfMaskedBits: 120 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_00000000
                )
            ),
            (
                countOfMaskedBits: 126 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
                )
            ),
            (
                countOfMaskedBits: 126 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111101
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
                )
            ),
            (
                countOfMaskedBits: 126 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111100
                )
            ),
            (
                countOfMaskedBits: 127 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                )
            ),
            (
                countOfMaskedBits: 127 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                )
            ),
            (
                countOfMaskedBits: 128 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                )
            ),
            (
                countOfMaskedBits: 129 as UInt8,
                ip: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                ),
                expectedIP: IPv6Address(
                    0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                )
            )
        ])
    ) func `ipv6 CIDR standard initializer truncates prefix if needed`(
        countOfMaskedBits: UInt8,
        ip: IPv6Address,
        expectedIP: IPv6Address
    ) {
        let cidr = CIDR(
            prefix: ip,
            countOfMaskedBits: countOfMaskedBits
        )
        #expect(
            cidr.prefix == expectedIP,
            """
            countOfMaskedBits: \(countOfMaskedBits)
            prefix:   0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            expected: 0b\(String(expectedIP.address, radix: 2)); \(expectedIP.address.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [(countOfMaskedBits: UInt8, expectedMask: UInt128)]([
            (0 as UInt8, (0b0 << 128) as UInt128),
            (1 as UInt8, (0b1 << 127) as UInt128),
            (2 as UInt8, (0b11 << 126) as UInt128),
            (3 as UInt8, (0b111 << 125) as UInt128),
            (19 as UInt8, (0b11111111_11111111_111 << 109) as UInt128),
            (20 as UInt8, (0b11111111_11111111_1111 << 108) as UInt128),
            (27 as UInt8, (0b11111111_11111111_11111111_111 << 101) as UInt128),
            (28 as UInt8, (0b11111111_11111111_11111111_1111 << 100) as UInt128),
            (29 as UInt8, (0b11111111_11111111_11111111_11111 << 99) as UInt128),
            (30 as UInt8, (0b11111111_11111111_11111111_111111 << 98) as UInt128),
            (31 as UInt8, (0b11111111_11111111_11111111_1111111 << 97) as UInt128),
            (32 as UInt8, (0b11111111_11111111_11111111_11111111 << 96) as UInt128),
            (33 as UInt8, (0b11111111_11111111_11111111_11111111_1 << 95) as UInt128),
            (34 as UInt8, (0b11111111_11111111_11111111_11111111_11 << 94) as UInt128),
            (
                50 as UInt8,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11 << 78) as UInt128
            ),
            (
                99 as UInt8,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_111
                    << 29) as UInt128
            ),
            (
                100 as UInt8,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_1111
                    << 28) as UInt128
            ),
            (
                101 as UInt8,
                (0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111
                    << 27) as UInt128
            ),
            (
                127 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111110
                    as UInt128
            ),
            (
                128 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                129 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                150 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
            (
                255 as UInt8,
                0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
                    as UInt128
            ),
        ])
    )
    func `ipv6 mask is correctly calculated when using countOfMaskedBits`(
        countOfMaskedBits: UInt8,
        expectedMask: UInt128
    ) {
        let calculatedMask = CIDR<IPv6Address>.makeMaskBasedOn(
            countOfMaskedBits: countOfMaskedBits
        )
        #expect(
            calculatedMask == expectedMask,
            """
            countOfMaskedBits: \(countOfMaskedBits)
            calculated: 0b\(String(calculatedMask, radix: 2)); \(calculatedMask.trailingZeroBitCount) trailing zeros
            expected:   0b\(String(expectedMask, radix: 2)); \(expectedMask.trailingZeroBitCount) trailing zeros
            """
        )
    }
}
