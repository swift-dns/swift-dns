import DNSClient
import Logging
import NIOPosix
import Testing

@available(swiftDNSApplePlatforms 26, *)
func withRunningDNSClient(
    _ client: DNSClient,
    function: @Sendable (DNSClient) async throws -> Void
) async throws {
    try await withThrowingDiscardingTaskGroup { taskGroup in
        taskGroup.addImmediateTask {
            await client.run()
        }
        try await function(client)
        taskGroup.cancelAll()
    }
}
