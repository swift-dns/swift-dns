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

    case dnsQueryCERTForDnsCertTestingMahdibmComPacket =
        "for-dns-cert-testing.mahdibm.com-cert-query-packet"
    case dnsResponseCERTForDnsCertTestingMahdibmComPacket =
        "for-dns-cert-testing.mahdibm.com-cert-response-packet"

    case dnsQueryMXMahdibmComPacket = "mahdibm.com-mx-query-packet"
    case dnsResponseMXMahdibmComPacket = "mahdibm.com-mx-response-packet"

    case dnsQueryNSAppleComPacket = "apple.com-ns-query-packet"
    case dnsResponseNSAppleComPacket = "apple.com-ns-response-packet"

    case dnsQueryPTR9dot9dot9dot9Packet = "9dot9dot9dot9-ptr-query-packet"
    case dnsResponsePTR9dot9dot9dot9Packet = "9dot9dot9dot9-ptr-response-packet"

    case dnsQueryOPTCloudflareComPacket = "cloudflare.com-opt-query-packet"
    case dnsResponseOPTCloudflareComPacket = "cloudflare.com-opt-response-packet"

    case topDomains = "top-domains.csv"

    func buffer() -> DNSBuffer {
        DNSBuffer(bytes: self.data())
    }

    func data() -> Data {
        FileManager.default.contents(
            atPath: self.qualifiedPath()
        )!
    }

    private func qualifiedPath() -> String {
        var components = URL(fileURLWithPath: #filePath).pathComponents

        while components.last != "swift-dns" {
            components.removeLast()
        }

        components.append(contentsOf: ["Tests", "Resources", self.rawValue])

        return components.joined(separator: "/")
    }
}
