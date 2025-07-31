import DNSClient
import Logging
import NIOPosix
import Testing

@available(swiftDNSApplePlatforms 26, *)
struct DNSClientTrait: TestTrait, SuiteTrait, TestScoping {
    @TaskLocal static var currentClient: DNSClient?

    let client: DNSClient

    @available(swiftDNSApplePlatforms 26, *)
    init(
        client: DNSClient = try! .preferUDPOrUseTCPTransport(
            serverAddress: .domain(name: "8.8.4.4", port: 53),
            udpConnectionConfiguration: .init(queryTimeout: .seconds(10)),
            tcpConfiguration: .init(
                connectionConfiguration: .init(queryTimeout: .seconds(20)),
                connectionPoolConfiguration: .init(),
                keepAliveBehavior: .init()
            ),
            logger: .init(label: "DNSClientTests")
        )
    ) {
        self.client = client
    }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        try await DNSClientTrait.$currentClient.withValue(self.client) {
            try await withThrowingDiscardingTaskGroup { taskGroup in
                taskGroup.addImmediateTask {
                    await client.run()
                }
                try await function()
                taskGroup.cancelAll()
            }
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension Trait where Self == DNSClientTrait {
    static var withDNSClient: Self {
        DNSClientTrait()
    }

    static func withDNSClient(
        client: DNSClient = try! .preferUDPOrUseTCPTransport(
            serverAddress: .domain(name: "8.8.4.4", port: 53),
            udpConnectionConfiguration: .init(queryTimeout: .seconds(10)),
            tcpConfiguration: .init(
                connectionConfiguration: .init(queryTimeout: .seconds(20)),
                connectionPoolConfiguration: .init(),
                keepAliveBehavior: .init()
            ),
            logger: .init(label: "DNSClientTests")
        )
    ) -> Self {
        DNSClientTrait(client: client)
    }
}
