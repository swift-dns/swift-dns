import DNSClient
import Logging
import NIOPosix
import Testing

@available(swiftDNSApplePlatforms 26, *)
struct DNSClientTrait: TestTrait, SuiteTrait, TestScoping {
    @TaskLocal static var currentClient: DNSClient?

    let transport: DNSClient.Transport

    @available(swiftDNSApplePlatforms 26, *)
    init(
        transport: DNSClient.Transport = .preferUDPOrUseTCP(
            try! PreferUDPOrUseTCPDNSClientTransport(
                serverAddress: .domain(name: "8.8.4.4", port: 53),
                configuration: .init(
                    udpConnectionConfiguration: .init(queryTimeout: .seconds(10)),
                    tcpConnectionConfiguration: .init(queryTimeout: .seconds(20)),
                    tcpKeepAliveBehavior: .init()
                )
            )
        )
    ) {
        self.transport = transport
    }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        let client = try DNSClient(transport: self.transport)
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

@available(swiftDNSApplePlatforms 26, *)
extension Trait where Self == DNSClientTrait {
    static var withDNSClient: Self {
        DNSClientTrait()
    }

    static func withDNSClient(
        transport: DNSClient.Transport = .preferUDPOrUseTCP(
            try! PreferUDPOrUseTCPDNSClientTransport(
                serverAddress: .domain(name: "8.8.4.4", port: 53),
                configuration: .init(
                    udpConnectionConfiguration: .init(queryTimeout: .seconds(10)),
                    tcpConnectionConfiguration: .init(queryTimeout: .seconds(20)),
                    tcpKeepAliveBehavior: .init()
                )
            )
        )
    ) -> Self {
        DNSClientTrait(transport: transport)
    }
}
