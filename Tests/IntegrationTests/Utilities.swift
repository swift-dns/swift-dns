import DNSClient
import Logging

enum Utils {
    @available(swiftDNSApplePlatforms 10.15, *)
    static func makeTestingDNSClients() -> [DNSClient] {
        [
            try! DNSClient(
                transport: .preferUDPOrUseTCP(
                    serverAddress: .domain(
                        domainName: DomainName(ipv4: .defaultTestDNSServer),
                        port: 53
                    ),
                    udpConnectionConfiguration: .init(queryTimeout: .seconds(10)),
                    tcpConfiguration: .init(
                        connectionConfiguration: .init(queryTimeout: .seconds(20)),
                        connectionPoolConfiguration: .init(),
                        keepAliveBehavior: .init()
                    ),
                    logger: .init(label: "DNSClientTests")
                )
            ),
            try! DNSClient(
                transport: .tcp(
                    serverAddress: .domain(
                        domainName: DomainName(ipv4: .defaultTestDNSServer),
                        port: 53
                    ),
                    configuration: .init(
                        connectionConfiguration: .init(queryTimeout: .seconds(20)),
                        connectionPoolConfiguration: .init(),
                        keepAliveBehavior: .init()
                    ),
                    logger: .init(label: "DNSClientTests")
                )
            ),
        ]
    }
}
