import DNSClient
import Logging
import NIOPosix
import Testing

@available(swiftDNSApplePlatforms 13, *)
func withRunningDNSClient(
    _ client: DNSClient,
    function: (DNSClient) async throws -> Void
) async throws {
    try await withThrowingDiscardingTaskGroup { taskGroup in
        if #available(swiftDNSApplePlatforms 26, *) {
            taskGroup.addImmediateTask {
                try await client.run()
            }
        } else {
            taskGroup.addTask {
                try await client.run()
            }
        }
        try await function(client)
        taskGroup.cancelAll()
    }
}
