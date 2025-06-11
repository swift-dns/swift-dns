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
        #expect(response.queries[0].name.isFQDN)
        let name = try Name(string: "example.com")
        #expect(response.queries[0].name.data == name.data)
        #expect(response.queries[0].queryType == .A)
        #expect(response.queries[0].queryClass == .IN)

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
        #expect(response.queries[0].name.isFQDN)
        let name = try Name(string: "cloudflare.com")
        #expect(response.queries[0].name.data == name.data)
        #expect(response.queries[0].queryType == .AAAA)
        #expect(response.queries[0].queryClass == .IN)

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
        #expect(response.queries[0].name.isFQDN)
        let name = try Name(string: "example.com")
        #expect(response.queries[0].name.data == name.data)
        #expect(response.queries[0].queryType == .TXT)
        #expect(response.queries[0].queryClass == .IN)

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
