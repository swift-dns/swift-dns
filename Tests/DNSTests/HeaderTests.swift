@_spi(Testing) import DNSModels
import Testing

import struct NIOCore.ByteBuffer

@Suite
struct HeaderTests {
    @Test func setGetWorksInBytes16To31WithDefaultTrue() async throws {
        do {
            var bytes16To31 = Header.Bytes16To31(rawValue: 0)
            bytes16To31.messageType = .Query
            #expect(bytes16To31.messageType == .Query)
            bytes16To31.opCode = .Query
            #expect(bytes16To31.opCode == .Query)
            bytes16To31.authoritative = true
            #expect(bytes16To31.authoritative == true)
            bytes16To31.truncation = true
            #expect(bytes16To31.truncation == true)
            bytes16To31.recursionDesired = true
            #expect(bytes16To31.recursionDesired == true)
            bytes16To31.recursionAvailable = true
            #expect(bytes16To31.recursionAvailable == true)
            bytes16To31.authenticData = true
            #expect(bytes16To31.authenticData == true)
            bytes16To31.checkingDisabled = true
            #expect(bytes16To31.checkingDisabled == true)
            bytes16To31.responseCode = .NoError
            #expect(bytes16To31.responseCode == .NoError)
        }

        do {
            var bytes16To31 = Header.Bytes16To31(rawValue: .max)
            bytes16To31.messageType = .Query
            #expect(bytes16To31.messageType == .Query)
            bytes16To31.opCode = .Query
            #expect(bytes16To31.opCode == .Query)
            bytes16To31.authoritative = true
            #expect(bytes16To31.authoritative == true)
            bytes16To31.truncation = true
            #expect(bytes16To31.truncation == true)
            bytes16To31.recursionDesired = true
            #expect(bytes16To31.recursionDesired == true)
            bytes16To31.recursionAvailable = true
            #expect(bytes16To31.recursionAvailable == true)
            bytes16To31.authenticData = true
            #expect(bytes16To31.authenticData == true)
            bytes16To31.checkingDisabled = true
            #expect(bytes16To31.checkingDisabled == true)
            bytes16To31.responseCode = .NoError
            #expect(bytes16To31.responseCode == .NoError)
        }
    }

    @Test func setGetWorksInBytes16To31WithDefaultFalse() async throws {
        do {
            var bytes16To31 = Header.Bytes16To31(rawValue: 0)
            bytes16To31.messageType = .Response
            #expect(bytes16To31.messageType == .Response)
            bytes16To31.opCode = .DSO
            #expect(bytes16To31.opCode == .DSO)
            bytes16To31.authoritative = false
            #expect(bytes16To31.authoritative == false)
            bytes16To31.truncation = false
            #expect(bytes16To31.truncation == false)
            bytes16To31.recursionDesired = false
            #expect(bytes16To31.recursionDesired == false)
            bytes16To31.recursionAvailable = false
            #expect(bytes16To31.recursionAvailable == false)
            bytes16To31.authenticData = false
            #expect(bytes16To31.authenticData == false)
            bytes16To31.checkingDisabled = false
            #expect(bytes16To31.checkingDisabled == false)
            bytes16To31.responseCode = .NXDomain
            #expect(bytes16To31.responseCode == .NXDomain)
        }

        do {
            var bytes16To31 = Header.Bytes16To31(rawValue: .max)
            bytes16To31.messageType = .Response
            #expect(bytes16To31.messageType == .Response)
            bytes16To31.opCode = .DSO
            #expect(bytes16To31.opCode == .DSO)
            bytes16To31.authoritative = false
            #expect(bytes16To31.authoritative == false)
            bytes16To31.truncation = false
            #expect(bytes16To31.truncation == false)
            bytes16To31.recursionDesired = false
            #expect(bytes16To31.recursionDesired == false)
            bytes16To31.recursionAvailable = false
            #expect(bytes16To31.recursionAvailable == false)
            bytes16To31.authenticData = false
            #expect(bytes16To31.authenticData == false)
            bytes16To31.checkingDisabled = false
            #expect(bytes16To31.checkingDisabled == false)
            bytes16To31.responseCode = .NXDomain
            #expect(bytes16To31.responseCode == .NXDomain)
        }
    }

    @Test func setGetWorksInBytes16To31WithDefaultFalseAndReverseOrdering() async throws {
        do {
            var bytes16To31 = Header.Bytes16To31(rawValue: 0)
            bytes16To31.responseCode = .NotZone
            #expect(bytes16To31.responseCode == .NotZone)
            bytes16To31.checkingDisabled = false
            #expect(bytes16To31.checkingDisabled == false)
            bytes16To31.authenticData = false
            #expect(bytes16To31.authenticData == false)
            bytes16To31.recursionAvailable = false
            #expect(bytes16To31.recursionAvailable == false)
            bytes16To31.recursionDesired = false
            #expect(bytes16To31.recursionDesired == false)
            bytes16To31.truncation = false
            #expect(bytes16To31.truncation == false)
            bytes16To31.authoritative = false
            #expect(bytes16To31.authoritative == false)
            bytes16To31.opCode = .Notify
            #expect(bytes16To31.opCode == .Notify)
            bytes16To31.messageType = .Response
            #expect(bytes16To31.messageType == .Response)
        }

        do {
            var bytes16To31 = Header.Bytes16To31(rawValue: .max)
            bytes16To31.responseCode = .NotZone
            #expect(bytes16To31.responseCode == .NotZone)
            bytes16To31.checkingDisabled = false
            #expect(bytes16To31.checkingDisabled == false)
            bytes16To31.authenticData = false
            #expect(bytes16To31.authenticData == false)
            bytes16To31.recursionAvailable = false
            #expect(bytes16To31.recursionAvailable == false)
            bytes16To31.recursionDesired = false
            #expect(bytes16To31.recursionDesired == false)
            bytes16To31.truncation = false
            #expect(bytes16To31.truncation == false)
            bytes16To31.authoritative = false
            #expect(bytes16To31.authoritative == false)
            bytes16To31.opCode = .Notify
            #expect(bytes16To31.opCode == .Notify)
            bytes16To31.messageType = .Response
            #expect(bytes16To31.messageType == .Response)
        }
    }

    @Test func testRealWorldBytes16To31Parsing() async throws {
        let bytes16To31 = Header.Bytes16To31(rawValue: 33152)
        #expect(bytes16To31.messageType == .Response)
        #expect(bytes16To31.opCode == .Query)
        #expect(bytes16To31.authoritative == false)
        #expect(bytes16To31.truncation == false)
        #expect(bytes16To31.recursionDesired == true)
        #expect(bytes16To31.recursionAvailable == true)
        #expect(bytes16To31.authenticData == false)
        #expect(bytes16To31.checkingDisabled == false)
        #expect(bytes16To31.responseCode == .NoError)
    }

    @Test func headerParsesCorrectly() async throws {
        var buffer = DNSBuffer(bytes: [
            0xAA, 0xAA, 0x01, 0x00,
            0x00, 0x01, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
        ])
        let header = try Header(from: &buffer)
        #expect(header.id == 0xAAAA)
        #expect(header.messageType == .Query)
        #expect(header.opCode == .Query)
        #expect(header.authoritative == false)
        #expect(header.truncation == false)
        #expect(header.recursionDesired == true)
        #expect(header.recursionAvailable == false)
        #expect(header.authenticData == false)
        #expect(header.checkingDisabled == false)
        #expect(header.responseCode == .NoError)
        #expect(header.queryCount == 1)
        #expect(header.answerCount == 0)
        #expect(header.nameServerCount == 0)
        #expect(header.additionalCount == 0)
    }
}
