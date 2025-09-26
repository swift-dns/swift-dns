import DNSModels
import Testing

@Suite
struct UInt8Tests {
    @Test func `UInt8 asDecimal works correctly`() {
        for number in (UInt8(0)...UInt8(255)) {
            var string = String()
            number.asDecimal(
                writeUTF8Byte: {
                    string.append(Character(UnicodeScalar($0)))
                }
            )
            #expect(string == String(number))
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test func `UInt8 from-decimal-span initializer works for numbers 0...255`() {
        for number in (UInt8(0)...UInt8(255)) {
            let string = String(number)
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == number)
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test func `UInt8 from-decimal-span initializer fails for negative numbers -255...-0`() {
        for number in (UInt8(0)...UInt8(255)) {
            let string = "-" + String(number)
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == nil)
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test func `UInt8 from-decimal-span initializer fails for numbers 256...309`() {
        for number in 256..<310 {
            let string = String(number)
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == nil)
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test func `UInt8 from-decimal-span initializer fails for numbers 1000...1233`() {
        for number in 1000..<1234 {
            let string = String(number)
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == nil)
        }
    }

    @available(swiftDNSApplePlatforms 26, *)
    @Test func `UInt8 from-decimal-span initializer fails for invalid strings`() {
        for string in ["hello", "hi there", "新华网.中国", "中国"] {
            let span = string.utf8Span.span
            #expect(UInt8(decimalRepresentation: span) == nil)
        }
    }
}
