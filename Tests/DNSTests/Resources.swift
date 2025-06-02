import FoundationEssentials
import NIOCore

enum Resource: String {
    case dnsQueryAExampleComPacket = "dns-query-a-example.com-packet"
    case dnsResponseAExampleComPacket = "dns-response-a-example.com-packet"
    case dnsQueryTXTExampleComPacket = "dns-query-txt-example.com-packet"
    case dnsResponseTXTExampleComPacket = "dns-response-txt-example.com-packet"

    func buffer() -> ByteBuffer {
        ByteBuffer(bytes: Resource.data(at: self.rawValue))
    }

    private static let fm = FileManager.default

    private static func data(at relativePath: String) -> Data {
        let path = #filePath.dropLast("DNSTests/Resources.swift".count) + "Resources/\(relativePath)"
        return fm.contents(atPath: String(path))!
    }
}
