import DNSClient
import Logging
import NIOPosix
import ServiceLifecycle
import Testing

@available(SwiftStdlib 5.1, *)
func withRunningDNSClient<S: Service>(
    _ client: S,
    function: (S) async throws -> Void
) async throws {
    try await withThrowingDiscardingTaskGroup { taskGroup in
        if #available(SwiftStdlib 6.2, *) {
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
