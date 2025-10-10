import DNSClient
import DNSModels
import NIOFileSystem
import Testing

@Suite
struct HostsFileTests {
    @available(swiftDNSApplePlatforms 26, *)
    @Test(
        arguments: [(Resources, HostsFile)]([
            (
                Resources.hosts,
                HostsFile([
                    ("odin", ["127.0.0.2", "127.0.0.3", "::2"]),
                    ("thor", ["127.1.1.1", "127.1.2.1", "127.1.3.1"]),
                    ("ullr", ["127.1.1.2"]),
                    ("ullrhost", ["127.1.1.2"]),
                    ("localhost", ["fe80::1%lo0"]),
                ]),
            ),
            (
                Resources.hostsSingleLine,
                HostsFile([
                    ("odin", ["127.0.0.2"])
                ]),
            ),
            (
                Resources.hostsIPv4,
                HostsFile([
                    ("localhost", ["127.0.0.1", "127.0.0.2", "127.0.0.3"]),
                    ("localhost.localdomain", ["127.0.0.3"]),
                ]),
            ),
            (
                Resources.hostsIPv6,
                HostsFile([
                    ("localhost", ["::1", "fe80::1", "fe80::2%lo0", "fe80::3%lo0"]),
                    ("localhost.localdomain", ["fe80::3%lo0"]),
                ]),
            ),
            (
                Resources.hostsCase,
                HostsFile([
                    ("PreserveMe", ["127.0.0.1", "::1"]),
                    ("PreserveMe.local", ["127.0.0.1", "::1"]),
                ]),
            ),
        ])
    )
    func `parsing host-files works`(
        resource: Resources,
        expectedHostsFile: HostsFile
    ) async throws {
        let path = resource.qualifiedPath()
        let filePath = FilePath(path)
        let hostsFile = try await HostsFile(
            readingFileAt: filePath,
            fileSystem: .shared,
            maximumSizeAllowed: .kibibytes(100)
        )
        let hostsFileEntries = self.sort(entries: hostsFile._entries)
        let expectedHostsFileEntries = self.sort(entries: expectedHostsFile._entries)
        #expect(hostsFileEntries.map(\.0) == expectedHostsFileEntries.map(\.0))
        #expect(hostsFileEntries.map(\.1) == expectedHostsFileEntries.map(\.1))
    }

    @available(swiftDNSApplePlatforms 15, *)
    func sort(entries: [DomainName: HostsFile.Target]) -> [(DomainName, HostsFile.Target)] {
        entries.sorted(by: { lhs, rhs in
            if lhs.key == rhs.key {
                if lhs.value.address == rhs.value.address {
                    return (lhs.value.zoneID ?? "") < (rhs.value.zoneID ?? "")
                }
                return lhs.value.address.description < rhs.value.address.description
            }
            return lhs.key.description < rhs.key.description
        })
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension HostsFile {
    init(_ array: [(name: String, addresses: [String])]) {
        self.init(_entries: [:])
        for (name, addresses) in array {
            let name = try! DomainName(name)
            for address in addresses {
                let target = HostsFile.Target(
                    from: address.utf8Span.span
                )!
                self._entries[name] = target
            }
        }
    }
}
