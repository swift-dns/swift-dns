import DNSClient
import DNSModels
import Logging
import NIOPosix
import Testing

@Suite(.serialized)
struct DNSTests {
    @Test func queryA() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "example.com"),
            queryType: .A,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "example.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .A)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count > 1)
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
        /// response.answers[].ttl is whatever
        let ipv4s = response.answers.compactMap {
            switch $0.rdata {
            case .A(let a):
                return a.value
            default:
                Issue.record("rdata was not of type A: \($0.rdata)")
                return nil
            }
        }
        #expect(
            ipv4s.allSatisfy {
                /// Weird way to check if the IPv4 is not just some zero bytes
                var sum: UInt32 = 0
                for idx in $0.bytes.indices {
                    sum += UInt32($0.bytes[idx])
                }
                return sum != 0
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

    @Test func queryAAAA() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "cloudflare.com"),
            queryType: .AAAA,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "cloudflare.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .AAAA)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count > 1)
        #expect(
            response.answers.allSatisfy { $0.nameLabels.isFQDN },
            "\(response.answers)"
        )
        #expect(
            response.answers.allSatisfy { $0.nameLabels.data == name.data },
            "\(response.answers)"
        )
        #expect(response.answers.allSatisfy { $0.recordType == .AAAA }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let ipv6s = response.answers.compactMap {
            switch $0.rdata {
            case .AAAA(let aaaa):
                return aaaa.value
            default:
                Issue.record("rdata was not of type AAAA: \($0.rdata)")
                return nil
            }
        }
        #expect(
            ipv6s.allSatisfy {
                /// Weird way to check if the IPv4 is not just some zero bytes
                var sum: UInt32 = 0
                for idx in $0.bytes.indices {
                    sum += UInt32($0.bytes[idx])
                }
                return sum != 0
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

    @Test func queryCAA() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "cloudflare.com"),
            queryType: .CAA,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "cloudflare.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CAA)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count > 1)
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
        /// response.answers[].ttl is whatever
        let caa = response.answers.compactMap {
            switch $0.rdata {
            case .CAA(let caa):
                return caa
            default:
                Issue.record("rdata was not of type CAA: \($0.rdata)")
                return nil
            }
        }
        #expect(
            caa.allSatisfy {
                $0.rawValue.count > 5
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

    @Test func queryCERT() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "for-dns-cert-testing.mahdibm.com"),
            queryType: .CERT,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        /// response.answers[].ttl is whatever
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
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryCNAMEWwwGithubCom() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "www.github.com"),
            queryType: .CNAME,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        #expect(answer.ttl > 0)
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
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryCNAMERawGithubusercontentCom() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "raw.githubusercontent.com"),
            queryType: .CNAME,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "raw.githubusercontent.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .CNAME)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count > 0)

        let nameServer = try #require(response.nameServers.first)
        switch nameServer.rdata {
        case .SOA(let soa):
            let mName = soa.mName.asString()
            let rName = soa.rName.asString()
            #expect(mName.count > 5, "mName: \(mName), soa: \(soa)")
            #expect(rName.count > 5, "rName: \(rName), soa: \(soa)")
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
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryCSYNC() async throws {}

    @Test func queryHINFO() async throws {}

    @Test func queryHTTPS() async throws {}

    @Test func queryMX() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "mahdibm.com"),
            queryType: .MX,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        /// response.answers[].ttl is whatever
        let mxs = response.answers.compactMap {
            switch $0.rdata {
            case .MX(let mx):
                return mx
            default:
                Issue.record("rdata was not of type MX: \($0.rdata)")
                return nil
            }
        }.sorted {
            $0.preference < $1.preference
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
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryNAPTR() async throws {}

    @Test func queryNS() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "apple.com"),
            queryType: .NS,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        /// response.answers[].ttl is whatever
        let nss = response.answers.compactMap {
            switch $0.rdata {
            case .NS(let ns):
                return ns
            default:
                Issue.record("rdata was not of type NS: \($0.rdata)")
                return nil
            }
        }.sorted {
            $0.name.asString() < $1.name.asString()
        }
        let expectedNSs = [
            NS(name: try Name(string: "a.ns.apple.com.")),
            NS(name: try Name(string: "b.ns.apple.com.")),
            NS(name: try Name(string: "c.ns.apple.com.")),
            NS(name: try Name(string: "d.ns.apple.com.")),
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
        /// edns.flags.z is whatever
        /// edns.maxPayload is whatever
        /// edns.options.options is whatever
    }

    @Test func queryNULL() async throws {}

    @Test func queryOPENPGPKEY() async throws {}

    /// You can't query OPT directly, so this response is a `ServFail`.
    /// OPT is used in every other query, so it's already well-tested.
    @Test func queryOPT() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "cloudflare.com"),
            queryType: .OPT,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
        #expect(response.header.queryCount > 0)
        #expect(response.header.answerCount == 0)
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
        #expect(response.header.responseCode == .ServFail)

        #expect(response.queries.count == 1)
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "cloudflare.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .OPT)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

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
        #expect(edns.options.options.count > 10)
        #expect(
            edns.options.options.allSatisfy { $0.0 == .ednsError },
            "\(edns.options.options)"
        )
        #expect(
            edns.options.options.allSatisfy {
                switch $0.1 {
                case .unknown(let code, let data):
                    return code == EDNSCode.ednsError.rawValue
                        && data.count > 10
                default:
                    return false
                }
            },
            "\(edns.options.options)"
        )
    }

    @Test func queryPTR() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "9.9.9.9.in-addr.arpa"),
            queryType: .PTR,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "9.9.9.9.in-addr.arpa")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .PTR)
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
        #expect(response.answers.allSatisfy { $0.recordType == .PTR }, "\(response.answers)")
        #expect(response.answers.allSatisfy { $0.dnsClass == .IN }, "\(response.answers)")
        /// response.answers[].ttl is whatever
        let ptrs = response.answers.compactMap {
            switch $0.rdata {
            case .PTR(let ptr):
                return ptr
            default:
                Issue.record("rdata was not of type PTR: \($0.rdata)")
                return nil
            }
        }
        let expectedPTRs = [
            PTR(name: try Name(string: "dns9.quad9.net."))
        ]
        #expect(ptrs.count == expectedPTRs.count)
        for (ptr, expectedPTR) in zip(ptrs, expectedPTRs) {
            #expect(ptr.name.isFQDN == expectedPTR.name.isFQDN)
            #expect(ptr.name.data == expectedPTR.name.data)
            #expect(ptr.name.borders == expectedPTR.name.borders)
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

    @Test func querySOA() async throws {}

    @Test func querySRV() async throws {}

    @Test func querySSHFP() async throws {}

    @Test func querySVCB() async throws {}

    @Test func queryTLSA() async throws {}

    @Test func queryTXT() async throws {
        let client = DNSClient(
            connectionTarget: .domain(name: "8.8.4.4", port: 53),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )

        let query = Query(
            name: try Name(string: "example.com"),
            queryType: .TXT,
            queryClass: .IN
        )
        let message = Message(
            header: Header(
                id: .random(in: .min ... .max),
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

        let response = try await client.query(message: message)

        #expect(response.header.id == message.header.id)
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
        #expect(response.queries.first?.name.isFQDN == true)
        let name = try Name(string: "example.com")
        #expect(response.queries.first?.name.data == name.data)
        #expect(response.queries.first?.queryType == .TXT)
        #expect(response.queries.first?.queryClass == .IN)

        #expect(response.nameServers.count == 0)

        #expect(response.answers.count > 1)
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
        /// response.answers[].ttl is whatever
        let txts = response.answers.compactMap {
            switch $0.rdata {
            case .TXT(let txt):
                return txt
            default:
                Issue.record("rdata was not of type TXT: \($0.rdata)")
                return nil
            }
        }
        #expect(txts.allSatisfy { ($0.txtData.first?.count ?? 0) > 5 })

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

    @Test func queryUnknown() async throws {}

    @Test func queryUpdate0() async throws {}
}
