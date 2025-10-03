import DNSModels
import Testing

@Suite
struct DNSTests {
    @Test
    func testTSIGAlgorithmConversions() throws {
        for algorithm in TSIG.Algorithm.allCases {
            let domainName = try algorithm.toDomainName()
            let recalculatedAlgorithm = TSIG.Algorithm(domainName: domainName)
            #expect(algorithm == recalculatedAlgorithm)
        }
    }

    @Test
    func testTSIGAlgorithmEqualityLooksAtInnerValueToo() throws {
        for algorithm in TSIG.Algorithm.allCases {
            #expect(algorithm == algorithm)
        }

        #expect(
            TSIG.Algorithm.HMAC_SHA256_128 != TSIG.Algorithm.HMAC_SHA512
        )

        /// Check the equality looks at inner value too instead of just the enum case
        for algorithm in TSIG.Algorithm.allCases {
            #expect(algorithm == TSIG.Algorithm.unknown(try algorithm.toDomainName()))
        }

        #expect(
            TSIG.Algorithm.unknown(
                try TSIG.Algorithm.HMAC_MD5.toDomainName()
            ) != TSIG.Algorithm.HMAC_SHA1
        )
    }
}
