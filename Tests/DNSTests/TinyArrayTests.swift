import DNSModels
import Testing

@Suite
struct TinyArrayTests {
    @Test func whenEmpty() {
        let array = TinyArray<1, Int>()

        for num in array {
            Issue.record("Expected the array to be empty. Num: \(num)")
        }
    }

    @Test func whenOnlyInlineElements() {
        var array = TinyArray<1, Int>()
        array.append(8)

        var iterationCount = 0
        for num in array {
            #expect(num == 8)
            iterationCount += 1
        }

        #expect(iterationCount == 1)
        #expect(array.count == 1)
        #expect(array.first == 8)
    }
}
