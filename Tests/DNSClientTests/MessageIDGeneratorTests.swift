import DNSClient
import Testing

@Suite
struct MessageIDGeneratorTests {
    @Test func generate10000IDs() {
        var generator = MessageIDGenerator()
        var generated = Set<UInt16>()
        for _ in 0..<10000 {
            let id = try! generator.next()
            #expect(UInt16.min...UInt16.max ~= id)
            #expect(generated.insert(id).inserted)
        }
        #expect(generated.count == 1000)
    }
}
