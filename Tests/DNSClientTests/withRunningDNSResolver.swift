import DNSClient
import Logging
import NIOPosix
import Testing

@available(swiftDNSApplePlatforms 10.15, *)
func withRunningDNSResolver(
    _ resolver: DNSResolver,
    function: (DNSResolver) async throws -> Void
) async throws {
    try await withThrowingDiscardingTaskGroup { taskGroup in
        if #available(swiftDNSApplePlatforms 26, *) {
            taskGroup.addImmediateTask {
                try await resolver.run()
            }
        } else {
            taskGroup.addTask {
                try await resolver.run()
            }
        }
        try await function(resolver)
        taskGroup.cancelAll()
    }
}
