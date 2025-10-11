import DNSClient
import DNSModels
import Logging
import NIOPosix
import Synchronization
import Testing

import struct NIOCore.ByteBuffer

@Suite(.serialized)
struct IntegrationTests {
    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryA(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<A>.forQuery(domainName: "example.com.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryA(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount > 0)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("example.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .A)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count > 1)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .A }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let ipv4s = try response.answers.map {
                try $0.rdata.value
            }
            #expect(ipv4s.allSatisfy { $0.address != 0 })

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            #expect(edns.flags.dnssecOk == false)
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryANonASCIIDomain(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<A>.forQuery(domainName: "新华网.中国.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryA(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount > 0)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("新华网.中国.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .A)
            #expect(response.queries.first?.queryClass == .IN)

            /// response.nameServers.count is whatever

            #expect(response.answers.count > 1)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .A }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let ipv4s = try response.answers.map {
                try $0.rdata.value
            }
            #expect(ipv4s.allSatisfy { $0.address != 0 })

            /// response.additionals.count is whatever

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            #expect(edns.flags.dnssecOk == false)
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryAAAA(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<AAAA>.forQuery(domainName: "cloudflare.com.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryAAAA(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount > 0)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
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
            let domainName = try DomainName("cloudflare.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .AAAA)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count > 1)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .AAAA }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let ipv6s = try response.answers.map {
                try $0.rdata.value
            }
            #expect(ipv6s.allSatisfy { $0.address != 0 })

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            #expect(edns.flags.dnssecOk == false)
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryCAA(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<CAA>.forQuery(domainName: "apple.com.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryCAA(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount > 0)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("apple.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .CAA)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count > 1)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .CAA }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let caa = try response.answers.map {
                try $0.rdata
            }
            #expect(
                caa.allSatisfy {
                    $0.rawValue.readableBytes > 5
                }
            )

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            #expect(edns.flags.dnssecOk == false)
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryCERT(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<CERT>.forQuery(
                domainName: "for-dns-cert-testing.mahdibm.com."
            )
            let message = factory.__testing_copyMessage()
            let response = try await client.queryCERT(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount > 0)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("for-dns-cert-testing.mahdibm.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .CERT)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count == 1)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .CERT }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let certs = try response.answers.map {
                try $0.rdata
            }
            let expectedCerts = [
                CERT(
                    certType: .PKIX,
                    keyTag: 12345,
                    algorithm: .RSASHA256,
                    certData: ByteBuffer([
                        0x4c, 0x4a, 0x41, 0x34, 0x56, 0x32, 0x4c, 0x6b, 0x56, 0x51, 0x5a, 0x6c,
                        0x4c,
                        0x7a, 0x5a, 0x6b, 0x48, 0x6d, 0x41, 0x75, 0x4f, 0x77, 0x4c, 0x31, 0x44,
                        0x47,
                        0x42, 0x33, 0x70, 0x51, 0x4d, 0x33, 0x56, 0x6d, 0x4c, 0x32, 0x56, 0x54,
                        0x4d,
                        0x34, 0x44, 0x4a, 0x5a,
                    ])
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
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryCNAMEWwwGithubCom(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<CNAME>.forQuery(domainName: "www.github.com.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryCNAME(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount == 1)
            #expect(response.header.nameServerCount == 0)
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("www.github.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .CNAME)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count == 1)
            let answer = try #require(response.answers.first)
            #expect(answer.nameLabels == domainName)
            #expect(answer.recordType == .CNAME)
            #expect(answer.dnsClass == .IN)
            #expect(answer.ttl > 0)
            let nameNoWWW = try DomainName("github.com.")
            let cname = try answer.rdata
            #expect(cname.domainName == nameNoWWW)

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            #expect(edns.flags.dnssecOk == false)
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryCNAMERawGithubusercontentCom(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<CNAME>.forQuery(
                domainName: "raw.githubusercontent.com."
            )
            let message = factory.__testing_copyMessage()
            let response = try await client.queryCNAME(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount == 0)
            #expect(response.header.nameServerCount > 0)
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("raw.githubusercontent.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .CNAME)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count > 0)

            let nameServer = try #require(response.nameServers.first)
            switch nameServer.rdata {
            case .SOA(let soa):
                let mName = soa.mName.description
                let rName = soa.rName.description
                #expect(mName.count > 5, "mName: \(mName), soa: \(soa).")
                #expect(rName.count > 5, "rName: \(rName), soa: \(soa).")
            default:
                Issue.record("rdata was not of type SOA: \(nameServer.rdata).")
            }

            #expect(response.answers.count == 0)

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            #expect(edns.flags.dnssecOk == false)
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @Test func queryCSYNC() async throws {}

    @Test func queryHINFO() async throws {}

    @Test func queryHTTPS() async throws {
        /// TODO: try `education.github.com`
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryMX(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<MX>.forQuery(domainName: "mahdibm.com.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryMX(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount > 0)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("mahdibm.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .MX)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count == 2)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .MX }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let mxs = try response.answers.map {
                try $0.rdata
            }.sorted {
                $0.preference < $1.preference
            }
            let expectedMXs = [
                MX(
                    preference: 10,
                    exchange: try DomainName("in1-smtp.messagingengine.com.")
                ),
                MX(
                    preference: 20,
                    exchange: try DomainName("in2-smtp.messagingengine.com.")
                ),
            ]
            #expect(mxs.count == expectedMXs.count)
            for (mx, expectedMX) in zip(mxs, expectedMXs) {
                #expect(mx.preference == expectedMX.preference)
                #expect(mx.exchange == expectedMX.exchange)
            }

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            #expect(edns.flags.dnssecOk == false)
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @Test func queryNAPTR() async throws {}

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryNS(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<NS>.forQuery(domainName: "apple.com.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryNS(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount == 4)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("apple.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .NS)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count == 4)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .NS }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let nss = try response.answers.map {
                try $0.rdata
            }.sorted {
                $0.domainName.description < $1.domainName.description
            }
            let expectedNSs = [
                NS(domainName: try DomainName("a.ns.apple.com.")),
                NS(domainName: try DomainName("b.ns.apple.com.")),
                NS(domainName: try DomainName("c.ns.apple.com.")),
                NS(domainName: try DomainName("d.ns.apple.com.")),
            ]
            #expect(nss.count == expectedNSs.count)
            for (ns, expectedNS) in zip(nss, expectedNSs) {
                #expect(ns.domainName == expectedNS.domainName)
            }

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            #expect(edns.version == 0)
            /// edns.flags.dnssecOk is whatever
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @Test func queryNULL() async throws {}

    @Test func queryOPENPGPKEY() async throws {}

    /// You can't query OPT directly.
    /// OPT is used in every other query, so it's already well-tested.
    @Test func queryOPT() async throws {}

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryPTR(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<PTR>.forQuery(domainName: "9.9.9.9.in-addr.arpa.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryPTR(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount == 1)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("9.9.9.9.in-addr.arpa.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .PTR)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count == 1)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .PTR }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let ptrs = try response.answers.map {
                try $0.rdata
            }
            let expectedPTRs = [
                PTR(domainName: try DomainName("dns9.quad9.net."))
            ]
            #expect(ptrs.count == expectedPTRs.count)
            for (ptr, expectedPTR) in zip(ptrs, expectedPTRs) {
                #expect(ptr.domainName == expectedPTR.domainName)
            }

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            /// edns.version is whatever
            /// edns.flags.dnssecOk is whatever
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @Test func querySOA() async throws {}

    @Test func querySRV() async throws {}

    @Test func querySSHFP() async throws {}

    @Test func querySVCB() async throws {
        /// TODO: try `_dns.resolver.arpa`
    }

    @Test func queryTLSA() async throws {}

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClients())
    func queryTXT(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            let factory = try MessageFactory<TXT>.forQuery(domainName: "example.com.")
            let message = factory.__testing_copyMessage()
            let response = try await client.queryTXT(
                message: factory,
                options: .edns
            )

            #expect(
                message.header.id == 0 && response.header.id != 0,
                """
                The channel handler reassigns the id. We expect it to be 0 initially, but not in the response.
                This is only possible to happen because we're illegally using `factory.__testing_copyMessage()`.
                """
            )
            #expect(response.header.queryCount > 0)
            #expect(response.header.answerCount > 0)
            /// response.header.nameServerCount is whatever
            #expect(response.header.additionalCount > 0)
            #expect(response.header.messageType == .Response)
            #expect(response.header.opCode == .Query)
            #expect(response.header.authoritative == false)
            #expect(response.header.truncation == false)
            #expect(response.header.recursionDesired == true)
            #expect(response.header.recursionAvailable == true)
            /// `response.header.authenticData` is whatever
            #expect(response.header.checkingDisabled == false)
            #expect(response.header.responseCode == .NoError)

            #expect(response.queries.count == 1)
            let domainName = try DomainName("example.com.")
            #expect(response.queries.first?.domainName == domainName)
            #expect(response.queries.first?.queryType == .TXT)
            #expect(response.queries.first?.queryClass == .IN)

            #expect(response.nameServers.count == 0)

            #expect(response.answers.count > 1)
            #expect(
                response.answers.allSatisfy { $0.nameLabels.isFQDN },
                "\(response.answers)"
            )
            #expect(
                response.answers.allSatisfy { $0.nameLabels == domainName },
                "\(response.answers)"
            )
            #expect(response.answers.allSatisfy { $0.recordType == .TXT }, "\(response.answers).")
            #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers).")
            /// response.answers[].ttl is whatever
            let txts = try response.answers.map {
                try $0.rdata
            }
            #expect(txts.allSatisfy { ($0.txtData.first?.count ?? 0) > 5 })

            /// The 'additional' was an EDNS
            #expect(response.additionals.count == 0)

            #expect(response.signature.count == 0)

            let edns = try #require(response.edns)
            #expect(edns.rcodeHigh == 0)
            /// edns.version is whatever
            /// edns.flags.dnssecOk is whatever
            /// edns.flags.z is whatever
            /// edns.maxPayload is whatever
            /// edns.options.options is whatever
        }
    }

    @Test func queryUnknown() async throws {}

    @Test func queryUpdate0() async throws {}

    @available(swiftDNSApplePlatforms 15, *)
    private static func makeTestingDNSClientsForConcurrentTest() -> [DNSClient] {
        [
            try! DNSClient(
                transport: .preferUDPOrUseTCP(
                    serverAddress: .domain(
                        domainName: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
                        port: 53
                    ),
                    udpConnectionConfiguration: .init(queryTimeout: .seconds(10)),
                    tcpConfiguration: .init(
                        connectionConfiguration: .init(queryTimeout: .seconds(20)),
                        connectionPoolConfiguration: .init(
                            minimumConnectionCount: 0,
                            maximumConnectionSoftLimit: 40,
                            maximumConnectionHardLimit: 50,
                            idleTimeout: .seconds(10)
                        ),
                        keepAliveBehavior: .init()
                    ),
                    logger: .init(label: "DNSClientTests")
                )
            ),
            try! DNSClient(
                transport: .tcp(
                    serverAddress: .domain(
                        domainName: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
                        port: 53
                    ),
                    configuration: .init(
                        connectionConfiguration: .init(queryTimeout: .seconds(20)),
                        connectionPoolConfiguration: .init(
                            minimumConnectionCount: 0,
                            maximumConnectionSoftLimit: 40,
                            maximumConnectionHardLimit: 50,
                            idleTimeout: .seconds(10)
                        ),
                        keepAliveBehavior: .init()
                    ),
                    logger: .init(label: "DNSClientTests")
                )
            ),
        ]
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: makeTestingDNSClientsForConcurrentTest())
    func query100DomainsConcurrently(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            await withTaskGroup(of: Void.self) { group in
                let withAnswers = Atomic(0)
                let errors: Mutex<[(String, any Error)]> = .init([])

                for domain in self.loadTop100Domains() {
                    group.addTask { @Sendable () -> Void in
                        do {
                            let domainName = try DomainName(domain + ".")
                            let response = try await client.queryNS(
                                message: .forQuery(domainName: domainName),
                                options: .edns
                            )
                            #expect(response.header.responseCode == .NoError, "\(domain)")
                            #expect(response.header.messageType == .Response, "\(domain)")
                            #expect(response.header.opCode == .Query, "\(domain)")
                            #expect(response.queries.first?.domainName == domainName, "\(domain)")
                            if response.header.answerCount > 0 {
                                #expect(response.answers.count > 0, "\(domain)")
                                withAnswers.add(1, ordering: .relaxed)
                            }
                        } catch {
                            errors.withLock { $0.append((domain, error)) }
                        }
                    }
                }

                await group.waitForAll()

                errors.withLock { errors in
                    /// Keep track of the errors for debugging, even if they less than the test-failure amount below.
                    if !errors.isEmpty {
                        print(
                            "\(#function) encountered these errors:\n\(errors)"
                        )
                    }
                    if errors.count >= 5 {
                        Issue.record("Too many errors: \(errors)")
                    }
                }

                #expect(withAnswers.load(ordering: .relaxed) >= 95)
            }
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    private static func makeTestingDNSClientsForSequentialTest() -> [DNSClient] {
        [
            try! DNSClient(
                transport: .preferUDPOrUseTCP(
                    serverAddress: .domain(
                        domainName: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
                        port: 53
                    ),
                    udpConnectionConfiguration: .init(queryTimeout: .seconds(5)),
                    tcpConfiguration: .init(
                        connectionConfiguration: .init(queryTimeout: .seconds(10)),
                        connectionPoolConfiguration: .init(
                            minimumConnectionCount: 0,
                            maximumConnectionSoftLimit: 1,
                            maximumConnectionHardLimit: 1,
                            idleTimeout: .seconds(30)
                        )
                    ),
                    logger: .init(label: "DNSClientTests")
                )
            ),
            try! DNSClient(
                transport: .tcp(
                    serverAddress: .domain(
                        domainName: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
                        port: 53
                    ),
                    configuration: .init(
                        connectionConfiguration: .init(queryTimeout: .seconds(10)),
                        connectionPoolConfiguration: .init(
                            minimumConnectionCount: 0,
                            maximumConnectionSoftLimit: 1,
                            maximumConnectionHardLimit: 1,
                            idleTimeout: .seconds(30)
                        )
                    ),
                    logger: .init(label: "DNSClientTests")
                )
            ),
        ]
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(
        .tags(.timeConsuming),
        arguments: makeTestingDNSClientsForSequentialTest()
    )
    func query100DomainsSequentially(client: DNSClient) async throws {
        try await withRunningDNSClient(client) { client in
            var withAnswers = 0
            var errors: [(String, any Error)] = []

            for domain in self.loadTop100Domains() {
                do {
                    let domainName = try DomainName(domain)
                    let response = try await client.queryNS(
                        message: .forQuery(domainName: domainName),
                        options: .edns
                    )
                    #expect(response.header.responseCode == .NoError, "\(domain)")
                    #expect(response.header.messageType == .Response, "\(domain)")
                    #expect(response.header.opCode == .Query, "\(domain)")
                    #expect(
                        response.queries.first?.domainName.isEssentiallyEqual(to: domainName)
                            == true,
                        "\(domain)"
                    )
                    if response.header.answerCount > 0 {
                        #expect(response.answers.count > 0, "\(domain)")
                        withAnswers += 1
                    }
                } catch {
                    errors.append((domain, error))
                }
            }

            /// Keep track of the errors for debugging, even if they are less than the test-failure amount below.
            if !errors.isEmpty {
                print("\(#function) encountered these errors:\n\(errors)")
            }
            if errors.count >= 5 {
                Issue.record("Too many errors: \(errors)")
            }

            #expect(withAnswers >= 95)
        }
    }

    /// A bunch don't even have A records. All have NS records.
    func loadTop100Domains() -> [String] {
        String(
            decoding: Resources.topDomains.data(),
            as: UTF8.self
        )
        .split(separator: "\n")
        .dropFirst()
        .prefix(100)
        .map(String.init)
    }

    @available(swiftDNSApplePlatforms 15, *)
    private static func makeTestingDNSClients() -> [DNSClient] {
        [
            try! DNSClient(
                transport: .preferUDPOrUseTCP(
                    serverAddress: .domain(
                        domainName: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
                        port: 53
                    ),
                    udpConnectionConfiguration: .init(queryTimeout: .seconds(10)),
                    tcpConfiguration: .init(
                        connectionConfiguration: .init(queryTimeout: .seconds(20)),
                        connectionPoolConfiguration: .init(),
                        keepAliveBehavior: .init()
                    ),
                    logger: .init(label: "DNSClientTests")
                )
            ),
            try! DNSClient(
                transport: .tcp(
                    serverAddress: .domain(
                        domainName: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
                        port: 53
                    ),
                    configuration: .init(
                        connectionConfiguration: .init(queryTimeout: .seconds(20)),
                        connectionPoolConfiguration: .init(),
                        keepAliveBehavior: .init()
                    ),
                    logger: .init(label: "DNSClientTests")
                )
            ),
        ]
    }
}
