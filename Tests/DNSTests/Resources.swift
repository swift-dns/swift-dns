import FoundationEssentials
import DNSModels

enum Resource: String {
    case dnsQueryAExampleComPacket = "dns-query-a-example.com-packet"
    case dnsResponseAExampleComPacket = "dns-response-a-example.com-packet"
    case dnsQueryAAAACloudflareComPacket = "dns-query-aaaa-cloudflare.com-packet"
    case dnsResponseAAAACloudflareComPacket = "dns-response-aaaa-cloudflare.com-packet"
    case dnsQueryTXTExampleComPacket = "dns-query-txt-example.com-packet"
    case dnsResponseTXTExampleComPacket = "dns-response-txt-example.com-packet"

    func buffer() -> DNSBuffer {
        DNSBuffer(bytes: Resource.data(at: self.rawValue))
    }

    private static let fm = FileManager.default

    private static func data(at relativePath: String) -> Data {
        let dropCount = "DNSTests/Resources.swift".count
        let path = #filePath.dropLast(dropCount) + "Resources/\(relativePath)"
        return fm.contents(atPath: String(path))!
    }
}
