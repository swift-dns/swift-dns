import DNSModels
import Testing

struct SpecializedMessageTests {
    @available(swiftDNSApplePlatforms 10.15, *)
    @Test func `SpecializedRecords filters out unrelated records`() throws {
        let (_, message) = Utils.bufferAndMessage(
            from: .dnsResponseAWwwExampleComPacket,
            changingIDTo: nil
        )

        let specializedMessage = SpecializedMessage<A>(message: message)

        #expect(specializedMessage.header.id == 0x1306)

        #expect(specializedMessage.message.answers.count == 4)
        #expect(specializedMessage.message.answers.map(\.recordType) == [.CNAME, .CNAME, .A, .A])

        /// The actual `.message.answers` contains `CNAME`s, but `.answers` must filter out the
        /// `CNAME`s and only return the `A` records.
        #expect(specializedMessage.answers.count == 2)
        #expect(specializedMessage.answers.map(\.recordType) == [.A, .A])

        #expect(specializedMessage.answers[0].recordType == .A)
        #expect(specializedMessage.answers[1].recordType == .A)
    }
}
