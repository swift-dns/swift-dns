import DNSClient
import DNSModels
import NIOCore
import Testing

@Suite
struct DNSMessageDecoderTests {
    @available(swiftDNSApplePlatforms 15, *)
    @Test func decodesDNSMessage() throws {
        let decoder = DNSMessageDecoder()
        let resource = Resources.dnsResponseCERTForDnsCertTestingMahdibmComPacket
        var buffer = ByteBuffer(dnsBuffer: resource.buffer())
        buffer.moveReaderIndex(forwardBy: 42)
        let result = try #require(decoder.decode(buffer: &buffer))
        switch result {
        case .message(let message):
            let domainName = try DomainName(string: "for-dns-cert-testing.mahdibm.com.")
            #expect(message.queries.first?.domainName == domainName)
        case .identifiableError(let id, let error):
            Issue.record("Expected message but got identifiable error. ID: \(id), error: \(error)")
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func decodingBufferWithLessThan12BytesReturnsNil() {
        let decoder = DNSMessageDecoder()
        var buffer = ByteBuffer()
        buffer.setRepeatingByte(0, count: 11, at: buffer.readerIndex)
        let result = decoder.decode(buffer: &buffer)
        #expect(result == nil)
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func throwsIdentifiableErrorWhenDecodingFailsAndReturnsEmptyBuffer() throws {
        let decoder = DNSMessageDecoder()
        let resource = Resources.dnsResponseCERTForDnsCertTestingMahdibmComPacket
        var buffer = ByteBuffer(dnsBuffer: resource.buffer())
        buffer.moveReaderIndex(forwardBy: 42)
        /// Set the buffer to only the first 42 bytes
        buffer = buffer.getSlice(at: buffer.readerIndex, length: 42)!

        let result = try #require(decoder.decode(buffer: &buffer))
        switch result {
        case .identifiableError(let id, let error):
            #expect(id == 8204)
            switch error as? ProtocolError {
            case .failedToValidate(let domainName, var buffer):
                #expect(String(describing: domainName) == "DomainName")
                /// Preferably whenever possible when decoding fails, the bytes that failed to decode
                /// should be marked as read already.
                ///
                /// The behavior that is happening here might not be the same, but see
                /// `DNSBuffer.withTruncatedReadableBytes` comments for more details.
                #expect(buffer.getToEnd().readableBytes == 1)
            default:
                Issue.record("Expected ProtocolError.failedToValidate but got \(error)")
            }
        case .message(let message):
            Issue.record("Expected identifiable error but got message: \(message)")
        }
    }
}
