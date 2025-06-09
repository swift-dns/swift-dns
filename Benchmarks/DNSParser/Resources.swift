import DNSModels
import FoundationEssentials

enum Resources: String {
    case dnsQueryAExampleComPacket = "example.com-a-query-packet"
    case dnsResponseAExampleComPacket = "example.com-a-response-packet"
    case dnsQueryAAAACloudflareComPacket = "cloudflare.com-aaaa-query-packet"
    case dnsResponseAAAACloudflareComPacket = "cloudflare.com-aaaa-response-packet"
    case dnsQueryTXTExampleComPacket = "example.com-txt-query-packet"
    case dnsResponseTXTExampleComPacket = "example.com-txt-response-packet"

    func buffer() -> DNSBuffer {
        DNSBuffer(bytes: Resources.data(at: self.rawValue))
    }

    private static let fm = FileManager.default

    private static func data(at relativePath: String) -> Data {
        let dropCount = "Benchmarks/DNSParserBenchmarks".count
        let path = #filePath.dropLast(dropCount) + "Tests/Resources/\(relativePath)"
        return fm.contents(atPath: String(path))!
    }
}
