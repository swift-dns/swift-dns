import DNSClient
import Logging
import NIOPosix
import Testing

struct DNSClientTrait: TestTrait, SuiteTrait, TestScoping {
    @TaskLocal static var currentClient: DNSClient?

    let serverAddress: DNSServerAddress

    init(serverAddress: DNSServerAddress = .domain(name: "8.8.4.4", port: 53)) {
        self.serverAddress = serverAddress
    }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        let client = try DNSClient(
            serverAddress: serverAddress,
            configuration: .init(
                connectionConfiguration: .init(queryTimeout: .seconds(3)),
                tcpConnectionConfiguration: .init(queryTimeout: .seconds(10)),
                keepAliveBehavior: .init()
            ),
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )
        try await DNSClientTrait.$currentClient.withValue(client) {
            try await withThrowingTaskGroup { taskGroup in
                taskGroup.addImmediateTask {
                    await client.run()
                }
                try await function()
                taskGroup.cancelAll()
                try await taskGroup.waitForAll()
            }
        }
    }
}

extension Trait where Self == DNSClientTrait {
    static var withDNSClient: Self {
        DNSClientTrait()
    }
}
