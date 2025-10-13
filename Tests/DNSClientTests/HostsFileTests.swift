import DNSClient
import DNSModels
import NIOFileSystem
import Testing

import struct NIOCore.ByteBuffer

@Suite
struct HostsFileTests {
    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: hostFilesWithCapacities)
    func `parsing host files works`(
        resource: Resources,
        expectedHostsFile: HostsFile,
        readChunkSize: ByteCount
    ) async throws {
        let path = resource.qualifiedPath()
        let filePath = FilePath(path)
        let hostsFile = try await HostsFile(
            readingFileAt: filePath,
            fileSystem: .shared,
            readChunkSize: readChunkSize
        )

        let hostsFileEntries = self.sort(entries: hostsFile._entries)
        let expectedEntries = self.sort(entries: expectedHostsFile._entries)

        #expect(hostsFileEntries.count == expectedEntries.count)

        for (parsed, expected) in zip(hostsFileEntries.map(\.0), expectedEntries.map(\.0)) {
            let parsedDomainName = DomainName(
                isFQDN: false,
                _uncheckedAssumingValidWireFormatBytes: parsed
            )
            let expectedDomainName = DomainName(
                isFQDN: false,
                _uncheckedAssumingValidWireFormatBytes: expected
            )
            #expect(parsed == expected)
            #expect(parsedDomainName == expectedDomainName)
        }

        for (parsed, expected) in zip(hostsFileEntries.map(\.1), expectedEntries.map(\.1)) {
            #expect(parsed == expected)
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    func sort(entries: [ByteBuffer: HostsFile.Target]) -> [(ByteBuffer, HostsFile.Target)] {
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

@available(swiftDNSApplePlatforms 15, *)
extension HostsFile {
    init(_ array: [(name: String, addresses: [String])]) {
        self.init(_entries: [:])
        for (name, addresses) in array {
            let name = try! DomainName(name)
            for address in addresses {
                var address = address
                let target = address.withUTF8 {
                    HostsFile.Target(from: $0.span)!
                }
                self._entries[name._data] = target
            }
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
private let hostFiles: [(Resources, HostsFile)] = [
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
]

private let readChunkSizes: [ByteCount] = [
    .bytes(10),
    .kibibytes(1),
    .kibibytes(2),
    .kibibytes(5),
    .kibibytes(64),
    .kibibytes(1024),
]

/// (resource, hostsFile, readChunkSize)
@available(swiftDNSApplePlatforms 15, *)
private let hostFilesWithCapacities: [(Resources, HostsFile, ByteCount)] = hostFiles.flatMap {
    (resource, hostsFile) in
    readChunkSizes.map { readChunkSize in
        (resource, hostsFile, readChunkSize)
    }
}
