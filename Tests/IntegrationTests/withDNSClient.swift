import DNSClient
import Logging
import NIOPosix
import Testing

@available(swiftDNSApplePlatforms 26.0, *)
struct DNSClientTrait: TestTrait, SuiteTrait, TestScoping {
    @TaskLocal static var currentClient: DNSClient?

    let serverAddress: DNSServerAddress
    let configuration: DNSClientConfiguration

    init() {
        self.serverAddress = .domain(name: "8.8.4.4", port: 53)
        self.configuration = .init(
            connectionConfiguration: .init(queryTimeout: .seconds(10)),
            tcpConnectionConfiguration: .init(queryTimeout: .seconds(20)),
            keepAliveBehavior: .init()
        )
    }

    @available(swiftDNSApplePlatforms 26.0, *)
    init(
        serverAddress: DNSServerAddress = .domain(name: "8.8.4.4", port: 53),
        configuration: DNSClientConfiguration = .init(
            connectionConfiguration: .init(queryTimeout: .seconds(10)),
            tcpConnectionConfiguration: .init(queryTimeout: .seconds(20)),
            keepAliveBehavior: .init()
        )
    ) {
        self.serverAddress = serverAddress
        self.configuration = configuration
    }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        let client = try DNSClient(
            serverAddress: self.serverAddress,
            configuration: self.configuration,
            eventLoopGroup: MultiThreadedEventLoopGroup.singleton,
            logger: Logger(label: "DNSTests")
        )
        try await DNSClientTrait.$currentClient.withValue(client) {
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

@available(swiftDNSApplePlatforms 26.0, *)
extension Trait where Self == DNSClientTrait {
    static var withDNSClient: Self {
        DNSClientTrait()
    }

    static func withDNSClient(
        serverAddress: DNSServerAddress = .domain(name: "8.8.4.4", port: 53),
        configuration: DNSClientConfiguration = .init(
            connectionConfiguration: .init(queryTimeout: .seconds(10)),
            tcpConnectionConfiguration: .init(queryTimeout: .seconds(20)),
            keepAliveBehavior: .init()
        )
    ) -> Self {
        DNSClientTrait(
            serverAddress: serverAddress,
            configuration: configuration
        )
    }
}

