import DNSClient
import Testing

@Suite
struct MessageIDGeneratorTests {
    @Test func `generate maxCount IDs`() throws {
        var generator = MessageIDGenerator()
        var generated = Set<UInt16>()
        let count = MessageIDGenerator.capacity
        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(MessageIDGenerator.randomNumberRange.contains(id))
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

    @Test func `generate maxCount IDs then remove 100 then add 200`() throws {
        var generator = MessageIDGenerator()
        var generated = Set<UInt16>()
        var count = MessageIDGenerator.capacity - 100
        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(MessageIDGenerator.randomNumberRange.contains(id))
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == count)

        /// Remove 100 IDs
        var removedCount = 0
        for idx in MessageIDGenerator.randomNumberRange {
            if removedCount == 100 {
                break
            }
            if generator.remove(idx) {
                #expect(generated.remove(idx) != nil)
                removedCount += 1
            }
        }

        count = 200
        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(MessageIDGenerator.randomNumberRange.contains(id))
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == (MessageIDGenerator.capacity - 100) - 100 + count)

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

    @Test func `generate maxCount IDs then remove then redo then remove then redo`() throws {
        var generator = MessageIDGenerator()
        var generated = Set<UInt16>()
        let count = MessageIDGenerator.capacity
        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(MessageIDGenerator.randomNumberRange.contains(id))
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == count)

        var removedCount = 0
        for idx in MessageIDGenerator.randomNumberRange {
            generator.remove(idx)
            if generated.remove(idx) != nil {
                removedCount += 1
            }
        }
        #expect(removedCount == count)

        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(MessageIDGenerator.randomNumberRange.contains(id))
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == count)

        removedCount = 0
        for idx in MessageIDGenerator.randomNumberRange {
            generator.remove(idx)
            if generated.remove(idx) != nil {
                removedCount += 1
            }
        }
        #expect(removedCount == count)

        generated = []
        for idx in 0..<count {
            do {
                let id = try generator.next()
                #expect(MessageIDGenerator.randomNumberRange.contains(id))
                #expect(generated.insert(id).inserted)
            } catch {
                Issue.record("Failed to generate ID at idx \(idx)")
            }
        }
        #expect(generated.count == count)
    }
}
