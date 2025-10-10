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

    case hosts = "hosts"
    case hostsIPv4 = "hosts-ipv4"
    case hostsIPv6 = "hosts-ipv6"
    case hostsSingleLine = "hosts-single-line"
    case hostsCase = "hosts-case"

    case topDomains = "top-domains.csv"

    func buffer() -> DNSBuffer {
        DNSBuffer(bytes: self.data())
    }

    func data() -> Data {
        FileManager.default.contents(
            atPath: self.qualifiedPath()
        )!
    }

    func qualifiedPath() -> String {
        var components = URL(fileURLWithPath: #filePath).pathComponents

        while components.last != "swift-dns" {
            components.removeLast()
        }

        components.append(contentsOf: ["Tests", "Resources"])

        if let subDirectory = self.subDirectory {
            components.append(subDirectory)
        }

        components.append(self.rawValue)

        return components.joined(separator: "/")
    }

    var subDirectory: String? {
        switch self {
        case .dnsQueryAExampleComPacket, .dnsResponseAExampleComPacket,
            .dnsQueryAAAACloudflareComPacket, .dnsResponseAAAACloudflareComPacket,
            .dnsQueryTXTExampleComPacket, .dnsResponseTXTExampleComPacket,
            .dnsQueryCNAMERawGithubusercontentComPacket,
            .dnsResponseCNAMERawGithubusercontentComPacket, .dnsQueryCNAMEWwwGithubComPacket,
            .dnsResponseCNAMEWwwGithubComPacket, .dnsQueryCAACloudflareComPacket,
            .dnsResponseCAACloudflareComPacket, .dnsQueryCERTForDnsCertTestingMahdibmComPacket,
            .dnsResponseCERTForDnsCertTestingMahdibmComPacket, .dnsQueryMXMahdibmComPacket,
            .dnsResponseMXMahdibmComPacket, .dnsQueryNSAppleComPacket, .dnsResponseNSAppleComPacket,
            .dnsQueryPTR9dot9dot9dot9Packet, .dnsResponsePTR9dot9dot9dot9Packet,
            .dnsQueryOPTCloudflareComPacket, .dnsResponseOPTCloudflareComPacket:
            return "dns-packets"
        case .hosts, .hostsIPv4, .hostsIPv6, .hostsSingleLine, .hostsCase:
            return "hosts"
        case .topDomains:
            return nil
        }
    }

    var domainName: DomainName? {
        switch self {
        case .dnsQueryAExampleComPacket, .dnsResponseAExampleComPacket:
            return try? DomainName("mahdibm.com.")
        case .dnsQueryAAAACloudflareComPacket, .dnsResponseAAAACloudflareComPacket:
            return try? DomainName("cloudflare.com.")
        case .dnsQueryTXTExampleComPacket, .dnsResponseTXTExampleComPacket:
            return try? DomainName("example.com.")
        case .dnsQueryCNAMERawGithubusercontentComPacket,
            .dnsResponseCNAMERawGithubusercontentComPacket:
            return try? DomainName("raw.githubusercontent.com.")
        case .dnsQueryCNAMEWwwGithubComPacket, .dnsResponseCNAMEWwwGithubComPacket:
            return try? DomainName("www.github.com.")
        case .dnsQueryCAACloudflareComPacket, .dnsResponseCAACloudflareComPacket:
            return try? DomainName("cloudflare.com.")
        case .dnsQueryCERTForDnsCertTestingMahdibmComPacket,
            .dnsResponseCERTForDnsCertTestingMahdibmComPacket:
            return try? DomainName("for-dns-cert-testing.mahdibm.com.")
        case .dnsQueryMXMahdibmComPacket, .dnsResponseMXMahdibmComPacket:
            return try? DomainName("mahdibm.com.")
        case .dnsQueryNSAppleComPacket, .dnsResponseNSAppleComPacket:
            return try? DomainName("apple.com.")
        case .dnsQueryPTR9dot9dot9dot9Packet, .dnsResponsePTR9dot9dot9dot9Packet:
            return try? DomainName("9.9.9.9.")
        case .dnsQueryOPTCloudflareComPacket, .dnsResponseOPTCloudflareComPacket:
            return try? DomainName("cloudflare.com.")
        case .hosts, .hostsIPv4, .hostsIPv6, .hostsSingleLine, .hostsCase, .topDomains:
            return nil
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    static func forQuery<QueryableType: Queryable>(
        queryableType: QueryableType.Type = QueryableType.self
    ) -> (query: Self, response: Self) {
        switch queryableType {
        case is A.Type:
            return (.dnsQueryAExampleComPacket, .dnsResponseAExampleComPacket)
        case is AAAA.Type:
            return (.dnsQueryAAAACloudflareComPacket, .dnsResponseAAAACloudflareComPacket)
        case is TXT.Type:
            return (.dnsQueryTXTExampleComPacket, .dnsResponseTXTExampleComPacket)
        case is CNAME.Type:
            return (
                .dnsQueryCNAMERawGithubusercontentComPacket,
                .dnsResponseCNAMERawGithubusercontentComPacket
            )
        case is CAA.Type:
            return (.dnsQueryCAACloudflareComPacket, .dnsResponseCAACloudflareComPacket)
        case is CERT.Type:
            return (
                .dnsQueryCERTForDnsCertTestingMahdibmComPacket,
                .dnsResponseCERTForDnsCertTestingMahdibmComPacket
            )
        case is MX.Type:
            return (.dnsQueryMXMahdibmComPacket, .dnsResponseMXMahdibmComPacket)
        case is NS.Type:
            return (.dnsQueryNSAppleComPacket, .dnsResponseNSAppleComPacket)
        case is PTR.Type:
            return (.dnsQueryPTR9dot9dot9dot9Packet, .dnsResponsePTR9dot9dot9dot9Packet)
        case is OPT.Type:
            return (.dnsQueryOPTCloudflareComPacket, .dnsResponseOPTCloudflareComPacket)
        default:
            fatalError("Unsupported queryable type: \(queryableType)")
        }
    }
}
