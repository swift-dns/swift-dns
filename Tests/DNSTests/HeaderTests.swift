@_spi(Testing) import DNSModels
import Testing

@Suite
struct HeaderTests {
    @Test func setGetWorksInBytes3And4WithDefaultTrue() throws {
        do {
            var bytes3And4 = Header.Bytes3And4(rawValue: 0)
            bytes3And4.messageType = .Query
            #expect(bytes3And4.messageType == .Query)
            bytes3And4.opCode = .Query
            #expect(bytes3And4.opCode == .Query)
            bytes3And4.authoritative = true
            #expect(bytes3And4.authoritative == true)
            bytes3And4.truncation = true
            #expect(bytes3And4.truncation == true)
            bytes3And4.recursionDesired = true
            #expect(bytes3And4.recursionDesired == true)
            bytes3And4.recursionAvailable = true
            #expect(bytes3And4.recursionAvailable == true)
            bytes3And4.authenticData = true
            #expect(bytes3And4.authenticData == true)
            bytes3And4.checkingDisabled = true
            #expect(bytes3And4.checkingDisabled == true)
            bytes3And4.responseCode = .NoError
            #expect(bytes3And4.responseCode == .NoError)
        }

        do {
            var bytes3And4 = Header.Bytes3And4(rawValue: .max)
            bytes3And4.messageType = .Query
            #expect(bytes3And4.messageType == .Query)
            bytes3And4.opCode = .Query
            #expect(bytes3And4.opCode == .Query)
            bytes3And4.authoritative = true
            #expect(bytes3And4.authoritative == true)
            bytes3And4.truncation = true
            #expect(bytes3And4.truncation == true)
            bytes3And4.recursionDesired = true
            #expect(bytes3And4.recursionDesired == true)
            bytes3And4.recursionAvailable = true
            #expect(bytes3And4.recursionAvailable == true)
            bytes3And4.authenticData = true
            #expect(bytes3And4.authenticData == true)
            bytes3And4.checkingDisabled = true
            #expect(bytes3And4.checkingDisabled == true)
            bytes3And4.responseCode = .NoError
            #expect(bytes3And4.responseCode == .NoError)
        }
    }

    @Test func setGetWorksInBytes3And4WithDefaultFalse() throws {
        do {
            var bytes3And4 = Header.Bytes3And4(rawValue: 0)
            bytes3And4.messageType = .Response
            #expect(bytes3And4.messageType == .Response)
            bytes3And4.opCode = .DSO
            #expect(bytes3And4.opCode == .DSO)
            bytes3And4.authoritative = false
            #expect(bytes3And4.authoritative == false)
            bytes3And4.truncation = false
            #expect(bytes3And4.truncation == false)
            bytes3And4.recursionDesired = false
            #expect(bytes3And4.recursionDesired == false)
            bytes3And4.recursionAvailable = false
            #expect(bytes3And4.recursionAvailable == false)
            bytes3And4.authenticData = false
            #expect(bytes3And4.authenticData == false)
            bytes3And4.checkingDisabled = false
            #expect(bytes3And4.checkingDisabled == false)
            bytes3And4.responseCode = .NXDomain
            #expect(bytes3And4.responseCode == .NXDomain)
        }

        do {
            var bytes3And4 = Header.Bytes3And4(rawValue: .max)
            bytes3And4.messageType = .Response
            #expect(bytes3And4.messageType == .Response)
            bytes3And4.opCode = .DSO
            #expect(bytes3And4.opCode == .DSO)
            bytes3And4.authoritative = false
            #expect(bytes3And4.authoritative == false)
            bytes3And4.truncation = false
            #expect(bytes3And4.truncation == false)
            bytes3And4.recursionDesired = false
            #expect(bytes3And4.recursionDesired == false)
            bytes3And4.recursionAvailable = false
            #expect(bytes3And4.recursionAvailable == false)
            bytes3And4.authenticData = false
            #expect(bytes3And4.authenticData == false)
            bytes3And4.checkingDisabled = false
            #expect(bytes3And4.checkingDisabled == false)
            bytes3And4.responseCode = .NXDomain
            #expect(bytes3And4.responseCode == .NXDomain)
        }
    }

    @Test func setGetWorksInBytes3And4WithDefaultFalseAndReverseOrdering() throws {
        do {
            var bytes3And4 = Header.Bytes3And4(rawValue: 0)
            bytes3And4.responseCode = .NotZone
            #expect(bytes3And4.responseCode == .NotZone)
            bytes3And4.checkingDisabled = false
            #expect(bytes3And4.checkingDisabled == false)
            bytes3And4.authenticData = false
            #expect(bytes3And4.authenticData == false)
            bytes3And4.recursionAvailable = false
            #expect(bytes3And4.recursionAvailable == false)
            bytes3And4.recursionDesired = false
            #expect(bytes3And4.recursionDesired == false)
            bytes3And4.truncation = false
            #expect(bytes3And4.truncation == false)
            bytes3And4.authoritative = false
            #expect(bytes3And4.authoritative == false)
            bytes3And4.opCode = .Notify
            #expect(bytes3And4.opCode == .Notify)
            bytes3And4.messageType = .Response
            #expect(bytes3And4.messageType == .Response)
        }

        do {
            var bytes3And4 = Header.Bytes3And4(rawValue: .max)
            bytes3And4.responseCode = .NotZone
            #expect(bytes3And4.responseCode == .NotZone)
            bytes3And4.checkingDisabled = false
            #expect(bytes3And4.checkingDisabled == false)
            bytes3And4.authenticData = false
            #expect(bytes3And4.authenticData == false)
            bytes3And4.recursionAvailable = false
            #expect(bytes3And4.recursionAvailable == false)
            bytes3And4.recursionDesired = false
            #expect(bytes3And4.recursionDesired == false)
            bytes3And4.truncation = false
            #expect(bytes3And4.truncation == false)
            bytes3And4.authoritative = false
            #expect(bytes3And4.authoritative == false)
            bytes3And4.opCode = .Notify
            #expect(bytes3And4.opCode == .Notify)
            bytes3And4.messageType = .Response
            #expect(bytes3And4.messageType == .Response)
        }
    }

    @Test func testRealWorldBytes3And4Parsing() throws {
        let bytes3And4 = Header.Bytes3And4(rawValue: 33152)
        #expect(bytes3And4.messageType == .Response)
        #expect(bytes3And4.opCode == .Query)
        #expect(bytes3And4.authoritative == false)
        #expect(bytes3And4.truncation == false)
        #expect(bytes3And4.recursionDesired == true)
        #expect(bytes3And4.recursionAvailable == true)
        #expect(bytes3And4.authenticData == false)
        #expect(bytes3And4.checkingDisabled == false)
        #expect(bytes3And4.responseCode == .NoError)
    }

    @Test func headerParsesCorrectly() throws {
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
