import DNSModels
import Testing

@Suite
struct DNSTests {
    @available(swiftDNSApplePlatforms 26, *)
    @Test func testTSIGAlgorithmConversions() throws {
        for algorithm in TSIG.Algorithm.allCases {
            let name = try algorithm.toName()
            let recalculatedAlgorithm = TSIG.Algorithm(name: name)
            #expect(algorithm == recalculatedAlgorithm)
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test func testTSIGAlgorithmEqualityLooksAtInnerValueToo() throws {
        for algorithm in TSIG.Algorithm.allCases {
            #expect(algorithm == algorithm)
        }

        #expect(
            TSIG.Algorithm.HMAC_SHA256_128 != TSIG.Algorithm.HMAC_SHA512
        )

        /// Check the equality looks at inner value too instead of just the enum case
        for algorithm in TSIG.Algorithm.allCases {
            #expect(algorithm == TSIG.Algorithm.unknown(try algorithm.toName()))
        }

        #expect(
            TSIG.Algorithm.unknown(
                try TSIG.Algorithm.HMAC_MD5.toName()
            ) != TSIG.Algorithm.HMAC_SHA1
        )
    }
}
