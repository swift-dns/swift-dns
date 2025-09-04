import DNSModels
import Testing

@Suite
struct CIDRTests {
    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [(cidr: CIDR<IPv4Address>, expectedDescription: String)]([
            (
                cidr: CIDR(prefix: IPv4Address(1, 43, 255, 199), countOfMaskedBits: 8),
                expectedDescription: "1.0.0.0/8"
            ),
            (
                cidr: CIDR(prefix: IPv4Address(244, 89, 123, 0), countOfMaskedBits: 24),
                expectedDescription: "244.89.123.0/24"
            ),
            (
                cidr: CIDR(prefix: IPv4Address(0, 0, 0, 0), countOfMaskedBits: 0),
                expectedDescription: "0.0.0.0/0"
            ),
            (
                cidr: CIDR(prefix: IPv4Address(255, 255, 255, 255), countOfMaskedBits: 32),
                expectedDescription: "255.255.255.255/32"
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), countOfMaskedBits: 24),
                expectedDescription: "192.168.1.0/24"
            ),
        ])
    ) func `ipv4 CIDR description is calculated correctly`(
        cidr: CIDR<IPv4Address>,
        expectedDescription: String
    ) {
        #expect(cidr.description == expectedDescription)
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [(cidr: CIDR<IPv4Address>, containsIP: IPv4Address, result: Bool)]([
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), countOfMaskedBits: 24),
                containsIP: IPv4Address(192, 168, 1, 0),
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), countOfMaskedBits: 24),
                containsIP: IPv4Address(192, 168, 1, 1),
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), countOfMaskedBits: 24),
                containsIP: IPv4Address(192, 168, 1, 255),
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), countOfMaskedBits: 24),
                containsIP: IPv4Address(192, 168, 1, 254),
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), countOfMaskedBits: 24),
                containsIP: IPv4Address(192, 168, 2, 123),
                result: false
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), countOfMaskedBits: 24),
                containsIP: IPv4Address(192, 168, 0, 123),
                result: false
            ),
            (
                cidr: CIDR(prefix: IPv4Address(192, 168, 1, 0), countOfMaskedBits: 24),
                containsIP: IPv4Address(192, 168, 255, 123),
                result: false
            ),
        ])
    )
    func `ipv4 CIDR containment check works as expected`(
        cidr: CIDR<IPv4Address>,
        containsIP: IPv4Address,
        result: Bool
    ) {
        #expect(
            cidr.contains(containsIP) == result,
            """
            IPv4Address containment check failed. A containment result of '\(result)' was expected.
            mask:    0b\(String(cidr.mask, radix: 2)); \(cidr.mask.trailingZeroBitCount) trailing zeros
            prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
            """
        )
        #expect(
            cidr.contains(IPAddress.v4(containsIP)) == result,
            """
            IPAddress.v4 containment check failed. A containment result of '\(result)' was expected.
            mask:    0b\(String(cidr.mask, radix: 2)); \(cidr.mask.trailingZeroBitCount) trailing zeros
            prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `randomly generated ipv4 CIDR containment checks work as expected`() {
        for (cidr, containsIP, result) in Self.makeRandom(
            ofType: IPv4Address.self,
            countForEachBit: 100
        ) {
            #expect(
                cidr.contains(containsIP) == result,
                """
                IPv4Address containment check failed. A containment result of '\(result)' was expected.
                mask:    0b\(String(cidr.mask, radix: 2)); \(cidr.mask.trailingZeroBitCount) trailing zeros
                prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
                checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
                """
            )
            #expect(
                cidr.contains(IPAddress.v4(containsIP)) == result,
                """
                IPAddress.v4 containment check failed. A containment result of '\(result)' was expected.
                mask:    0b\(String(cidr.mask, radix: 2)); \(cidr.mask.trailingZeroBitCount) trailing zeros
                prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
                checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
                """
            )
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
        arguments: [(cidr: CIDR<IPv6Address>, expectedDescription: String)]([
            (
                cidr: CIDR(
                    prefix: IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0100),
                    countOfMaskedBits: 24
                ),
                expectedDescription: "[2001:d00::]/24"
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, countOfMaskedBits: 8),
                expectedDescription: "[ff00::]/8"
            ),
            (
                cidr: CIDR(prefix: 0x0, countOfMaskedBits: 0),
                expectedDescription: "[::]/0"
            ),
            (
                cidr: CIDR(prefix: IPv6Address(UInt128.max), countOfMaskedBits: 128),
                expectedDescription: "[ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff]/128"
            ),
            (
                cidr: CIDR(
                    prefix: IPv6Address(0x2001_0DB8_85A3_0000_0000_0000_0000_0000),
                    countOfMaskedBits: 48
                ),
                expectedDescription: "[2001:db8:85a3::]/48"
            ),
        ])
    ) func `ipv6 CIDR description is calculated correctly`(
        cidr: CIDR<IPv6Address>,
        expectedDescription: String
    ) {
        #expect(cidr.description == expectedDescription)
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        arguments: [(cidr: CIDR<IPv6Address>, containsIP: IPv6Address, result: Bool)]([
            (
                /// `FF::` is equivalent to `00FF::`
                cidr: CIDR(prefix: IPv6Address("FF::")!, countOfMaskedBits: 8),
                containsIP: IPv6Address("FF00::")!,
                result: false
            ),
            (
                /// `FF::` is equivalent to `00FF::`
                cidr: CIDR(prefix: IPv6Address("FF::")!, countOfMaskedBits: 16),
                containsIP: IPv6Address("FF::")!,
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, countOfMaskedBits: 8),
                containsIP: IPv6Address("FF92::")!,
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, countOfMaskedBits: 8),
                containsIP: IPv6Address("FFEE:9328:3212:0:1::")!,
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, countOfMaskedBits: 8),
                containsIP: IPv6Address("FF00:9328:3212:0:1::")!,
                result: true
            ),
            (
                cidr: CIDR(prefix: IPv6Address("FF00::")!, countOfMaskedBits: 8),
                containsIP: IPv6Address("EEFF:9328:3212:0:1::")!,
                result: false
            ),
        ])
    )
    func `ipv6 CIDR containment check works as expected`(
        cidr: CIDR<IPv6Address>,
        containsIP: IPv6Address,
        result: Bool
    ) {
        #expect(
            cidr.contains(containsIP) == result,
            """
            IPv6Address containment check failed. A containment result of '\(result)' was expected.
            mask:    0b\(String(cidr.mask, radix: 2)); \(cidr.mask.trailingZeroBitCount) trailing zeros
            prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
            """
        )
        #expect(
            cidr.contains(IPAddress.v6(containsIP)) == result,
            """
            IPAddress.v6 containment check failed. A containment result of '\(result)' was expected.
            mask:    0b\(String(cidr.mask, radix: 2)); \(cidr.mask.trailingZeroBitCount) trailing zeros
            prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
            checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
            """
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `randomly generated ipv6 CIDR containment checks work as expected`() {
        for (cidr, containsIP, result) in Self.makeRandom(
            ofType: IPv6Address.self,
            countForEachBit: 15
        ) {
            #expect(
                cidr.contains(containsIP) == result,
                """
                IPv6Address containment check failed. A containment result of '\(result)' was expected.
                mask:    0b\(String(cidr.mask, radix: 2)); \(cidr.mask.trailingZeroBitCount) trailing zeros
                prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
                checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
                """
            )
            #expect(
                cidr.contains(IPAddress.v6(containsIP)) == result,
                """
                IPAddress.v6 containment check failed. A containment result of '\(result)' was expected.
                mask:    0b\(String(cidr.mask, radix: 2)); \(cidr.mask.trailingZeroBitCount) trailing zeros
                prefix:  0b\(String(cidr.prefix.address, radix: 2)); \(cidr.prefix.address.trailingZeroBitCount) trailing zeros
                checked: 0b\(String(containsIP.address, radix: 2)); \(containsIP.address.trailingZeroBitCount) trailing zeros
                """
            )
        }
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
            ),
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

    @available(swiftDNSApplePlatforms 15, *)
    /// We intentionally don't use much math operators here like bit-shift, to keep things
    /// simpler for tests.
    static func makeRandom<IPAddressType: _IPAddressProtocol>(
        ofType: IPAddressType.Type,
        countForEachBit: Int
    ) -> [(cidr: CIDR<IPAddressType>, containsIP: IPAddressType, result: Bool)] {
        let bitWidth = UInt8(IPAddressType.IntegerLiteralType.bitWidth)
        var results: [(cidr: CIDR<IPAddressType>, containsIP: IPAddressType, result: Bool)] = []
        results.reserveCapacity((Int(bitWidth) + 1) * 2 * countForEachBit)

        for bitCount in UInt8(0)...bitWidth {
            let cidr = CIDR(
                prefix: IPAddressType(integerLiteral: .random(in: .all)),
                countOfMaskedBits: bitCount
            )

            var cidrPrefixBits = String(cidr.prefix.address, radix: 2)
            let remainingBits = Int(bitWidth) - cidrPrefixBits.count
            cidrPrefixBits = String(repeating: "0", count: remainingBits) + cidrPrefixBits
            let matchingBits = cidrPrefixBits.prefix(Int(bitCount))

            for _ in (0..<countForEachBit) {
                let theRest = (0..<(bitWidth - bitCount)).map { _ in
                    "\(UInt8.random(in: 0...1))"
                }
                let number = IPAddressType.IntegerLiteralType(
                    matchingBits + theRest.joined(separator: ""),
                    radix: 2
                )!
                results.append((cidr, IPAddressType(integerLiteral: number), true))
            }

            guard bitCount > 0 else {
                continue
            }

            for _ in (0..<countForEachBit) {
                var messedUpBits = Array(matchingBits)
                let howManyToMessUp = Int.random(in: 1...matchingBits.count)
                let indicesToMessUp = messedUpBits.indices.shuffled().prefix(howManyToMessUp)
                for index in indicesToMessUp {
                    let toggled: Character = messedUpBits[index] == "1" ? "0" : "1"
                    messedUpBits[index] = toggled
                }
                let theRest = (0..<(bitWidth - bitCount)).map { _ in
                    "\(UInt8.random(in: 0...1))"
                }
                let number = IPAddressType.IntegerLiteralType(
                    messedUpBits + theRest.joined(separator: ""),
                    radix: 2
                )!
                results.append((cidr, IPAddressType(integerLiteral: number), false))
            }
        }

        return results
    }
}

extension ClosedRange where Bound: FixedWidthInteger {
    fileprivate static var all: Self {
        Bound.min...Bound.max
    }
}
