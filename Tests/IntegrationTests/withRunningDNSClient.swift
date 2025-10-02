import DNSClient
import Logging
import NIOPosix
import Testing

@available(swiftDNSApplePlatforms 15, *)
func withRunningDNSClient(
    _ client: DNSClient,
    function: (DNSClient) async throws -> Void
) async throws {
    async let _ = client.run()
    try await function(client)
}
