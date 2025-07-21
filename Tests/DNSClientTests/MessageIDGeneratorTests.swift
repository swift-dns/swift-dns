import DNSClient
import Testing

@Suite
struct MessageIDGeneratorTests {
    @Test func generate32768IDs() throws {
        var generator = MessageIDGenerator()
        var generated = Set<UInt16>()
        let count = 32768
        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(UInt16.min...UInt16.max ~= id)
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == count)

        /// Next one should throw an error
        #expect(throws: MessageIDGenerator.Errors.self) {
            try generator.next()
        }

        /// The rest should throw as well
        for _ in 0..<50_000 {
            #expect(throws: MessageIDGenerator.Errors.self) {
                try generator.next()
            }
        }
    }

    @Test func generate32768IDsThenRemoveThenRedoThenRemoveThenRedo() throws {
        var generator = MessageIDGenerator()
        var generated = Set<UInt16>()
        let count = 32768
        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(UInt16.min...UInt16.max ~= id)
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == count)

        var removedCount = 0
        for idx in 0...UInt16.max {
            generator.remove(UInt16(idx))
            if generated.remove(UInt16(idx)) != nil {
                removedCount += 1
            }
        }
        #expect(removedCount == count)

        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(UInt16.min...UInt16.max ~= id)
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == count)

        removedCount = 0
        for idx in 0...UInt16.max {
            generator.remove(UInt16(idx))
            if generated.remove(UInt16(idx)) != nil {
                removedCount += 1
            }
        }
        #expect(removedCount == count)

        generated = []
        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(UInt16.min...UInt16.max ~= id)
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == count)
    }
}
