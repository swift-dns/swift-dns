import DNSModels
import NIOCore
import Testing

@Suite
struct DNSTests {
    @Test func encodeAExampleComQuery() async throws {
        let query = Query(
            name: try Name(string: "example.com"),
            queryType: .A,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0x67ed,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryAExampleComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeAExampleComResponse() async throws {
        var buffer = Resources.dnsResponseAExampleComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0x67ed)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 6)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == false)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "example.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .A)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 6)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .A }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.ttl == 130 }, "\(response.answers)")
        let ipv4s = response.answers.compactMap {
            switch $0.rdata {
            case .A(let a):
                return a.value
            default:
                Issue.record("rdata was not of type A: \($0.rdata)")
                return nil
            }
        }
        let expectedIPv4s = [
            IPv4Address(bytes: [23, 215, 0, 136]),
            IPv4Address(bytes: [96, 7, 128, 198]),
            IPv4Address(bytes: [23, 192, 228, 80]),
            IPv4Address(bytes: [23, 215, 0, 138]),
            IPv4Address(bytes: [23, 192, 228, 84]),
            IPv4Address(bytes: [96, 7, 128, 175]),
        ]
        #expect(ipv4s == expectedIPv4s)

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 130)
        #expect(edns.maxPayload == 1232)
        #expect(edns.options.options.count == 1)
        let option = try #require(edns.options.options.first)
        #expect(option.0 == .padding)
        #expect(option.1 == .unknown(12, [UInt8](repeating: 0, count: 328)))
    }

    @Test func encodeAAAACloudflareComQuery() async throws {
        let query = Query(
            name: try Name(string: "cloudflare.com"),
            queryType: .AAAA,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0xa7fe,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryAAAACloudflareComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeAAAACloudflareComResponse() async throws {
        var buffer = Resources.dnsResponseAAAACloudflareComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0xa7fe)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 2)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == true)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "cloudflare.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .AAAA)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 2)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(name.data); \(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .AAAA }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.ttl == 72 }, "\(response.answers)")
        let ipv6s = response.answers.compactMap {
            switch $0.rdata {
            case .AAAA(let aaaa):
                return aaaa.value
            default:
                Issue.record("rdata was not of type AAAA: \($0.rdata)")
                return nil
            }
        }
        let expectedIPv6s = [
            IPv6Address(bytes: [
                0x26, 0x06, 0x47, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0x68, 0x10, 0x84, 0xe5,
            ]),
            IPv6Address(bytes: [
                0x26, 0x06, 0x47, 0,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0x68, 0x10, 0x85, 0xe5,
            ]),
        ]
        #expect(ipv6s == expectedIPv6s)

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 0)
        #expect(edns.maxPayload == 512)
        #expect(edns.options.options.count == 0)
    }

    @Test func encodeCAACloudflareComQuery() async throws {
        let query = Query(
            name: try Name(string: "cloudflare.com"),
            queryType: .CAA,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0xc01b,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryCAACloudflareComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeCAACloudflareComResponse() async throws {
        var buffer = Resources.dnsResponseCAACloudflareComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0xc01b)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 11)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == true)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "cloudflare.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CAA)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 11)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .CAA }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.ttl == 300 }, "\(response.answers)")
        let caas = response.answers.compactMap {
            switch $0.rdata {
            case .CAA(let caa):
                return caa
            default:
                Issue.record("rdata was not of type CAA: \($0.rdata)")
                return nil
            }
        }
        let expectedCAAs = [
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issueWildcard,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [112, 107, 105, 103, 111, 111, 103],
                            borders: [3, 7]
                        )
                    ),
                    [
                        (
                            key: "cansignhttpexchanges",
                            value: "yes"
                        )
                    ]
                ),
                rawValue: [
                    112, 107, 105, 46, 103, 111, 111, 103, 59, 32, 99, 97, 110, 115, 105, 103, 110,
                    104, 116, 116, 112, 101, 120, 99, 104, 97, 110, 103, 101, 115, 61, 121, 101,
                    115,
                ]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issueWildcard,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [99, 111, 109, 111, 100, 111, 99, 97, 99, 111, 109],
                            borders: [8, 11]
                        )
                    ),
                    []
                ),
                rawValue: [99, 111, 109, 111, 100, 111, 99, 97, 46, 99, 111, 109]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .iodef,
                value: .url("mailto:tls-abuse@cloudflare.com"),
                rawValue: [
                    109, 97, 105, 108, 116, 111, 58, 116, 108, 115, 45, 97, 98, 117, 115, 101, 64,
                    99, 108, 111, 117, 100, 102, 108, 97, 114, 101, 46, 99, 111, 109,
                ]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issue,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [112, 107, 105, 103, 111, 111, 103],
                            borders: [3, 7]
                        )
                    ),
                    [
                        (
                            key: "cansignhttpexchanges",
                            value: "yes"
                        )
                    ]
                ),
                rawValue: [
                    112, 107, 105, 46, 103, 111, 111, 103, 59, 32, 99, 97, 110, 115, 105, 103, 110,
                    104, 116, 116, 112, 101, 120, 99, 104, 97, 110, 103, 101, 115, 61, 121, 101,
                    115,
                ]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issue,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [99, 111, 109, 111, 100, 111, 99, 97, 99, 111, 109],
                            borders: [8, 11]
                        )
                    ),
                    []
                ),
                rawValue: [99, 111, 109, 111, 100, 111, 99, 97, 46, 99, 111, 109]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issue,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [115, 115, 108, 99, 111, 109],
                            borders: [3, 6]
                        )
                    ),
                    []
                ),
                rawValue: [115, 115, 108, 46, 99, 111, 109]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issueWildcard,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [100, 105, 103, 105, 99, 101, 114, 116, 99, 111, 109],
                            borders: [8, 11]
                        )
                    ),
                    [
                        (
                            key: "cansignhttpexchanges",
                            value: "yes"
                        )
                    ]
                ),
                rawValue: [
                    100, 105, 103, 105, 99, 101, 114, 116, 46, 99, 111, 109, 59, 32, 99, 97, 110,
                    115, 105, 103, 110, 104, 116, 116, 112, 101, 120, 99, 104, 97, 110, 103, 101,
                    115, 61, 121, 101, 115,
                ]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issueWildcard,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [115, 115, 108, 99, 111, 109],
                            borders: [3, 6]
                        )
                    ),
                    []
                ),
                rawValue: [115, 115, 108, 46, 99, 111, 109]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issueWildcard,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [
                                108, 101, 116, 115, 101, 110, 99, 114, 121, 112, 116, 111, 114, 103,
                            ],
                            borders: [11, 14]
                        )
                    ),
                    []
                ),
                rawValue: [108, 101, 116, 115, 101, 110, 99, 114, 121, 112, 116, 46, 111, 114, 103]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issue,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [100, 105, 103, 105, 99, 101, 114, 116, 99, 111, 109],
                            borders: [8, 11]
                        )
                    ),
                    [
                        (
                            key: "cansignhttpexchanges",
                            value: "yes"
                        )
                    ]
                ),
                rawValue: [
                    100, 105, 103, 105, 99, 101, 114, 116, 46, 99, 111, 109, 59, 32, 99, 97, 110,
                    115, 105, 103, 110, 104, 116, 116, 112, 101, 120, 99, 104, 97, 110, 103, 101,
                    115, 61, 121, 101, 115,
                ]
            ),
            CAA(
                issuerCritical: false,
                reservedFlags: 0,
                tag: .issue,
                value: .issuer(
                    Optional(
                        Name(
                            isFQDN: false,
                            data: [
                                108, 101, 116, 115, 101, 110, 99, 114, 121, 112, 116, 111, 114, 103,
                            ],
                            borders: [11, 14]
                        )
                    ),
                    []
                ),
                rawValue: [108, 101, 116, 115, 101, 110, 99, 114, 121, 112, 116, 46, 111, 114, 103]
            ),
        ]
        try #require(caas.count == 11)
        // FXIME: use proper equality checking when I've figured out Name equality checking
        #expect("\(caas)" == "\(expectedCAAs)")

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 0)
        #expect(edns.maxPayload == 512)
        #expect(edns.options.options.count == 0)
    }

    @Test func encodeCERTForDnsCertTestingMahdibmComQuery() async throws {
        let query = Query(
            name: try Name(string: "for-dns-cert-testing.mahdibm.com"),
            queryType: .CERT,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0x200c,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryCERTForDnsCertTestingMahdibmComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeCERTForDnsCertTestingMahdibmComResponse() async throws {
        var buffer = Resources.dnsResponseCERTForDnsCertTestingMahdibmComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0x200c)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 1)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == false)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "for-dns-cert-testing.mahdibm.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CERT)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 1)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .CERT }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.ttl == 300 }, "\(response.answers)")
        let certs = response.answers.compactMap {
            switch $0.rdata {
            case .CERT(let cert):
                return cert
            default:
                Issue.record("rdata was not of type CERT: \($0.rdata)")
                return nil
            }
        }
        let expectedCerts = [
            CERT(
                certType: .PKIX,
                keyTag: 12345,
                algorithm: .RSASHA256,
                certData: [
                    0x4c, 0x4a, 0x41, 0x34, 0x56, 0x32, 0x4c, 0x6b, 0x56, 0x51, 0x5a, 0x6c, 0x4c,
                    0x7a, 0x5a, 0x6b, 0x48, 0x6d, 0x41, 0x75, 0x4f, 0x77, 0x4c, 0x31, 0x44, 0x47,
                    0x42, 0x33, 0x70, 0x51, 0x4d, 0x33, 0x56, 0x6d, 0x4c, 0x32, 0x56, 0x54, 0x4d,
                    0x34, 0x44, 0x4a, 0x5a,
                ]
            )
        ]

        #expect(certs.count == expectedCerts.count)

        for (lhs, rhs) in zip(certs, expectedCerts) {
            #expect(lhs.certType == rhs.certType)
            #expect(lhs.keyTag == rhs.keyTag)
            #expect(lhs.algorithm == rhs.algorithm)
            #expect(lhs.certData == rhs.certData)
        }

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 0)
        #expect(edns.maxPayload == 512)
        #expect(edns.options.options.count == 0)
    }

    @Test func encodeCNAMEWwwGithubComQuery() async throws {
        let query = Query(
            name: try Name(string: "www.github.com"),
            queryType: .CNAME,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0x3dfb,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryCNAMEWwwGithubComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeCNAMEWwwGithubComResponse() async throws {
        var buffer = Resources.dnsResponseCNAMEWwwGithubComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0x3dfb)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 1)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == false)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "www.github.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CNAME)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 1)
        let answer = try #require(response.answers.first)
        #expect(answer.nameLabels.isFQDN == true)
        #expect(answer.nameLabels.data == name.data)
        #expect(answer.recordType == .CNAME)
        #expect(answer.dnsClass == .IN)
        #expect(answer.ttl == 3550)
        let cname: CNAME
        switch answer.rdata {
        case .CNAME(let _cname):
            cname = _cname
        default:
            Issue.record("rdata was not of type CNAME: \(answer.rdata)")
            return
        }
        #expect(cname.name.asString() == "github.com.")

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 0)
        #expect(edns.maxPayload == 512)
        #expect(edns.options.options.count == 0)
    }

    @Test func encodeCNAMERawGithubusercontentComQuery() async throws {
        let query = Query(
            name: try Name(string: "raw.githubusercontent.com"),
            queryType: .CNAME,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0x3c7d,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryCNAMERawGithubusercontentComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeCNAMERawGithubusercontentComResponse() async throws {
        var buffer = Resources.dnsResponseCNAMERawGithubusercontentComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0x3c7d)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 0)
        #expect(response.header.nameServerCount == 1)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == false)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "raw.githubusercontent.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CNAME)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 1)
        let nameServer = try #require(response.nameServers.first)
        switch nameServer.rdata {
        case .SOA(let soa):
            #expect(soa.mName.asString() == "ns-1411.awsdns-48.org.")
            #expect(soa.rName.asString() == "awsdns-hostmaster.amazon.com.")
            #expect(soa.serial == 1)
            #expect(soa.refresh == 7200)
            #expect(soa.retry == 900)
            #expect(soa.expire == 1_209_600)
            #expect(soa.minimum == 86400)
        default:
            Issue.record("rdata was not of type SOA: \(nameServer.rdata)")
        }

        #expect(response.answers.count == 0)

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 0)
        #expect(edns.maxPayload == 512)
        #expect(edns.options.options.count == 0)
    }

    @Test func encodeMXMahdibmComQuery() async throws {
        let query = Query(
            name: try Name(string: "mahdibm.com"),
            queryType: .MX,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0x3c4a,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryMXMahdibmComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeMXMahdibmComResponse() async throws {
        var buffer = Resources.dnsResponseMXMahdibmComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0x3c4a)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 2)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == false)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "mahdibm.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .MX)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 2)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .MX }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.ttl == 300 }, "\(response.answers)")
        let mxs = response.answers.compactMap {
            switch $0.rdata {
            case .MX(let mx):
                return mx
            default:
                Issue.record("rdata was not of type MX: \($0.rdata)")
                return nil
            }
        }
        let expectedMXs = [
            MX(preference: 10, exchange: try Name(string: "in1-smtp.messagingengine.com.")),
            MX(preference: 20, exchange: try Name(string: "in2-smtp.messagingengine.com.")),
        ]
        #expect(mxs.count == expectedMXs.count)
        for (mx, expectedMX) in zip(mxs, expectedMXs) {
            #expect(mx.preference == expectedMX.preference)
            #expect(mx.exchange.isFQDN == expectedMX.exchange.isFQDN)
            #expect(mx.exchange.data == expectedMX.exchange.data)
            #expect(mx.exchange.borders == expectedMX.exchange.borders)
        }

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 0)
        #expect(edns.maxPayload == 512)
        #expect(edns.options.options.count == 0)
    }

    @Test func encodeNSAppleComQuery() async throws {
        let query = Query(
            name: try Name(string: "apple.com"),
            queryType: .NS,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0x1fec,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryNSAppleComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeNSAppleComResponse() async throws {
        var buffer = Resources.dnsResponseNSAppleComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0x1fec)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 4)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == false)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "apple.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .NS)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 4)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .NS }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.ttl == 11197 }, "\(response.answers)")
        let nss = response.answers.compactMap {
            switch $0.rdata {
            case .NS(let ns):
                return ns
            default:
                Issue.record("rdata was not of type NS: \($0.rdata)")
                return nil
            }
        }
        let expectedNSs = [
            NS(name: try Name(string: "d.ns.apple.com.")),
            NS(name: try Name(string: "c.ns.apple.com.")),
            NS(name: try Name(string: "a.ns.apple.com.")),
            NS(name: try Name(string: "b.ns.apple.com.")),
        ]
        #expect(nss.count == expectedNSs.count)
        for (ns, expectedNS) in zip(nss, expectedNSs) {
            #expect(ns.name.isFQDN == expectedNS.name.isFQDN)
            #expect(ns.name.data == expectedNS.name.data)
            #expect(ns.name.borders == expectedNS.name.borders)
        }

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 0)
        #expect(edns.maxPayload == 512)
        #expect(edns.options.options.count == 0)
    }

    @Test func encodeTXTExampleComQuery() async throws {
        let query = Query(
            name: try Name(string: "example.com"),
            queryType: .TXT,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: 0x9f11,
                messageType: .Query,
                opCode: .Query,
                authoritative: false,
                truncation: false,
                recursionDesired: true,
                recursionAvailable: false,
                authenticData: true,
                checkingDisabled: false,
                responseCode: .NoError,
                queryCount: 1,
                answerCount: 0,
                nameServerCount: 0,
                additionalCount: 1
            ),
            queries: [query],
            answers: [],
            nameServers: [],
            additionals: [],
            signature: [],
            edns: EDNS(
                rcodeHigh: 0,
                version: 0,
                flags: .init(dnssecOk: false, z: 0),
                maxPayload: 4096,
                options: OPT(options: [])
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        var expected = Resources.dnsQueryTXTExampleComPacket.buffer()
        expected.moveReaderIndex(forwardBy: 42)
        #expect(buffer == expected)
    }

    @Test func decodeTXTExampleComResponse() async throws {
        var buffer = Resources.dnsResponseTXTExampleComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)

        let response = try Message(from: &buffer)

        #expect(response.header.id == 0x9f11)
        #expect(response.header.queryCount == 1)
        #expect(response.header.answerCount == 2)
        #expect(response.header.nameServerCount == 0)
        #expect(response.header.additionalCount == 1)
        #expect(response.header.messageType == .Response)
        #expect(response.header.opCode == .Query)
        #expect(response.header.authoritative == false)
        #expect(response.header.truncation == false)
        #expect(response.header.recursionDesired == true)
        #expect(response.header.recursionAvailable == true)
        #expect(response.header.authenticData == true)
        #expect(response.header.checkingDisabled == false)
        #expect(response.header.responseCode == .NoError)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "example.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .TXT)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count == 2)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .TXT }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.ttl == 80148 }, "\(response.answers)")
        let txts = response.answers.compactMap {
            switch $0.rdata {
            case .TXT(let txt):
                return txt
            default:
                Issue.record("rdata was not of type TXT: \($0.rdata)")
                return nil
            }
        }
        let expectedTXTs = [
            TXT(txtData: ["v=spf1 -all"]),
            TXT(txtData: ["_k2n1y4vw3qtb4skdx9e7dxt97qrmmq9"]),
        ]
        #expect(txts == expectedTXTs)

        /// The 'additional' was an EDNS
        #expect(response.additionals.count == 0)

        #expect(response.signature.count == 0)

        let edns = try #require(response.edns)
        #expect(edns.rcodeHigh == 0)
        #expect(edns.version == 0)
        #expect(edns.flags.dnssecOk == false)
        #expect(edns.flags.z == 0)
        #expect(edns.maxPayload == 1232)
        #expect(edns.options.options.count == 0)
    }
}
