import DNSClient
import Logging
import NIOPosix
import ServiceLifecycle
import Testing

@available(swiftDNSApplePlatforms 10.15, *)
func withRunningDNSClient<S: Service>(
    _ client: S,
    function: (S) async throws -> Void
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
