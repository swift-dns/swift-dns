import DNSModels

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
/// We're in tests so should be fine
import Foundation
#endif

enum Resources: String {
    case dnsQueryAExampleComPacket = "example.com-a-query-packet"
    case dnsResponseAExampleComPacket = "example.com-a-response-packet"

    case dnsQueryAAAACloudflareComPacket = "cloudflare.com-aaaa-query-packet"
    case dnsResponseAAAACloudflareComPacket = "cloudflare.com-aaaa-response-packet"

    case dnsQueryTXTExampleComPacket = "example.com-txt-query-packet"
    case dnsResponseTXTExampleComPacket = "example.com-txt-response-packet"

    case dnsQueryCNAMERawGithubusercontentComPacket = "raw.githubusercontent.com-cname-query-packet"
    case dnsResponseCNAMERawGithubusercontentComPacket =
        "raw.githubusercontent.com-cname-response-packet"

    case dnsQueryCNAMEWwwGithubComPacket = "www.github.com-cname-query-packet"
    case dnsResponseCNAMEWwwGithubComPacket = "www.github.com-cname-response-packet"

    case dnsQueryCAACloudflareComPacket = "cloudflare.com-caa-query-packet"
    case dnsResponseCAACloudflareComPacket = "cloudflare.com-caa-response-packet"

    func buffer() -> DNSBuffer {
        DNSBuffer(bytes: Resources.data(at: self.rawValue))
    }

    private static func data(at relativePath: String) -> Data {
        let dropCount = "DNSTests/Resources.swift".count
        let path = #filePath.dropLast(dropCount) + "Resources/\(relativePath)"
        return FileManager.default.contents(atPath: String(path))!
    }
}
