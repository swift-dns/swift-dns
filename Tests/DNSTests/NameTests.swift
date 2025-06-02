import DNSCore
import DNSModels
import Testing

// REMOVE
import struct Foundation.Data
import struct NIOCore.ByteBuffer

@Suite
struct NameTests {
    @Test(
        arguments: [
            (name: "*", isFQDN: false, data: [42], borders: [1]),
            (name: "a", isFQDN: false, data: [97], borders: [1]),
            (name: "*.b", isFQDN: false, data: [42, 98], borders: [1, 2]),
            (name: "a.b", isFQDN: false, data: [97, 98], borders: [1, 2]),
            (name: "*.b.c", isFQDN: false, data: [42, 98, 99], borders: [1, 2, 3]),
            (name: "a.b.c", isFQDN: false, data: [97, 98, 99], borders: [1, 2, 3]),
            (name: "a.b.c.", isFQDN: true, data: [97, 98, 99], borders: [1, 2, 3]),
            (name: #"test\."#, isFQDN: false, data: [116, 101, 115, 116, 46], borders: [5]),
        ]
    )
    func initFromString(name: String, isFQDN: Bool, data: [UInt8], borders: [UInt8]) async throws {
        let domainName = try Name(string: name)
        #expect(domainName.isFQDN == isFQDN)
        #expect(domainName.data == data)
        #expect(domainName.borders == borders)
    }

    @Test(
        arguments: [
            (name: ".", isFQDN: true),
            (name: "", isFQDN: false),
            (name: "www.example.com.", isFQDN: true),
            (name: "www.example", isFQDN: false),
            (name: "www", isFQDN: false),
            (name: "test.", isFQDN: true),
            (name: #"test\."#, isFQDN: false),
        ]
    )
    func `fqdnParsing`(name: String, isFQDN: Bool) async throws {
        try #expect(Name(string: name).isFQDN == isFQDN)
    }

    @Test(
        arguments: [
            (name: ".", expected: "."),
            (name: "", expected: ""),
            (name: "www.example.com.", expected: "www.example.com."),
            (name: "www.example", expected: "www.example"),
            (name: "www", expected: "www"),
            (name: "test.", expected: "test."),
            (name: #"test\."#, expected: "test."),
        ]
    )
    func `parsingThenAsStringWorksAsExpected`(name: String, expected: String) async throws {
        #expect(try Name(string: name).asString() == expected)
    }

    @Test(
        arguments: [
            (name: "*", expectedLabelsCount: 0),
            (name: "a", expectedLabelsCount: 1),
            (name: "*.b", expectedLabelsCount: 1),
            (name: "a.b", expectedLabelsCount: 2),
            (name: "*.b.c", expectedLabelsCount: 2),
            (name: "a.b.c", expectedLabelsCount: 3),
        ]
    )
    func `numberOfLabels`(name: String, expectedLabelsCount: Int) async throws {
        try #expect(Name(string: name).labelsCount == expectedLabelsCount)
    }

    @Test func decodeFromBuffer() async throws {
        var buffer = ByteBuffer([
            0x07, 0x65, 0x78, 0x61,
            0x6d, 0x70, 0x6c, 0x65,
            0x03, 0x63, 0x6f, 0x6d,
            0x00,
        ])
        let name = try Name(from: &buffer)
        #expect(name.asString() == "example.com")
    }
}
